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

  # Called to check if user exceeds monthly upload limit, with option
  # to pass in an extra byte count
  def exceeds_upload_limit?(attempted_bytes=0)
    self.upload_size_this_month + attempted_bytes >= Rails.application.secrets.monthly_upload_byte_limit
  end

  # May be better in a helper
  def upload_usage_percent
    ((self.upload_size_this_month.to_f / Rails.application.secrets.monthly_upload_byte_limit.to_f)*100).to_i.to_s + "%"
  end

  # May be better in a helper
  def upload_usage_fraction
    # Show in megabytes
    used = (self.upload_size_this_month / 1024 / 1024).to_s
    limit = (Rails.application.secrets.monthly_upload_byte_limit / 1024 / 1024).to_s
    "#{used} MB / #{limit} <span title='megabytes'>MB</span>".html_safe
  end

  # May be better in a helper
  def usage_reset_day
    self.upload_limit_resets_at.strftime("%A, %B %e, %Y")
  end

  def upload_limit_remaining
    Rails.application.secrets.monthly_upload_byte_limit - self.upload_size_this_month
  end
end
