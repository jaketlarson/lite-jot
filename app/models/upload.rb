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


# Paperclip::Attachment.default_options.merge!(
#   url:                  ':s3_domain_url',
#   path:                 ':class/processed/:id/:style/:hash.:extension',
#   storage:              :s3,
#   s3_credentials:       { :access_key_id => Rails.application.secrets.aws_access_key_id, :secret_access_key => Rails.application.secrets.aws_secret_access_key },
#   s3_permissions:       :private,
#   s3_protocol:          'https',
#   bucket:               'litejot',
#   hash_secret: (0...64).map { (65 + rand(26)).chr }.join
# )

  validates :direct_upload_url, presence: true, format: { with: DIRECT_UPLOAD_URL_FORMAT }
  validate :check_upload_limit, :on => :create
    
  before_create :set_upload_attributes
  after_create :queue_processing
  
  attr_accessible :direct_upload_url, :upload_file_size

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

    upload.processed = true
    upload.save
    ap upload
    upload.postprocess_jot_update
    ap upload

    # Update user meta
    user = User.find(upload.user_id)
    user.meta.record_new_upload_size(upload.upload_file_size)
    
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
  def postprocess_jot_update
    jot = Jot.where('jot_type = ? AND content = ?', 'upload', self.id.to_s)
    ap "okay here is the jot we just processed:"
    ap jot
    if !jot.empty?
      jot = jot.first
      topic = Topic.find(jot.topic_id)
      folder = Folder.find(jot.folder_id)
      folder.touch
      topic.touch
      jot.touch
    end
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
