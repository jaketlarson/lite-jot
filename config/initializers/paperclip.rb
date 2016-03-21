Paperclip::Attachment.default_options.merge!(
  :url =>                ':s3_domain_url',
  :path =>               ':class/processed/:id/:hash_:basename_:style.:extension', # use hash for filename, defined below
  :hash_secret =>         Rails.application.secrets.filename_hash, # randomize file name
  :storage =>             :s3,
  :s3_credentials =>      { :access_key_id => Rails.application.secrets.aws_access_key_id, :secret_access_key => Rails.application.secrets.aws_secret_access_key },
  :s3_permissions =>       :private,
  :s3_protocol =>          'https',
  :bucket =>               'litejot'
)
