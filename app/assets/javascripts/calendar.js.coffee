#= require litejot

class window.Calendar extends LiteJot
  constructor: (@lj) ->
    @initVars()

    if @cal_link.is(':visible')
      @initBinds()
      @loadCalItems(init=true)

  initVars: =>
    @cal_list_wrap = $('#cal-list-wrap')
    @cal_items_elem = $('#cal-items')
    @cal_link = $('a#calendar-link')
    @cal_loaded_data = null
    @cal_items = {}
    @month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    @cal_empty_message = $('#cal-empty-message')
    @cal_loading = $('#cal-loading')
    @event_reminder_minutes = 10
    @cal_notifications = []
    @event_topic_modal = $('#calendar-event-topic-modal')
    @event_topic_modal_template = $('#calendar-event-topic-template')
    @cal_error_message = $('#cal-error-message')

    @refresh_timer = null
    @refresh_timing = 5*60*1000

    # Contains id's of calendar events posted as notifications to client.
    # This is a fix for event notification duplicates, and will still
    # show the notifications on every instance opened (multiple tabs, etc.)
    @cal_notifications_posted = []

  initBinds: =>
    @cal_link.click (event) =>
      event.stopPropagation()
      if @cal_list_wrap.is(':visible')
        @closeCal()
      else
        @openCal()

    @cal_list_wrap.click (event) =>
      event.stopPropagation()

    $('a#calendar-info-modal-link').click (e) =>
      $('#calendar-info-modal').foundation 'reveal', 'open'
      $('#calendar-info-modal').html($('#calendar-info-modal-template').html())

      $('#calendar-info-modal .confirm').click (e2) =>
        $('#calendar-info-modal').foundation 'reveal', 'close'

    $(document).bind 'click', () =>
      @closeCal()

  openCal: =>
    @cal_list_wrap.show()
    @cal_link.addClass('active')
    @positionCal()

  closeCal: =>
    @cal_list_wrap.hide()
    @cal_link.removeClass('active')
    @cal_link.removeClass('active')
    @cal_link.removeClass('active')

  showLoading: =>
    @cal_loading.show()

  hideLoading: =>
    @cal_loading.hide()

  positionCal: =>
    pos_top = @cal_link.offset().top + @cal_link.height()
    pos_right = $(document).width() - @cal_link.offset().left - @cal_link.outerWidth()
    @cal_list_wrap.css({
      top: pos_top
      right: pos_right
    })

  loadCalItems: (init=false) =>
    if init
      @showLoading()

    $.ajax(
      type: 'GET'
      url: '/notifications/calendar'
      success: (data) =>
        @cal_error_message.hide()
        if init
          @hideLoading()
        else
          @resetNotificationTimers()

        @cal_loaded_data = $.parseJSON(data.calendar_items)
        @handleCalData()

        @initRefreshTimer()

      error: (data) =>
        @cal_error_message.show()
        @hideLoading()
        @initRefreshTimer()
    )

  handleCalData: =>
    @cal_items = {}
    $.each @cal_loaded_data, (index, cal_item) =>
      console.log cal_item
      if !@cal_items[cal_item.start.day]
        @cal_items[cal_item.start.day] = []

      @cal_items[cal_item.start.day].push cal_item

    @updateCalView()

  updateCalView: =>
    if $.isEmptyObject @cal_items
      @cal_empty_message.show()
    else
      @cal_empty_message.hide()

      html = ""
      
      $.each @cal_items, (key, items) =>
        date = new Date(items[0].start.dateTime)
        date_heading = "#{@month_names[date.getMonth()]} #{date.getDate()}"

        html += "<article id='cal-items-of-#{key.toLowerCase()}'>"
        html += "<h3>"
        html += "#{key}"
        html += "<span class='date'>#{date_heading}</span>"
        html += "</h3>"
        html += "<ul>"

        $.each items, (index, cal_item) =>
          attendees_text = ''
          if cal_item.attendees
            $.each cal_item.attendees, (index, attendee) =>
              if attendee
                if attendee.email == @lj.app.user.email
                  cal_item.attendees.remove(index)
                  return

            attendees_count = cal_item.attendees.length

            $.each cal_item.attendees, (index, attendee) =>
              if index == attendees_count - 1 && attendees_count > 1
                attendees_text += " and "

              attendees_text += "#{attendee.displayName}"

              if index < attendees_count - 2
                attendees_text += ", "

          cal_item.attendees_text = attendees_text

          if cal_item.event_finished
            event_class = 'event-finished'
          else if cal_item.event_in_progress
            event_class = 'event-in-progress'
          else
            event_class = ''

          html += "<li class='#{event_class}'>"
          html += "<section class='time'>#{cal_item.start.timestamp}</section>"

          html += "<h4>#{cal_item.summary}</h4>"

          if cal_item.location
            html += "<p>"
            html += "<i class='fa fa-map-marker' />#{cal_item.location}"
            html += "</p>"

          if attendees_count > 0
            attendees_text = "<i class='fa fa-group' />with #{attendees_text}"
            html += "<p>"
            html += attendees_text
            html += "</p>"

          html += "</li>"

          @setNotification cal_item

        html += "</ul>"
        html += "</article>"

      @cal_items_elem.html(html)

  setNotification: (cal_item) =>
    # Check to see if user has already seen this notification 
    # (i.e., clicked the X on the notification)
    user = @lj.app.user
    if user.notifications_seen && user.notifications_seen.length > 0
      if user.notifications_seen.indexOf(cal_item.id) > -1
        # They've seen it, abort.
        return

    title = cal_item.summary

    # Build info
    info = "<i class='fa fa-clock-o'></i> #{cal_item.notif_time_span}"
    if cal_item.location
      info += "<br /><i class='fa fa-map-marker' /> #{cal_item.location}"
    if cal_item.attendees_text.length > 0
      info += "<br /><i class='fa fa-group'></i> with #{cal_item.attendees_text}"

    # Schedule notification
    current_unix = new Date().valueOf()
    time_until = parseInt(cal_item.start.dateTime_unix)*1000 - current_unix - @event_reminder_minutes*60000
    hide_at = parseInt(cal_item.end.dateTime_unix)*1000 - current_unix

    if parseInt(cal_item.end.dateTime_unix)*1000 > current_unix
      if parseInt(cal_item.start.dateTime_unix)*1000 - @event_reminder_minutes*60000 > current_unix
        # if it's more than @event_reminder_minutes away, then set timer for notification show time
        @cal_notifications.push(setTimeout(() =>
          new Notification @lj, cal_item.id, title, info, hide_at, @cal_notifications_posted
        , time_until))
      else
        # if notification would've shown by now, show it now.
        new Notification @lj, cal_item.id, title, info, hide_at, @cal_notifications_posted

  resetNotificationTimers: =>
    $.each @cal_notifications, (key, timer) =>
      clearTimeout timer
    @cal_notifications = []

  openEventTopicModal: (title) =>
    @event_topic_modal.foundation 'reveal', 'open'
    @event_topic_modal.html @event_topic_modal_template.html()
    @event_topic_modal.find('button.cancel').click =>
      @closeEventTopicModal()

    @event_topic_modal.find('input').val title

    if @lj.app.folders.filter((folder) -> folder.has_manage_permissions).length > 0
      $.each @lj.app.folders.filter((folder) -> folder.has_manage_permissions), (index, folder) =>
        @event_topic_modal.find('select#cal-folder-choices')
        .append("<option value='#{folder.id}'>#{folder.title}</option>")
    else
      @event_topic_modal.find('.cal-event-existing-folder-wrap').hide()

    @event_topic_modal.find('.cal-event-existing-folder-wrap form').submit (e) =>
      e.preventDefault()
      @submitEventTopicForm('existing-folder')

    @event_topic_modal.find('.cal-event-new-folder-wrap form').submit (e) =>
      e.preventDefault()
      @submitEventTopicForm('new-folder')


  submitEventTopicForm: (mode) =>
    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return

    # Define folder create action, based off regular method
    createFolder = (folder_title, topic_title) =>
      filtered_content = window.escapeHtml(folder_title)
      topic_title_blank = if window.escapeHtml(topic_title).trim().length == 0 then true else false
      unless filtered_content.trim().length == 0 || topic_title_blank
        # Disable elements
        @event_topic_modal.find('select, input, button').attr('disabled', true)

        $.ajax(
          type: 'POST'
          url: '/folders'
          data: "title=#{encodeURIComponent(filtered_content)}"
          success: (data) =>
            @lj.folders.pushFolderIntoData data.folder
            @lj.key_controls.clearKeyedOverData()
            @lj.folders.selectFolder data.folder.id
            createTopic data.folder.id, topic_title

          error: (data) =>
            # Re-enable form elements
            @event_topic_modal.find('select:disabled, input:disabled, button:disabled').attr('disabled', false)
            
            unless typeof data.responseJSON.error == 'undefined'
              new HoverNotice(@lj, data.responseJSON.error, 'error')
            else
              new HoverNotice(@lj, 'Could not create folder.', 'error')
          )

    # Define topic create action, based off regular method
    createTopic = (folder_id, title) =>
      filtered_content = window.escapeHtml(title)
      unless filtered_content.trim().length == 0
        # Disable elements
        @event_topic_modal.find('select, input, button').attr('disabled', true)

        $.ajax(
          type: 'POST'
          url: '/topics'
          data: "folder_id=#{folder_id}&title=#{encodeURIComponent(filtered_content)}"
          success: (data) =>
            new HoverNotice @lj, 'Topic created.', 'success'
            @lj.key_controls.clearKeyedOverData()
            @lj.folders.selectFolder data.topic.folder_id
            @lj.topics.pushTopicIntoData data.topic
            @lj.topics.hideNewTopicForm()
            @closeEventTopicModal()

            if @lj.folders.new_folder_title.val().trim().length == 0
              @lj.folders.hideNewFolderForm()

          error: (data) =>
            # Re-enable form elements
            @event_topic_modal.find('select:disabled, input:disabled, button:disabled').attr('disabled', false)
            
            unless typeof data.responseJSON.error == 'undefined'
              new HoverNotice(@lj, data.responseJSON.error, 'error')
            else
              new HoverNotice(@lj, 'Could not create folder.', 'error')
          )

      else
        # Re-enable form elements
        @event_topic_modal.find('select:disabled, input:disabled, button:disabled').attr('disabled', false)
        
    # Determine course of action
    if mode == 'existing-folder'
      folder_id = parseInt(@event_topic_modal.find('#cal-folder-choices').val())
      topic_title = @event_topic_modal.find('#cal-topic-title').val()
      createTopic folder_id, topic_title
    else if mode =='new-folder'
      folder_title = @event_topic_modal.find('#cal-folder-title').val()
      topic_title = @event_topic_modal.find('#cal-new-folder-topic-title').val()
      createFolder folder_title, topic_title

  closeEventTopicModal: =>
    @event_topic_modal.foundation 'reveal', 'close'

  initRefreshTimer: =>
    if @refresh_timer
      clearTimeout @refresh_timer

    setTimeout(() =>
      @loadCalItems()
    , @refresh_timing)
      
