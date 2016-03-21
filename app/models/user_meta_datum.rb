class UserMetaDatum < ActiveRecord::Base
  belongs_to :user

  after_create :set_upload_limit_reset_date

  # Limit should reset every 30 days, starting on day of
  # account creation
  def set_upload_limit_reset_date
    now = DateTime.now
    reset_date = now + 30
    self.upload_limit_resets_at = reset_date
    self.save
  end

  # Called when user uploads new files so we can keep
  # track of limits
  def record_new_upload_size(bytes)
    self.upload_size_this_month = self.upload_size_this_month + bytes
    self.save
  end

  # Called to check if user exceeds monthly upload limit
  def exceeds_upload_limit?
    self.upload_size_this_month >= Rails.application.secrets.monthly_upload_byte_limit
  end
end
