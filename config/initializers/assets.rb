# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile += %w( litejot.css )
Rails.application.config.assets.precompile += %w( vendor/modernizr.js )
Rails.application.config.assets.precompile += %w( components/email_viewer.css )
Rails.application.config.assets.precompile += %w( stellar.min.js )
Rails.application.config.assets.precompile += %w( site.js )
