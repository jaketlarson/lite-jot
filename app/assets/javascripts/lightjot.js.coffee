$ ->
  lightjot = new window.LightJot()

class window.LightJot
  constructor: ->
    @loadDataFromServer()
    @initVars()
    @initElems()
    @initFullScreenListener()
    @initJotFormListeners()
    @sizeJotsWrapper()

  initVars: =>
    @fullscreen_expand_icon_class = 'fa-expand'
    @fullscreen_compress_icon_class = 'fa-compress'
    @new_jot_form = $('form#new_jot')
    @new_jot_content = @new_jot_form.find('textarea#jot_content')
    @jots_wrapper = $('#jots-wrapper')
    @jots_list = @jots_wrapper.find('ul#jots-list')
    @jot_entry_template = $('#jot-entry-template')
    @topics_list = $('ul#topics-list')

    @app = {} # all loaded app data goes here

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

  sizeJotsWrapper: =>
    build_height = window.innerHeight - $('header').outerHeight() - $('h2').outerHeight(true) - @new_jot_content.outerHeight(true)
    @jots_wrapper.css 'height', build_height

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

  loadDataFromServer: =>
    $.ajax(
      type: 'GET'
      url: '/load-data'
      success: (data) =>
        console.log data
        @app.folders = data.folders
        @app.topics = data.topics
        @app.jots = data.jots

        @buildTopicsList()
        @initTopicsBinds()
        @buildJotsList()

      error: (data) =>
        console.log data
    )

  buildTopicsList: =>
    $.each @app.topics, (index, topic) =>
      @topics_list.append("<li data-topic='#{topic.id}'>#{topic.title}</li>")

    if @topics_list.find('li').length > 0
      $(@topics_list.find('li')[0]).addClass('current')
      @app.current_topic = @app.topics[0].id

  initTopicsBinds: =>
    @topics_list.find('li').click (e) =>
      @selectTopic(e)

  buildJotsList: =>
    @jots_list.html('')

    $.each @app.jots, (index, jot) =>
      if jot.topic_id == @app.current_topic
        @jots_list.append("<li>#{jot.content}</li>")

  selectTopic: (e, topic_id) =>
    $("li[data-topic='#{@app.current_topic}']").removeClass('current')
    target = $(e.currentTarget)
    @app.current_topic = target.data('topic')
    target.addClass('current')
    @buildJotsList()

  initJotFormListeners: =>
    @new_jot_form.submit (e) =>
      e.preventDefault()
      @submitNewJot()

    @new_jot_content.keydown (e) =>
      if e.keyCode == @key_codes.enter && !e.shiftKey # enter key w/o shift key means submission
        e.preventDefault()
        @new_jot_form.submit()

  submitNewJot: =>
    content = @new_jot_content.val()
    @jot_entry_template.find('li').append(content)
    build_entry = @jot_entry_template.html()

    @jots_list.append(build_entry)

    $.ajax(
      type: 'POST'
      url: @new_jot_form.attr('action')
      data: "content=#{content}&topic_id=#{@app.current_topic}"
      success: (data) =>
        console.log data

      error: (data) =>
        console.log data

    )

    #reset new jot form
    @clearJotEntryTemplate()
    @new_jot_content.val('')

  clearJotEntryTemplate: =>
    @jot_entry_template.find('li').html('')
