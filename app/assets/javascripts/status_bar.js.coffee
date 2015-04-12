#= require litejot

class window.StatusBar extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @updateClock()

  initVars: =>
    @clock_text = $('#clock-text')
    @update_interval = 2000 # 2 seconds

  updateClock: =>
    date = new Date
    hour = (date.getHours() % 12)
    hour = if hour == 0 then hour = 12 else hour = hour
    minutes = date.getMinutes()
    minutes = if minutes < 10 then minutes = "0#{minutes}" else minutes = minutes

    $('#clock-text').html("#{hour}:#{minutes}")

    setTimeout(() =>
      @updateClock()
    , @update_interval)
    