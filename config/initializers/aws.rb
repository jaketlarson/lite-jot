Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new(Rails.application.secrets.aws_access_key_id, Rails.application.secrets.aws_secret_access_key),
})

S3_BUCKET = Aws::S3::Resource.new.bucket(Rails.application.secrets.s3_bucket)

AWS.config(access_key_id: Rails.application.secrets.aws_access_key_id,
            secret_access_key: Rails.application.secrets.aws_secret_access_key,
            region: 'us-east-1')
