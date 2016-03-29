class window.Aside extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @initToggleListener()
    @determineStateOnInit()

  initVars: =>
    @show_trigger = $('#show-aside')

  initToggleListener: =>
    @show_trigger.click =>
      @toggle()

    $('nav h2').click =>
      @toggle()

  # Since it's hidden on load...
  showToggle: =>
    @show_trigger.show()

  determineStateOnInit: =>
    # Determine, based on viewport, if we hide folder/topic columns on init
    if !Foundation.utils.is_large_up()
      $('body').addClass('hide-aside')

  toggle: =>
    if $('body').hasClass('hide-aside')
      $('body').removeClass('hide-aside')
    else
      $('body').addClass('hide-aside')
