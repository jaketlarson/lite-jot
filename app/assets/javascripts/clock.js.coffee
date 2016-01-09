#= require litejot

class window.Clock extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @updateClock()

  initVars: =>
    @clock_hover_wrap = $('#clock-hover-wrap')
    @clock_text = $('#clock-text')
    @update_interval = 2000 # 2 seconds

  updateClock: =>
    date = new Date
    hour = (date.getHours() % 12)
    hour = if hour == 0 then hour = 12 else hour = hour
    minutes = date.getMinutes()
    minutes = if minutes < 10 then minutes = "0#{minutes}" else minutes = minutes

    $('#clock-text').html("#{hour}:#{minutes}")

    calendar_icon_date = $('nav #cal-icon-date')
    calendar_icon_date.html(date.getDate())

    setTimeout(() =>
      @updateClock()
    , @update_interval)
    

  showClock: =>
    @clock_hover_wrap.show()

  hideClock: =>
    @clock_hover_wrap.hide()
