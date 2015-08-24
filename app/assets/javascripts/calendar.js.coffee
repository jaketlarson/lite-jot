#= require litejot

class window.Calendar extends LiteJot
  constructor: (@lj) ->
    @initVars()

    if @cal_link.is(':visible')
      @initBinds()
      @loadCalItems()

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

  loadCalItems: =>
    @showLoading()

    $.ajax(
      type: 'GET'
      url: '/notifications/calendar'
      success: (data) =>
        @user_email = data.user_email
        @cal_loaded_data = $.parseJSON(data.calendar_items)
        @handleCalData()
        @hideLoading()

      error: (data) =>
    )

  handleCalData: =>
    $.each @cal_loaded_data, (index, cal_item) =>
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
                if attendee.email == @user_email
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
          cal_item.start_time_display = @prettyTimestamp new Date(cal_item.start.dateTime)
          cal_item.end_time_display = @prettyTimestamp new Date(cal_item.end.dateTime)

          if cal_item.event_finished
            event_class = 'event-finished'
          else if cal_item.event_in_progress
            event_class = 'event-in-progress'
          else
            event_class = ''

          html += "<li class='#{event_class}'>"
          html += "<section class='time'>#{cal_item.start_time_display}</section>"

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

    title = "<i class='fa fa-bell-o'></i> #{cal_item.summary}"

    # Build info
    info = "<i class='fa fa-clock-o'></i> #{cal_item.start_time_display} - #{cal_item.end_time_display}"
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
          new Notification @lj, cal_item.id, title, info, hide_at
        , time_until))
      else
        # if notification would've shown by now, show it now.
        new Notification @lj, cal_item.id, title, info, hide_at

  resetNotificationTimers: =>
    @cal_notifications.each (key, timer) =>
      clearTimeout timer
    @cal_notifications = []


  prettyTimestamp: (date) =>
    am_pm = if date.getHours() >= 12 then "pm" else "am"
    hour = (date.getHours() % 12)
    hour = if hour == 0 then 12 else hour
    minutes = date.getMinutes()
    minutes = if minutes == 0 then "00" else minutes

    return "#{hour}:#{minutes}#{am_pm}"
