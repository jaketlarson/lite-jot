# CarrierWave.configure do |config|
#   config.fog_provider = 'fog/aws'                        # required
#   config.fog_credentials = {
#     provider:              'AWS',                        # required
#     aws_access_key_id:     Rails.application.secrets.aws_access_key_id,                        # required
#     aws_secret_access_key: Rails.application.secrets.aws_secret_access_key,                        # required
#     region:                'us-east-1',                  # optional, defaults to 'us-east-1'
#   }
#   config.fog_directory  = Rails.application.secrets.s3_bucket                         # required
#   config.fog_public     = false                                        # optional, defaults to true
#   config.fog_attributes = { 'Cache-Control' => "max-age=#{365.day.to_i}" } # optional, defaults to {}
# end


# # CarrierWave.configure do |config|
# #   config.storage    = :aws
# #   config.aws_bucket = Rails.application.secrets.s3_bucket
# #   config.aws_acl    = 'public-read'

# #   # Optionally define an asset host for configurations that are fronted by a
# #   # content host, such as CloudFront.
# #   config.asset_host = 'http://example.com'

# #   # The maximum period for authenticated_urls is only 7 days.
# #   config.aws_authenticated_url_expiration = 60 * 60 * 24 * 7

# #   # Set custom options such as cache control to leverage browser caching
# #   config.aws_attributes = {
# #     expires: 1.week.from_now.httpdate,
# #     cache_control: 'max-age=604800'
# #   }

# #   config.aws_credentials = {
# #     access_key_id:     Rails.application.secrets.aws_access_key_id,
# #     secret_access_key: Rails.application.secrets.aws_secret_access_key,
# #     region:            'us-east-1' # Required
# #   }

# #   # Optional: Signing of download urls, e.g. for serving private
# #   # content through CloudFront.
# #   config.aws_signer = -> (unsigned_url, options) { Aws::CF::Signer.sign_url unsigned_url, options }
# # end