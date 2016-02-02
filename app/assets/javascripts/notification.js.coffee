#= require litejot

class window.Notification extends LiteJot
  constructor: (@lj, @notif_id, @title, @description, @time_to_show, @check_against_posted_notif_ids) ->
    # If @time_to_show == 0, then it stays til user closes

    # Feature needed by calendar.js to prevent multple notifications per event
    # when the calendar refreshes.
    # Checks against an array of notif_ids (or calendar item ids)
    # and stores the notif_id in the given array (if defined)
    if @check_against_posted_notif_ids.indexOf(@notif_id) == -1
      @initVars()
      @pushEventNotificationToScreen()
      @setHideTimer()

      if @check_against_posted_notif_ids
        @check_against_posted_notif_ids.push @notif_id

  initVars: =>
    @notification_template = $('#notification-template')
    @rid = window.randomKey()

  pushEventNotificationToScreen: =>
    html = @notification_template.html()

    $('body').append("<div class='notification' id='notification-#{@rid}'>#{html}</div>")
    elem = $(".notification#notification-#{@rid}")

    elem.find('h1').html("<i class='fa fa-bell-o'></i> #{@title}")
    elem.find('section.description').html(@description)
    elem.find('.new-topic-text').css('line-height', elem.outerHeight()+'px')

    elem.css({opacity: 1})
    @bindNotification()

    @orderNotifications()

  orderNotifications: =>
    offset_bottom = 0

    $.each $('.notification').get().reverse(), (key, this_elem) =>
      $(this_elem).css({
        bottom: offset_bottom
      })

      offset_bottom += $(this_elem).outerHeight(true)

  bindNotification: =>
    elem = $("#notification-#{@rid}")
    elem.find('a.close').click (e) =>
      e.preventDefault()
      @closeNotification()

    elem.find('.new-topic-overlay').click =>
      if @lj.airplane_mode.active
        @lj.airplane_mode.feature_unavailable_notice()
        return

      @lj.calendar.openEventTopicModal @title
      @closeNotification()

  closeNotification: =>
    elem = $("#notification-#{@rid}")

    elem.fadeOut(250, () =>
      elem.remove()
      @orderNotifications()
    )

    $.post('/notifications/acknowledge', { notif_id: @notif_id })

  setHideTimer: =>
    if @time_to_show > 0
      setTimeout(@closeNotification, @time_to_show)
