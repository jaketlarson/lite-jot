#= require litejot

class window.AirplaneMode extends LiteJot
  constructor: (@lj) ->
    @initVars()

  initVars: =>
    @active = false
    @terms_accepted_by_user = false
    @header_notice = $('#airplane-mode-header-notice')
    @header_notice_has_storage = @header_notice.find('#has-storage')
    @header_notice_no_storage = @header_notice.find('#no-storage')
    @terms_modal = $('#airplane-mode-terms-modal')
    @terms_modal_template = $('#airplane-mode-terms-modal-template')
    @unsaved_jots_modal = $('#airplane-mode-unsaved-jots-modal')
    @unsaved_jots_modal_template = $('#airplane-mode-unsaved-jots-modal-template')
    @max_save_attempts = 3

  activate: =>
    @active = true
    @showHeaderNotice()

    # Close certain modals, if opened.
    $('#folder-share-settings-modal').foundation 'reveal', 'close'
    $('#user-settings-modal').foundation 'reveal', 'close'

    if !@terms_accepted_by_user && @hasLocalStorage()
      @showTerms()

    return

  showHeaderNotice: =>
    @header_notice.show()
    if @hasLocalStorage()
      @header_notice_has_storage.show()
      @header_notice_no_storage.hide()
    else
      @header_notice_has_storage.hide()
      @header_notice_no_storage.show()
    @lj.sizeUI()
    return

  hideHeaderNotice: =>
    @header_notice.hide()
    @lj.sizeUI()
    return

  showTerms: =>
    if @hasLocalStorage()
      @terms_modal.foundation 'reveal', 'open'
      @terms_modal.html @terms_modal_template.html()

      @terms_modal.find('.accept').click =>
        @acceptTerms()

      @terms_modal.find('.refuse').click =>
        @refuseTerms()

    else
      @feature_unavailable_notice()

    return

  hideTerms: =>
    @terms_modal.foundation 'reveal', 'close'
    return

  acceptTerms: =>
    @terms_accepted_by_user = true
    @hideTerms()
    return

  refuseTerms: =>
    @terms_accepted_by_user = false
    @hideTerms()
    return

  deactivate: =>
    @active = false
    @hideHeaderNotice()
    @hideTerms()
    new HoverNotice(@lj, 'Connection to Lite Jot server restored.', 'success')
    
    @saveStoredJots @max_save_attempts
    return

  # not sure why this is not camelcase.. should go through and fix this
  feature_unavailable_notice: =>
    new HoverNotice(@lj, 'This feature is unavailable while in Airplane Mode.', 'error')
    return

  storeJot: (content, key, jot_type, break_from_top, color) =>
    now = new Date
    jot = 
      content: content
      is_temp: true
      temp_key: key
      topic_id: @lj.app.current_topic
      folder_id: @lj.app.current_folder
      jot_type: jot_type
      break_from_top: break_from_top
      color: color
      em_created_at: now.getTime()

    stored_jots = @getStoredJotsObject()
    stored_jots.push jot

    localStorage.jots = JSON.stringify(stored_jots)

  getStoredJotsObject: =>
    if localStorage.jots
      return JSON.parse(localStorage.jots)
    else
      return []

  saveStoredJots: (save_attempts_left) =>
    stored_jots = @getStoredJotsObject()

    if stored_jots.length > 0 && save_attempts_left > 0
      console.log "Attempting to save airplone mode jots with #{save_attempts_left} attempts left..."

      @lj.connection.abortPossibleDataLoadXHR()
      $.ajax(
        type: 'POST'
        url: '/jots'
        data: {"jots": stored_jots}
        success: (data) =>
          if data.error_list.length > 0
            # add a timeout so the reveal overlay doesn't glitch up and disappear
            setTimeout(() =>
              unsavedJotsAlert(data.error_list)
            , 500)

          $.each data.jots, (key, jot) =>
            @lj.app.jots.push jot
            @lj.jots.integrateTempJot jot, jot.temp_key

          # Now that jots were saved, let's sort them
          @lj.jots.sortJotsList()

          # Handle auto-generated folder or topic.
          if (typeof @lj.app.current_folder == 'undefined' || !@lj.app.current_folder) && typeof data.folder != 'undefined'
            @lj.folders.hideNewFolderForm()
            @lj.folders.pushFolderIntoData data.folder

          if (typeof @lj.app.current_topic == 'undefined' || !@lj.app.current_topic) && typeof data.topic != 'undefined'
            @lj.topics.hideNewTopicForm()
            @lj.topics.pushTopicIntoData data.topic
            
          @clearLocalStorage()

        error: (data) =>
          @saveStoredJots (save_attempts_left - 1)

        complete: (xhr, status) =>
          @lj.connection.startDataLoadTimer()
      )
    else
      @lj.connection.startDataLoadTimer()

    # unsavedJotsAlert fires upon savedStoredJots ajax success
    # but returns errors from the server
    unsavedJotsAlert = (error_list) =>
      @unsaved_jots_modal.foundation 'reveal', 'open'
      @unsaved_jots_modal.html @unsaved_jots_modal_template.html()
      $.each error_list, (key, item) =>
        if item.jot_type == "heading"
          type_desc = "Heading Jot"
          content = item.content
        else if item.jot_type == "checklist"
          type_desc = "Checklist Jot"
          content = @lj.jots.parseCheckListToText item.content
        else
          type_desc = "Standard Jot"
          content = item.content

        if item.break_from_top
          type_desc += ", space from top"

        @unsaved_jots_modal.find('textarea#error-list').append("#{type_desc}:\n#{content}\nError: #{item.error}\n\n")

      @unsaved_jots_modal.find('.close').click =>
        @unsaved_jots_modal.foundation 'reveal', 'close'

    # errorWhileAttemptingToSaveJots fires when the ajax request
    # has an error.. this can happen during a choppy internet connection,
    # when airplane mode starts up and then goes off, but internet
    # is still bad
    errorWhileAttemptingToSaveJots = =>
      @unsaved_jots_modal.foundation 'reveal', 'open'
      @unsaved_jots_modal.html @unsaved_jots_modal_template.html()
      $.each stored_jots, (key, item) =>
        if item.jot_type == "heading"
          type_desc = "Heading Jot"
          content = item.content
        else if item.jot_type == "checklist"
          type_desc = "Checklist Jot"
          content = @lj.jots.parseCheckListToText item.content
        else
          type_desc = "Standard Jot"
          content = item.content

        if item.break_from_top
          type_desc += ", space from top"

        @unsaved_jots_modal.find('textarea#error-list').append("#{type_desc}:\n#{content}\n\n")

      @unsaved_jots_modal.find('.close').click =>
        @unsaved_jots_modal.foundation 'reveal', 'close'

    if save_attempts_left == 0
      # Still can't save the jots.. let's give up and show what we couldn't save.
      errorWhileAttemptingToSaveJots()
      @clearLocalStorage()
      return

  clearLocalStorage: =>
    localStorage.clear()

  hasLocalStorage: =>
    try
      localStorage.setItem 'storage-test', 'test-value'
      localStorage.removeItem 'storage-test'
      return true
    catch e
      return false

  # This is ran upon Lite Jot init, in case user left in airplane mode
  # w/ unsaved jots
  checkLocalStorageContents: =>
    stored_jots = @getStoredJotsObject()
    if stored_jots.length > 0
      @saveStoredJots @max_save_attempts
