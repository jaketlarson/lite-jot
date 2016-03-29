# This file contains methods that handle the uploading of jots
class window.JotUploader extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @initUploader()
    @initBinds()

  initVars: =>
    @uploader = $('#uploader')

  initUploader: =>
    @uploader.S3Uploader(
      remove_completed_progress_bar: false,
      allow_multiple_files: false,
      progress_bar_target: $('#uploads-progress')
    )

  initBinds: =>
    @uploader.bind 's3_upload_failed', (e, content) =>
      $('#uploads-progress').hide().find('.upload').remove()
      new HoverNotice(@, 'Upload(s) unsuccessful: File size may exceed monthly allowance. Please contact us if this issue persists.', 'error')

      @reassignImageUploadInputVar()

    @uploader.bind 's3_uploads_start', (e, content) =>
      console.log e
      console.log content
      $('#uploads-progress').show()
      @lj.jots.scrollJotsToBottom()

    @uploader.bind 'ajax:success', (e, data) =>
      # This method is called on the last upload in the list of uploads.
      # So, if there are multiple uploads this will only return data on the last
      # response. The other images tend to trickle in via live reload, and for now
      # that seems to be fine.
      $('#uploads-progress').hide().find('.upload').remove()
      jot = data.jot
      @lj.app.jots.push jot
      @lj.jots.smartInsertJotElem jot
      new HoverNotice(@, 'Upload(s) successful! Images may take a moment to process.', 'success')

      @reassignImageUploadInputVar()

    @uploader.bind 'ajax:error', (e, data) =>
      $('#uploads-progress').hide().find('.upload').remove()

      response = data.responseJSON
      if response && response.errors && response.errors.upload && response.errors.upload.indexOf "monthly_limit_exceeded" > -1
        new HoverNotice(@, 'Upload(s) unsuccessful: Monthly limit exceeded.', 'error')
      else
        new HoverNotice(@, 'Internal Server Error: Please contact us if this issue persists.', 'error')

      @reassignImageUploadInputVar()

  # When the user changes topics this function will be called so we can make sure
  # their next upload references the current topic id.
  updateUploader: =>
    # If there is a way to update 'additional_data' without having to pass in
    # the same parameters each time, that'd be great.
    @uploader.S3Uploader(
      additional_data: { 'topic_id': @lj.app.current_topic },
      remove_completed_progress_bar: false,
      allow_multiple_files: false,
      progress_bar_target: $('#uploads-progress'),
      max_file_size: 1024*1024*10
    )

  reassignImageUploadInputVar: =>
    # Needs to be set every time files are uploaded.
    # Not sure why.
    # Also set in jots.js on init.
    @lj.jots.image_upload_input = @uploader.find("input[type='file']")
