class Upload < ActiveRecord::Base

  # Environment-specific direct upload url verifier screens for malicious posted upload locations.
  DIRECT_UPLOAD_URL_FORMAT = %r{\Ahttps:\/\/litejot\.s3\.amazonaws\.com\/(?<path>uploads\/.+\/(?<filename>.+))\z}.freeze
  
  belongs_to :user
  has_attached_file :upload,
                    :s3_permissions => :public_read,
                    :styles => {
                      # original_no_exif is just a clone of the original image, but will have the
                      # convert options applied, namely the auto-orient, dealing with EXIF-related
                      # issues.
                      :original_no_exif => {
                        :geometry => "",
                        :quality => 100,
                        :format => 'jpg'
                      },
                      :thumbnail => {
                        :geometry => "800x120",
                        :quality => 100,
                        :format => 'jpg'
                      }
                    },
                    :convert_options => { :all => "-quality 100 -auto-orient" }

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
    # First save it, so we can grab the new paperclip url in OCR process
    upload.save

    # Now call the other process method, more related to the jot and OCR routiens
    upload.postprocess_jot_update

    # Mark this upload as processed, so the UI knows how to deal with it.
    upload.processed = true
    upload.save

    # Update user meta
    user = User.find(upload.user_id)
    user.meta.record_new_upload_size(upload.upload_file_size)
    
    ap direct_upload_url_data[:path]
    s3.buckets[Rails.application.secrets.s3_bucket].objects[direct_upload_url_data[:path]].delete
  end

  def original_url
    self.upload.url(:original_no_exif)
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

      # Get text from upload using Tesseract OCR
      ocr_response = self.get_text
      #ocr_text = ""
      ap "heres da text:"
      ap ocr_response
      content = JSON.parse(jot.content)
      content['identified_text'] = ocr_response[:text]
      content['annotations_info'] = ocr_response[:annotations_info]
      ap "saving identified_text to jot"
      jot.content = content.to_json
      jot.save

      # Do jot.touch just in case jot.save (above) did not have any new information to save,
      # so that live sync still detects the changes and removes the processing image state.
      jot.touch

      # Tell the topic and folder that they've been updated, so live sync catches the updated jot      
      topic = Topic.find(jot.topic_id)
      folder = Folder.find(jot.folder_id)
      folder.touch
      topic.touch
    end
  end

  def get_text
    # Grab the latest version of this upload, instead of using self.
    # However, not necessary when using delayed_jobs and direct_upload_url column.
    upload = Upload.find(self.id)
    #url = URI.parse(upload.upload.url(:original))
    url = URI.parse(upload.upload.url(:original_no_exif))
    ap "from url:"
    ap url

    image = HTTParty.get(url).body
    
    prefix = "ocr-sample"
    suffix = '.jpg'

    # Create directory if necessary
    if !File.directory?(Rails.root.join('tmp', 'ocr'))
      %x(mkdir tmp/ocr)
    end

    puts "Saving image"
    tempfile = Tempfile.new([prefix, suffix], Rails.root.join('tmp', 'ocr'))
    tempfile.binmode
    tempfile.write image
    tempfile.close
    save_path = tempfile.path
    ap "save_path="
    ap save_path
    
    response = GoogleCloudVision::Classifier.new(Rails.application.secrets.google_server_key,
    [
      { image: save_path, detection: 'TEXT_DETECTION', max_results: 10 }
    ]).response

    ap response

    # ap response
    ap '1'
    annotations_exist = false
    if response && response['responses'] && !response['responses'].empty? && response['responses'][0]['textAnnotations'] && !response['responses'][0]['textAnnotations'].empty?
      text = response['responses'][0]['textAnnotations'][0]['description']
      annotations_exist = true
      annotations_info = response['responses'][0]['textAnnotations']
    else
      text = ""
    end
    ap '2'

    ap text

    tempfile.unlink

    if annotations_exist
      ap "annotations list: "
      ap annotations_info.shift
      ap annotations_info.length
      data = { :text => text, :annotations_info => annotations_info }
    else
      data = { :text => text, :annotations_info => [] }
    end

    return data
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
