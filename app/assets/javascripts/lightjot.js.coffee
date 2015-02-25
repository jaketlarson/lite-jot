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
    @topics_list.html('')

    if typeof @app.current_topic == 'undefined' && @app.topics.length > 0
      @app.current_topic = @app.topics[0].id

    offset_top = 0
    $.each @app.topics, (index, topic) =>
      if @app.current_topic == topic.id
        $("li[data-topic='#{topic.id}']").addClass('current')
        console.log @topics_list.find("li[data-topic='#{topic.id}']")
        console.log 'okay'

      @topics_list.append("<li data-topic='#{topic.id}'>#{topic.title}</li>")
      topic_elem = @topics_list.find("li[data-topic='#{topic.id}']")
      topic_elem.css('top', offset_top+'px')
      height = topic_elem.outerHeight()
      offset_top += height

    console.log 'here'
    console.log @app.topics
    console.log @app.current_topic

    @initTopicsBinds()


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

    # topic_key_to_temporarily_delete = null
    # topic_object_to_temporarily_delete = null
    
    # $.each @app.topics, (index, topic) =>
    #   if topic.id == topic_id
    #     topic_key_to_temporarily_delete = index
    #     topic_object_to_temporarily_delete = topic
    #     return false

    # delete @app.topic[topic_key_to_temporarily_delete]
    # @app.prepend(topic_object_to_temporarily_delete)


    @buildJotsList()
    @buildTopicsList()

  reloadTopics: =>
    $.ajax(
      type: 'GET'
      url: '/topics'

      success: (data) =>
        @app.topics = data.topics
        @buildTopicsList()

      error: (data) =>
        console.log data
    )

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

    @reloadTopics()

    #reset new jot form
    @clearJotEntryTemplate()
    @new_jot_content.val('')

  clearJotEntryTemplate: =>
    @jot_entry_template.find('li').html('')
