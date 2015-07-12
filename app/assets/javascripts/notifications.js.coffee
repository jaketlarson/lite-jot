#= require litejot

class window.Notifications extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @loadNotifications()

  initVars: =>
    #@notifications_wrap = $('#notifications-wrap')
    @notifications_data = null
    @notification_template = $('#notification-template')
    @user_email = null

  loadNotifications: =>
    $.ajax(
      type: 'GET'
      url: '/notifications/calendar'
      success: (data) =>
        console.log data
        @user_email = data.user_email
        @notifications_data = $.parseJSON(data.notifications)
        @handleNotificationData()

      error: (data) =>
        console.log data
    )

  handleNotificationData: =>
    $.each @notifications_data, (index, notification) =>
      @pushEventNotificationToScreen notification

  pushEventNotificationToScreen: (notification) =>
    html = @notification_template.html()
    id = window.randomKey()
    $('body').append("<div class='notification' id='notification-#{id}'>#{html}</div>")
    elem = $(".notification#notification-#{id}")

    elem.find('h1')
      .html(notification.summary)

    attendees_text = ""
    if notification.attendees

      $.each notification.attendees, (index, attendee) =>
        if attendee
          if attendee.email == @user_email
            notification.attendees.remove(index)
            return


      attendees_count = notification.attendees.length

      $.each notification.attendees, (index, attendee) =>
        if index == attendees_count - 1 && attendees_count > 1
          attendees_text += " and "

        attendees_text += "#{attendee.displayName}"

        if index < attendees_count - 2
          attendees_text += ", "


    if attendees_count > 0
      attendees_text = "<br />with "+ attendees_text
      elem.find('section.description').html(attendees_text)

    day = notification.start.day
    date = new Date(notification.start.dateTime)
    console.log date
    am_pm = if date.getHours() >= 12 then "pm" else "am"
    hour = (date.getHours() % 12)
    hour = if hour == 0 then 12 else hour
    minutes = date.getMinutes()
    minutes = if minutes == 0 then "00" else minutes
    elem.find('section.description').prepend("#{day} at #{hour}:#{minutes}#{am_pm}&nbsp;")

    elem.css({opacity: 1})
    @bindNotification id

    @orderNotifications()

  orderNotifications: =>
    offset_bottom = $('#status-bar').outerHeight(true)

    $.each $('.notification').get().reverse(), (key, this_elem) =>
      $(this_elem).css({
        bottom: offset_bottom
      })

      offset_bottom += $(this_elem).outerHeight(true)

  bindNotification: (id) =>
    elem = $("#notification-#{id}")
    elem.find('a.close').click (e) =>
      e.preventDefault()
      @closeNotification id

  closeNotification: (id) =>
    elem = $("#notification-#{id}")

    elem.fadeOut(250, () =>
      elem.remove()
      @orderNotifications()
    )

