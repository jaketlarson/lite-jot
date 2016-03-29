// This file includes JS assets for the application part of Lite Jot. For the regular website, use site.js
// jQuery2 is included via CDN, called before this file is in layout.
//= require jstz
//= require jquery_ujs
//= require s3_direct_upload
// DON'T require turbolinks
//= require vendor/modernizr
//= require foundation
//= require fullscreen
//= require folders
//= require topics
//= require jots
//= require search
//= require key_controls
//= require user_settings
//= require notification
//= require clock
//= require calendar
//= require folder_share_settings
//= require hover_notice
//= require airplane_mode
//= require connection
//= require push_ui
//= require jot_recovery
//= require email_tagger
//= require email_viewer
//= require jot_uploader
//= require aside
//= require Autolinker
//= require cooltip
//= require cursor_position
//= require helpers
//= require litejot
  
if($('body#pages-dashboard').length > 0) {
  window.lj = {
    litejot: new window.LiteJot()
  };
}
