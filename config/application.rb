require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'devise'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LiteJot
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    
    config.autoload_paths  = %W(#{config.root}/lib)
    config.active_record.default_timezone = :local
    config.active_record.raise_in_transactional_callbacks = true

    # Errors
    config.exceptions_app = self.routes

    config.serve_static_files = true

    # Email
    ActionMailer::Base.smtp_settings = {
      :address => Rails.application.secrets.smtp['address'],
      :port => Rails.application.secrets.smtp['port'],
      :user_name => Rails.application.secrets.smtp['user_name'],
      :password => Rails.application.secrets.smtp['password'],
      :domain => Rails.application.secrets.smtp['domain'],
      :authentication => Rails.application.secrets.smtp['authentication'],
      :enable_starttls_auto => Rails.application.secrets.smtp['enable_starttls_auto']
    }

    # Active Job
    config.active_job.queue_adapter = :delayed_job
    
  end
end
