class Upload < ActiveRecord::Base

  # Environment-specific direct upload url verifier screens for malicious posted upload locations.
  DIRECT_UPLOAD_URL_FORMAT = %r{\Ahttps:\/\/litejot\.s3\.amazonaws\.com\/(?<path>uploads\/.+\/(?<filename>.+))\z}.freeze
  
  belongs_to :user
  has_attached_file :upload,
                    :s3_permissions => :public_read,
                    :styles => {
                      :thumbnail => {
                        :geometry => "150x120",
                        :quality => 100,
                        :format => 'jpg'
                      }
                    },
                    :convert_options => { :all => "-quality 100" }

  validates :direct_upload_url, presence: true, format: { with: DIRECT_UPLOAD_URL_FORMAT }
  validate :check_upload_limit, :on => :create
    
  before_create :set_upload_attributes
  after_create :queue_processing
  
  attr_accessible :direct_upload_url, :upload_file_size
  after_post_process :save_image_dimensions

  # Paperclip version 4.0 requires:
  validates_attachment_content_type :upload, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"]
  
  # Store an unescaped version of the escaped URL that Amazon returns from direct upload.
  def direct_upload_url=(escaped_url)
    write_attribute(:direct_upload_url, (CGI.unescape(escaped_url) rescue nil))
  end
  
  # Determines if file requires post-processing (image resizing, etc)
  def post_process_required?
    %r{^(image|(x-)?application)/(bmp|gif|jpeg|jpg|pjpeg|png|x-png)$}.match(upload_content_type).present?
  end
  
  # Final upload processing step
  def self.transfer_and_cleanup(id)
    upload = Upload.find(id)
    direct_upload_url_data = DIRECT_UPLOAD_URL_FORMAT.match(upload.direct_upload_url)
    s3 = AWS::S3.new
    
    if upload.post_process_required?
      upload.upload = URI.parse(URI.escape(upload.direct_upload_url))
    else
      paperclip_file_path = "processed/#{id}/original/#{direct_upload_url_data[:filename]}"
      s3.buckets[Rails.application.secrets.s3_bucket].objects[paperclip_file_path].copy_from(direct_upload_url_data[:path])
    end

    # Now do more processing stuff, which includes OCR
    upload.postprocess_jot_update
    upload.processed = true
    upload.save

    # Update user meta
    user = User.find(upload.user_id)
    user.meta.record_new_upload_size(upload.upload_file_size)
    
    ap direct_upload_url_data[:path]
    s3.buckets[Rails.application.secrets.s3_bucket].objects[direct_upload_url_data[:path]].delete
  end

  def original_url
    self.upload.url
  end

  def thumbnail_url
    self.upload.url(:thumbnail)
  end

  # Since we use delayed jobs to handle processing, we need to go back to the jot that is currently
  # showing a placeholder and show them the newly processed image..
  # Has to be a public method (for delayed jobs)
  # We also run an OCR to read text from the image
  def postprocess_jot_update
    # Grab the latest version of this upload, instead of using self.
    upload = Upload.find(self.id)

    jot = Jot.where('id = ?', upload.jot_id)
    ap "okay here is the jot [id=#{upload.jot_id}] we just processed:"
    ap jot
    ap self
    ap upload
    if !jot.empty?
      jot = jot.first
      topic = Topic.find(jot.topic_id)
      folder = Folder.find(jot.folder_id)
      folder.touch
      topic.touch

      # Get text from upload using Tesseract OCR
      ocr_text = self.get_text
      ap "heres da text:"
      ap ocr_text
      content = JSON.parse(jot.content)
      content['identified_text'] = ocr_text
      jot.content = content.to_json
      jot.save
    end
  end

  def get_text
    ap "getting text for.. #{self.upload.url}"
    # Grab the latest version of this upload, instead of using self.
    upload = Upload.find(self.id)
    url = upload.upload.url(:original)
    image = HTTParty.get(url).body
    
    # puts "Creating directory"
    # #%x(mkdir tessdir)

    #prefix = "ocr-sample-#{self.user_id}"
    prefix = "tesseract-sample"
    suffix = '.jpg'
    # tmp_file = Tempfile.new [prefix, suffix], "#{Rails.root}/tmp" # For some reason won't allow another folder called tesseract..
    # ap tmp_file
    puts "Saving image"
    filename = "#{prefix}#{suffix}"
    save_as = "tmp/#{filename}"
    ap "saving as:"
    ap save_as
    ap File.size("#{save_as}")
    file = File.open(save_as,'wb') # make a rails secret call
    file.write image

    
    tempfile = Tempfile.new(['sample', '.jpg'], Rails.root.join('tmp','tesseract'))
    tempfile.binmode
    tempfile.write image
    tempfile.close
    save_path = tempfile.path
    ap "save_path="
    ap save_path
    # puts "Starting tesseract"
    # %x(tesseract tmp/tesseract-sample.jpg tmp/tesseract-out)
    
    # puts "Reading result"
    # file = File.open("tmp/tesseract-out.txt", "rb")
    # contents = file.read
    # ap "tesseract:"
    # ap contents

    # ap "google:"
    
    response = GoogleCloudVision::Classifier.new(Rails.application.secrets.google_server_key,
    [
      { image: save_path, detection: 'TEXT_DETECTION', max_results: 10 }
    ]).response

    # ap response
    ap response
    text = response['responses'][0]['textAnnotations'][0]['description']
    if !response['responses'].empty? && !responses[0]['textAnnotations'].empty?
      text = response['responses'][0]['textAnnotations'][0]['description']
    else
      text = ""
    end

    ap text

    tempfile.unlink

    return text
  end

  protected
  
  # Set attachment attributes from the direct upload
  # @note Retry logic handles S3 "eventual consistency" lag.
  def set_upload_attributes
    tries ||= 5
    direct_upload_url_data = DIRECT_UPLOAD_URL_FORMAT.match(direct_upload_url)
    s3 = AWS::S3.new
    direct_upload_head = s3.buckets[Rails.application.secrets.s3_bucket].objects[direct_upload_url_data[:path]].head

    self.upload_file_name     = direct_upload_url_data[:filename]
    self.upload_file_size     = direct_upload_head.content_length
    self.upload_content_type  = direct_upload_head.content_type
    self.upload_updated_at    = direct_upload_head.last_modified
  rescue AWS::S3::Errors::NoSuchKey => e
    tries -= 1
    if tries > 0
      sleep(3)
      retry
    else
      false
    end
  end

  def save_image_dimensions
    geometry = Paperclip::Geometry.from_file(self.upload.queued_for_write[:original])
    self.width = geometry.width.to_i
    self.height = geometry.height.to_i
  end
  
  # Queue file processing
  def queue_processing
    Upload.delay.transfer_and_cleanup(id)
  end

  def check_upload_limit
    user = User.find(self.user_id)

    ap self.upload_file_size
    errors.add(:upload, 'monthly_limit_exceeded') if user.meta.exceeds_upload_limit?(self.upload_file_size)
  end
end
