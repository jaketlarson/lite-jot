# Array Remove - By John Resig (MIT Licensed)
Array::remove = (from, to) ->
  rest = @slice((to or from) + 1 or @length)
  @length = if from < 0 then @length + from else from
  @push.apply this, rest



$ ->
  lightjot = new window.LightJot()

class window.LightJot
  constructor: ->
    @loadDataFromServer()
    @initVars()
    @initElems()
    @initFullScreenListener()
    @initJotFormListeners()
    @sizeUI()

  initVars: =>
    @fullscreen_expand_icon_class = 'fa-expand'
    @fullscreen_compress_icon_class = 'fa-compress'
    @new_jot_form = $('form#new_jot')
    @new_jot_content = @new_jot_form.find('textarea#jot_content')
    @jots_wrapper = $('#jots-wrapper')
    @jots_list = @jots_wrapper.find('ul#jots-list')
    @jot_entry_template = $('#jot-entry-template')

    @topics_wrapper = $('#topics-wrapper')
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

  sizeUI: =>
    jots_height = window.innerHeight - $('header').outerHeight() - $('#jots-heading').outerHeight(true) - @new_jot_content.outerHeight(true)
    @jots_wrapper.css 'height', jots_height

    topics_height = window.innerHeight - $('header').outerHeight() - $('#topics-heading').outerHeight(true)
    @topics_wrapper.css 'height', topics_height

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
        @initNewtopicListeners()
        @buildJotsList()

      error: (data) =>
        console.log data
    )

  buildTopicsList: =>
    @topics_list.html('')

    if typeof @app.current_topic == 'undefined' && @app.topics.length > 0
      @app.current_topic = @app.topics[0].id

    $.each @app.topics, (index, topic) =>
      @topics_list.append("<li data-topic='#{topic.id}' data-editing='false'>
                            <span class='title'>#{topic.title}</span>
                            <div class='input-edit-wrap'>
                              <input type='text' class='input-edit' />
                            </div>
                            <i class='fa fa-pencil edit' data-edit />
                            <i class='fa fa-trash delete' data-delete />
                          </li>")

      if @app.current_topic == topic.id
        $("li[data-topic='#{topic.id}']").addClass('current')

    @topics_list.prepend("#{$('#new-topic-template').html()}")
    @sortTopicsList()

  sortTopicsList: =>
    offset_top = 0
    $.each @topics_list.find('li'), (index, topic_elem) =>
      # data-hidden is used on the new-topic li while it is being hidden but not quite !.is(:visible) yet
      if $(topic_elem).is(':visible') && $(topic_elem).attr('data-hidden') != 'true'
        $(topic_elem).css('top', offset_top)
        height = $(topic_elem).outerHeight()
        offset_top += height

  initTopicsBinds: =>
    @topics_list.find('li:not(.new-topic-form-wrap)').click (e) =>
      @selectTopic(e)

    @topics_list.find('li [data-edit]').click (e) =>
      id = $(e.currentTarget).closest('li').data('topic')
      @editTopic(id)

    @topics_list.find('li [data-delete]').click (e1) =>
      $('#delete-modal').foundation 'reveal', 'open'
      $('#delete-modal').html($('#delete-modal-template').html())

      $('#delete-modal .cancel').click (e2) ->
        $('#delete-modal').foundation 'reveal', 'close'

      $('#delete-modal .confirm').click (e2) =>
        id = $(e1.currentTarget).closest('li').data('topic')

        $('#delete-modal').foundation 'reveal', 'close'

        setTimeout(() =>
          @deleteTopic(id)
        , 250)

  buildJotsList: =>
    @jots_list.html('')

    $.each @app.jots, (index, jot) =>
      if jot.topic_id == @app.current_topic
        @jots_list.append("<li>#{jot.content}</li>")

    @scrollJotsToBottom()

  selectTopic: (e, topic_id) =>
    $("li[data-topic='#{@app.current_topic}']").removeClass('current')
    target = $(e.currentTarget)
    @app.current_topic = target.data('topic')
    target.addClass('current')

    @buildJotsList()

  editTopic: (id) =>
    elem = $("li[data-topic='#{id}']")
    input = elem.find('input.input-edit')
    title = elem.find('.title')
    input.val(title.html())
    elem.attr('data-editing', 'true')
    input.focus()

    submitted_edit = false

    input.blur (e) =>
      finishEditing()

    input.keydown (e) =>
      if e.keyCode == @key_codes.enter
        finishEditing()

    finishEditing = =>
      if !submitted_edit
        submitted_edit = true
        elem.attr('data-editing', 'false')
        title.html(input.val())

        $.ajax(
          type: 'PATCH'
          url: "/topics/#{id}"
          data: "title=#{input.val()}"

          success: (data) =>
            console.log data

          error: (data) =>
            console.log data
        )

  deleteTopic: (id) =>
    elem = $("li[data-topic='#{id}']")
    elem.attr('data-deleting', 'true')

    setTimeout(() =>
      topic_key = null
      $.each @app.topics, (index, topic) =>
        if topic.id == id
          topic_key = index
          return false

      @app.topics.remove(topic_key)
      elem.remove()
      @sortTopicsList()
    , 350)

  initNewtopicListeners: =>
    $('.new-topic-icon').click (e) =>
      if !@topics_list.find('li.new-topic-form-wrap').is(':visible')
        @newTopic()
        @topics_list.find('input#topic_title').focus() # dont like how there are two #topic_titles (from template)

    @topics_list.find('input#topic_title').blur (e) =>
      if @topics_list.find('form#new_topic #topic_title').val().trim().length == 0
        @hideNewTopicForm()

    $('form#new_topic').submit (e) =>
      e.preventDefault()
      @submitNewTopic()

  newTopic: =>
    @showNewTopicForm()
    @sortTopicsList()

  submitNewTopic: =>
    topic_title = @topics_list.find('form#new_topic #topic_title')
    if topic_title.val().trim().length == 0
      @hideNewTopicForm()

  showNewTopicForm: =>
    @topics_list.find('li.new-topic-form-wrap').show().attr('data-hidden', 'false')

  hideNewTopicForm: =>
    @topics_list.find('li.new-topic-form-wrap').attr('data-hidden', 'true').css('opacity', 0)

    @sortTopicsList()

    setTimeout(() =>
      @topics_list.find('li.new-topic-form-wrap').hide().css({
        opacity: 1
      })

      @topics_list.find('form#new_topic #topic_title').val('')
    , 250)

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
    @scrollJotsToBottom()

    $.ajax(
      type: 'POST'
      url: @new_jot_form.attr('action')
      data: "content=#{content}&topic_id=#{@app.current_topic}"
      success: (data) =>
        console.log data

      error: (data) =>
        console.log data
    )

    topic_key_to_move = null
    topic_object_to_move = null

    # find topic to move
    $.each @app.topics, (index, topic) =>
      if topic.id == @app.current_topic
        topic_key_to_move = index
        topic_object_to_move = topic
        return false

    # move topic being written in to top of list
    temp_list = $.extend({}, @app.topics)
    for i in [0...topic_key_to_move]
      temp_list[i+1] = @app.topics[i]

    @app.topics = $.extend({}, temp_list)

    @app.topics[0] = topic_object_to_move
    @sortTopicsList()

    # reset new jot form
    @clearJotEntryTemplate()
    @new_jot_content.val('')

  scrollJotsToBottom: =>
    @jots_wrapper.scrollTop @jots_wrapper[0].scrollHeight

  clearJotEntryTemplate: =>
    @jot_entry_template.find('li').html('')
