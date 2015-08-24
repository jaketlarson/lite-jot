#= require litejot

class window.Notification extends LiteJot
  constructor: (@lj, @notif_id, @title, @description, @time_to_show) ->
    # If @time_to_show == 0, then it stays til user closes
    @initVars()
    @pushEventNotificationToScreen()
    @setHideTimer()

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
      if @lj.emergency_mode.active
        @lj.emergency_mode.feature_unavailable_notice()
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
