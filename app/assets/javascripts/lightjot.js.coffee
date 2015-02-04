$ ->
  lightjot = new window.LightJot()

class window.LightJot
  constructor: ->
    @initVars()
    @initElems()
    @initFullScreenListener()
    @initJotFormListeners()

  initVars: =>
    @fullscreen_expand_icon_class = 'fa-expand'
    @fullscreen_compress_icon_class = 'fa-compress'
    @new_jot_form = $('form#new_jot')
    @new_jot_content = @new_jot_form.find('textarea#jot_content')
    @jots_wrapper = $('#jots-wrapper')
    @jots_list = @jots_wrapper.find('#jots-list')
    @jot_entry_template = $('#jot-entry-template')

    @key_codes =
      enter: 13

  initElems: =>
    @fullscreen_btn = $('a#fullscreen-request')

  initFullScreenListener: =>
    @fullScreenHandler()
    
    @fullscreen_btn.click =>
      @toggleFullScreen()
      document.documentElement.webkitRequestFullScreen()

    document.addEventListener "webkitfullscreenchange", @fullScreenHandler
    document.addEventListener "fullscreenchange", @fullScreenHandler
    document.addEventListener "webkitfullscreenchange", @fullScreenHandler
    document.addEventListener "mozfullscreenchange", @fullScreenHandler
    document.addEventListener "MSFullscreenChange", @fullScreenHandler

  fullScreenHandler: =>
    if document.fullscreenElement || document.webkitFullscreenElement || document.mozFullScreenElement || document.msFullscreenElement
      @showFullScreenCompressButton()
    else
      @showFullScreenExpandButton()

  toggleFullScreen: =>
    if document.fullscreenElement || document.webkitFullscreenElement || document.mozFullScreenElement || document.msFullscreenElement
      document.exitFullscreen

      if document.exitFullscreen
        document.exitFullscreen()

      else if document.webkitExitFullscreen
        document.webkitExitFullscreen()

      else if document.mozCancelFullScreen
        document.mozCancelFullScreen()

      else if document.msExitFullscreen
        document.msExitFullscreen()

  showFullScreenExpandButton: =>
    if !@fullscreen_btn.find('i').hasClass(@fullscreen_expand_icon_class)
      @fullscreen_btn.find('i').addClass(@fullscreen_expand_icon_class)
        
    if @fullscreen_btn.find('i').hasClass(@fullscreen_compress_icon_class)
      @fullscreen_btn.find('i').removeClass(@fullscreen_compress_icon_class)

  showFullScreenCompressButton: =>
    if @fullscreen_btn.find('i').hasClass(@fullscreen_expand_icon_class)
      @fullscreen_btn.find('i').removeClass(@fullscreen_expand_icon_class)
        
    if !@fullscreen_btn.find('i').hasClass(@fullscreen_compress_icon_class)
      @fullscreen_btn.find('i').addClass(@fullscreen_compress_icon_class)

  initJotFormListeners: =>
    @new_jot_form.submit (e) =>
      e.preventDefault()
      content = @new_jot_content.val()
      @jot_entry_template.find('li').append(content)
      build_entry = @jot_entry_template.html()

      @jots_list.append(build_entry)

      $.ajax(
        type: 'POST'
        url: @new_jot_form.attr('action')
        data: "content=#{content}"
        success: (data) =>
          console.log data

        error: (data) =>
          console.log data

      )

      #reset new jot form
      @clearJotEntryTemplate()
      @new_jot_content.val('')

    @new_jot_content.keydown (e) =>
      if e.keyCode == @key_codes.enter && !e.shiftKey # enter key
        e.preventDefault()
        @new_jot_form.submit()


  clearJotEntryTemplate: =>
    @jot_entry_template.find('li').html('')