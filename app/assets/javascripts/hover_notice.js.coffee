#= require litejot

class window.HoverNotice extends LiteJot
  constructor: (@lj, @message, @type=null) ->
    @initVars()
    @buildNotice()

  initVars: =>
    @timer_seconds = 3000

  buildNotice: =>
    random_suffix = window.randomKey()
    $('body').append("<div id='hover-notice-#{random_suffix}' class='hover-notice'></div>")
    @elem = $("#hover-notice-#{random_suffix}")
    @elem.html(@message)

    set_left = $('body').width()/2 - @elem.width()/2

    @elem.css(
      left: set_left
    )

    if @type == 'error'
      @elem.addClass 'error'
      @elem.prepend "<i class='fa fa-warning'></i>"
    else if @type == 'success'
      @elem.addClass 'success'
      @elem.prepend "<i class='fa fa-check'></i>"

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
    @elem.remove()