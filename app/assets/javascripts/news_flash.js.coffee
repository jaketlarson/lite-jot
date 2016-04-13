# New features are announced via a "news flash" that shows once for the user
# If an element #news-flash exists this module will detect it and show it
# to the user.

class window.NewsFlash extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @checkIfExists()

  initVars: =>
    @screen = $('#news-flash')
    @counter_start = 300
    @li_counter_interval = 250
    @close_button_show_at = 1050
    @close_button_fadein_time = 500
    @screen_fadeaway_time = 300

  checkIfExists: =>
    if @screen.length > 0
      @performAnimation()

  performAnimation: =>
    counter = @counter_start
    $.each @screen.find('li'), (key, elem) =>
      setTimeout(() =>
        $(elem).addClass('show')
      , counter)

      counter += @li_counter_interval

    setTimeout(() =>
      $('#news-flash .close-button-wrap').fadeIn(@close_button_show_at)
    , @close_button_show_at)

    $('#news-flash .close-button-wrap a.button, #news-flash .close-x, #news-flash .logo').click =>
      $('#news-flash').addClass('disappear')

      setTimeout(() =>
        $('#news-flash').hide()
      , @screen_fadeaway_time)
