#= require lightjot

class window.Topics extends LightJot
  constructor: (@lj) ->
    @initVars()

  initVars: =>
    @topics_wrapper = $('#topics-wrapper')
    @topics_list = $('ul#topics-list')

  buildTopicsList: =>
    @topics_list.html('')

    if typeof @lj.app.current_topic == 'undefined' && @lj.app.topics.length > 0
      @lj.app.current_topic = @lj.app.topics[0].id

    @topics_list.prepend("#{$('#new-topic-template').html()}")
    $.each @lj.app.topics, (index, topic) =>
      @insertTopicElem(topic)

      if @lj.app.current_topic == topic.id
        $("li[data-topic='#{topic.id}']").addClass('current')

    @sortTopicsList()

  insertTopicElem: (topic, append = true) =>
    build_html = "<li data-topic='#{topic.id}' data-editing='false'>
                    <span class='title'>#{topic.title}</span>
                    <div class='input-edit-wrap'>
                      <input type='text' class='input-edit' />
                    </div>
                    <i class='fa fa-pencil edit' data-edit />
                    <i class='fa fa-trash delete' data-delete />
                  </li>"

    if append
      @topics_list.append build_html
    else
      @topics_list.find('.new-topic-form-wrap').after build_html

  sortTopicsList: =>
    offset_top = 0
    $.each @topics_list.find('li'), (index, topic_elem) =>
      # data-hidden is used on the new-topic li while it is being hidden but not quite !.is(:visible) yet
      if $(topic_elem).is(':visible') && $(topic_elem).attr('data-hidden') != 'true'
        $(topic_elem).css('top', offset_top)
        height = $(topic_elem).outerHeight()
        offset_top += height

  initTopicBinds: (topic_id) =>
    @topics_list.find("li:not(.new-topic-form-wrap)[data-topic='#{topic_id}']").click (e) =>
      @selectTopic($(e.currentTarget).data('topic'))

    @topics_list.find("li[data-topic='#{topic_id}'] [data-edit]").click (e) =>
      @editTopic(topic_id)
      return false

    @topics_list.find("li[data-topic='#{topic_id}'] .input-edit").click (e) =>
      return false

    @topics_list.find("li[data-topic='#{topic_id}'] [data-delete]").click (e1) =>
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

  selectTopic: (topic_id) =>
    $("li[data-topic='#{@lj.app.current_topic}']").removeClass('current')
    elem = $("li[data-topic='#{topic_id}']")
    @lj.app.current_topic = topic_id
    elem.addClass('current')

    @lj.jots.buildJotsList()
    @lj.jots.new_jot_content.focus()

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
      if e.keyCode == @lj.key_codes.enter
        e.preventDefault()
        finishEditing()

    finishEditing = =>
      if !submitted_edit
        submitted_edit = true
        elem.attr('data-editing', 'false')
        title.html(input.val())
        @lj.jots.new_jot_content.focus()

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

    $.ajax(
      type: 'POST'
      url: "/topics/#{id}"
      data: {'_method': 'delete'}

      success: (data) =>
        console.log data

      error: (data) =>
        console.log data
    )

    setTimeout(() =>
      topic_key = null
      $.each @lj.app.topics, (index, topic) =>
        if topic.id == id
          topic_key = index
          return false

      @lj.app.topics.remove(topic_key)
      elem.remove()
      @sortTopicsList()

      next_topic_elem = @topics_list.find('li:not(.new-topic-form-wrap)')[0]
      console.log $(next_topic_elem).data('topic')
      @selectTopic($(next_topic_elem).data('topic'))

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
    unless topic_title.val().trim().length == 0
      topic_title.attr 'disabled', true

      $.ajax(
        type: 'POST'
        url: '/topics'
        data: "title=#{topic_title.val()}"
        success: (data) =>
          @hideNewTopicForm()
          console.log data
          @lj.app.topics.unshift data.topic
          @insertTopicElem data.topic, false
          @sortTopicsList()
          @selectTopic(data.topic.id)
          @initTopicBinds(data.topic.id)
          topic_title.attr 'disabled', false

        error: (data) =>
          console.log data
        )

    else
      @hideNewTopicFrm

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
