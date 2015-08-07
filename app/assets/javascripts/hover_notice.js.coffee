#= require litejot

class window.HoverNotice extends LiteJot
  constructor: (@lj, @message, type) ->
    @initVars()
    @buildNotice()

  initVars: =>
    @timer_seconds = 3000

  buildNotice: =>
    random_suffix = window.randomKey()
    $('body').append("<div id='hover-notice-#{random_suffix}' class='hover-notice'></div>")
    @elem = $("#hover-notice-#{random_suffix}")
    @elem.html(@message)

    @startTimer()
    @initBinds()

  startTimer: =>
    @timeout = setTimeout(@removeNotice, @timer_seconds)

  cancelTimer: =>
    clearTimeout @timeout

  initBinds: =>
    @elem.mouseenter => 
      @cancelTimer()

    @elem.mouseleave =>
      @startTimer()

  removeNotice: =>
    @elem.hide()