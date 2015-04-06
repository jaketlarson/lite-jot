#= require litejot

class window.Notifications extends LiteJot
  constructor: (@lj) ->
    @initVars
    @loadNotifications()

  initVars: =>
    @notifications_wrap = $('#notifications-wrap')
    @notifications_data = null

  loadNotifications: =>
    $.ajax(
      type: 'GET'
      url: '/notifications'
      success: (data) =>
        console.log data
        @notifications_data = data
        @handleNotifications()

      error: (data) =>
        console.log data
    )

  handleNotifications: =>
    console.log 'handle'
    