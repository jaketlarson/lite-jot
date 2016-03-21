// This file includes JS assets for the regular site of Lite Jot. For the application part, use application.js
// jQuery2 is included via CDN, called before this file is in layout.
//= require jquery_ujs
//= require jquery.ui.widget
//= require jquery.fileupload
// DON'T require turbolinks
//= require vendor/modernizr
//= require foundation
//= require blog_subscribe
//= require cooltip

//= require s3_direct_upload
$(document).foundation();
$(function() {
  $('#s3_uploader').S3Uploader(
    { 
      remove_completed_progress_bar: false,
      progress_bar_target: $('#uploads_container')
    }
  );
  $('#s3_uploader').bind('s3_upload_failed', function(e, content) {
    return alert(content.filename + ' failed to upload');
  });
});
