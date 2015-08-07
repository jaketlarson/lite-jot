#= require litejot

class window.Topics extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @initScrollBind()
    @initDeleteTopicModalBinds()

  initVars: =>
    @topics_heading = $('h2#topics-heading')
    @topics_column = $('#topics-column')
    @topics_wrapper = $('#topics-wrapper')
    @topics_list = $('ul#topics-list')
    @new_topic_form_wrap = null
    @new_topic_title = null

  initScrollBind: =>
    @topics_wrapper.scroll =>
      @checkScrollPosition()

  checkScrollPosition: =>
    if @topics_wrapper.scrollTop() > 0
      @topics_heading.addClass('is-scrolled-from-top')
    else
      @topics_heading.removeClass('is-scrolled-from-top')

  initDeleteTopicModalBinds: =>
    $('#delete-topic-modal').keydown (e) =>
      if e.keyCode == @lj.key_controls.key_codes.esc
        @cancelDeleteTopic()

      else if e.keyCode == @lj.key_controls.key_codes.y
        id = $("li[data-keyed-over='true']").data('topic')
        @confirmDeleteTopic id

  buildTopicsList: (organize_dom=true) =>
    @topics_list.html('')

    if (typeof @lj.app.current_topic == 'undefined' || !@lj.app.current_topic || @lj.app.current_topic == null) && @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder).length > 0
      @lj.app.current_topic = @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder)[0].id

    @topics_list.prepend("#{$('#new-topic-template').html()}")
    @new_topic_form_wrap = @topics_wrapper.find('li.new-topic-form-wrap')
    @new_topic_title = @new_topic_form_wrap.find('input#topic_title')

    if @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder).length > 0
      $.each @lj.app.topics, (index, topic) =>
        if topic.folder_id == @lj.app.current_folder
          @insertTopicElem(topic)

          if @lj.app.current_topic == topic.id
            $("li[data-topic='#{topic.id}']").addClass('current')

      $.each @lj.app.topics, (index, topic) =>
        @initTopicBinds(topic.id)

      # organize_dom is an option because if a user submits a jot while in search mode
      # the jot submission process would be redundantly calling the sortTopicsList()
      # and selectFirstTopic() functions again and cause unexpected behavior in the UI.
      # The organize_dom option can be carried from Jots.submitNewJot to Jots.endSearchState 
      # to Jots.restoreMasterData to LiteJot.buildUI to here.
      # It has not yet been necessary to add the organize_dom logic to Folders.buildFoldersList
      # since the Folders.buildFoldersList does not call anything leading to Folders.selectFolder
      # which sets @lj.app.current_folder like topics did in Topics.selectTopic upon a new jot
      # submission, which would set @lj.app.current_topic.

      if organize_dom
        @sortTopicsList()
        @selectFirstTopic()

    else
      @lj.app.current_topic = undefined
      @showNewTopicForm()

    if organize_dom
      @lj.jots.buildJotsList()

    @initNewTopicListeners()

  insertTopicElem: (topic, append = true) =>
    build_html = "<li data-topic='#{topic.id}' data-editing='false'>
                    <span class='title'>#{topic.title}</span>
                    <div class='input-edit-wrap'>
                      <input type='text' class='input-edit' />
                    </div>"
    if topic.has_manage_permissions
      build_html += "<i class='fa fa-pencil edit' data-edit title='Edit topic' />
                    <i class='fa fa-trash delete' data-delete title='Delete topic' />"
    
    build_html += "</li>"

    if append
      @topics_list.append build_html
    else
      @new_topic_form_wrap.after build_html

  sortTopicsList: (sort_dom=true) => #optimize this
    offset_top = 0

    if @new_topic_form_wrap.is(':visible') && @new_topic_form_wrap.attr('data-hidden') == 'false'
      offset_top += @new_topic_form_wrap.outerHeight()

    $.each @lj.app.topics, (index, topic) =>
      # data-hidden is used on the new-topic li while it is being hidden but not quite !.is(:visible) yet
      topic_elem = @topics_list.find("li[data-topic='#{topic.id}']")

      if $(topic_elem).is(':visible') && $(topic_elem).attr('data-hidden') != 'true'
        $(topic_elem).css('top', offset_top).attr('data-sort', offset_top)
        height = $(topic_elem).outerHeight()
        offset_top += height

    if sort_dom
      setTimeout(() =>
        topic_elems = @lj.topics.topics_list.children('li')
        topic_elems.detach().sort (a, b) =>
            return parseInt($(a).attr('data-sort')) - parseInt($(b).attr('data-sort'))

        @lj.topics.topics_list.append(topic_elems)
      , 250)


  initTopicBinds: (topic_id) =>
    @topics_list.find("li:not(.new-topic-form-wrap)[data-topic='#{topic_id}']").click (e) =>
      @selectTopic($(e.currentTarget).data('topic'))

    @topics_list.find("li[data-topic='#{topic_id}'] [data-edit]").click (e) =>
      @editTopic(topic_id)
      return false

    @topics_list.find("li[data-topic='#{topic_id}'] .input-edit").click (e) =>
      return false

    @topics_list.find("li[data-topic='#{topic_id}'] [data-delete]").click (e) =>
      @deleteTopicPrompt e.currentTarget

  selectTopic: (topic_id) =>
    if topic_id == @lj.app.current_topic
      return
      
    $("li[data-topic='#{@lj.app.current_topic}']").removeClass('current')
    elem = $("li[data-topic='#{topic_id}']")
    @lj.app.current_topic = topic_id
    elem.addClass('current')

    @lj.jots.buildJotsList()

  editTopic: (id) =>
    elem = $("li[data-topic='#{id}']")
    input = elem.find('input.input-edit')
    title = elem.find('.title')
    topic_object = @lj.app.topics.filter((topic) => topic.id == id)[0]

    if !topic_object.has_manage_permissions
      new HoverNotice(@lj, 'You do not have permission to modify this topic.', 'error')
      return

    input.val(window.unescapeHtml(title.html()))
    elem.attr('data-editing', 'true')
    input.focus()

    submitted_edit = false

    input.blur (e) =>
      finishEditing()

    input.keydown (e) =>
      if e.keyCode == @lj.key_controls.key_codes.enter
        e.preventDefault()
        finishEditing()

    finishEditing = =>
      if !submitted_edit
        submitted_edit = true
        filtered_input = window.escapeHtml(input.val())
        topic_object.title = filtered_input
        elem.attr('data-editing', 'false')
        title.html(filtered_input)
        @topics_wrapper.focus()

        $.ajax(
          type: 'PATCH'
          url: "/topics/#{id}"
          data: "title=#{encodeURIComponent(filtered_input)}"

          success: (data) =>
            console.log data

          error: (data) =>
            console.log data
        )

  deleteTopicPrompt: (target) =>
    id = if typeof target != 'undefined' then id = $(target).closest('li').data('topic') else id = $("li[data-keyed-over='true']").data('topic')
    topic_object = @lj.app.topics.filter((topic) => topic.id == id)[0]

    if !topic_object.has_manage_permissions
      new HoverNotice(@lj, 'You do not have permission to delete this topic.', 'error')
      return

    $('#delete-topic-modal').foundation 'reveal', 'open'
    $('#delete-topic-modal').html($('#delete-topic-modal-template').html())

    $('#delete-topic-modal .cancel').click =>
      @cancelDeleteTopic()

    $('#delete-topic-modal .confirm').click =>
      @confirmDeleteTopic id

  confirmDeleteTopic: (id) =>
    $('#delete-topic-modal').foundation 'reveal', 'close'
    @topics_wrapper.focus()

    setTimeout(() =>
      @deleteTopic id
    , 250)

  cancelDeleteTopic: =>
    $('#delete-topic-modal').attr('data-topic-id', '').foundation 'reveal', 'close'
    @topics_wrapper.focus()


  deleteTopic: (id) =>
    elem = $("li[data-topic='#{id}']")
    elem.attr('data-deleting', 'true')

    $.ajax(
      type: 'POST'
      url: "/topics/#{id}"
      data: {'_method': 'delete'}

      success: (data) =>
        new HoverNotice(@lj, data.message, 'success')
        vanish()

      error: (data) =>
        elem.attr('data-deleting', false)
        unless typeof data.responseJSON.error == 'undefined'
          new HoverNotice(@lj, data.responseJSON.error, 'error')
        else
          new HoverNotice(@lj, 'Could not delete topic.', 'error')
    )

    vanish = =>
      elem.attr('data-deleted', 'true')

      setTimeout(() =>
        topic_key = null
        $.each @lj.app.topics, (index, topic) =>
          if topic.id == id
            topic_key = index
            return false

        @lj.app.topics.remove(topic_key)
        elem.remove()
        @sortTopicsList false

        if @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder).length > 0
          @selectFirstTopic()
        else
          # deleted last topic
          @lj.app.current_topic = null
          @lj.jots.updateHeading()
          @lj.jots.clearJotsList()
          @newTopic()

      , 350)

  selectFirstTopic: =>
    next_topic_elem = @topics_list.find('li:not(.new-topic-form-wrap)')[0]
    @selectTopic($(next_topic_elem).data('topic')) 

  initNewTopicListeners: =>
    $('button.new-topic-button').mousedown (e) =>
      e.preventDefault()

      unless @new_topic_form_wrap.is(':visible')
        @newTopic()

      @new_topic_title.focus() # dont like how there are two #topic_titles (from template)

    @new_topic_title.blur (e) =>
      topics_count = @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder).length
      topic_title_length = @new_topic_title.val().trim().length
      
      if topics_count > 0 && topic_title_length == 0
        @hideNewTopicForm()

    $('form#new_topic').submit (e) =>
      e.preventDefault()
      @submitNewTopic()

  newTopic: (focus_title=true) =>
    @showNewTopicForm()
    @sortTopicsList false

    if focus_title
      @new_topic_title.focus()

  submitNewTopic: =>
    @lj.key_controls.clearKeyedOverData()
    topic_title = @new_topic_title
    filtered_content = window.escapeHtml(topic_title.val())

    unless filtered_content.trim().length == 0
      @lj.jots.new_jot_content.focus()
      topic_title.attr 'disabled', true

      $.ajax(
        type: 'POST'
        url: '/topics'
        data: "title=#{encodeURIComponent(filtered_content)}&folder_id=#{@lj.app.current_folder}"
        success: (data) =>
          @lj.jots.endSearchState()
          @hideNewTopicForm()

          console.log data

          @pushTopicIntoData data.topic

          if typeof @lj.app.current_folder == 'undefined' && typeof data.auto_folder != 'undefined'
            @lj.folders.hideNewFolderForm()
            @lj.folders.pushFolderIntoData data.auto_folder

          topic_title.attr 'disabled', false

        error: (data) =>
          console.log data
        )

    else
      @hideNewTopicForm

  pushTopicIntoData: (topic) =>
    if @lj.app.topics.length == 0
      @lj.app.topics.push topic
    else
      @lj.app.topics.unshift topic

    @insertTopicElem topic, false
    @sortTopicsList()
    @selectTopic topic.id
    @initTopicBinds topic.id

  showNewTopicForm: =>
    folder_object = @lj.app.folders.filter((folder) => folder.id == @lj.app.current_folder)[0]
    if @lj.app.currentFolder && !folder_object.has_manage_permissions
      new HoverNotice(@lj, 'You do not have permission to create topics within this folder.', 'error')
      @lj.key_controls.keyToCurrentFolder()
      return

    @new_topic_form_wrap.show().attr('data-hidden', 'false')

  hideNewTopicForm: =>
    @new_topic_form_wrap.attr('data-hidden', 'true').css('opacity', 0)
    @sortTopicsList()

    setTimeout(() =>
      @new_topic_form_wrap.hide().css({
        opacity: 1
      })

      @new_topic_title.val('')
      @lj.key_controls.clearKeyedOverData()
    , 250)

  moveCurrentTopicToTop: =>
    topic_key_to_move = null
    topic_object_to_move = null

    # find topic to move
    $.each @lj.app.topics, (index, topic) =>
      if topic.id == @lj.app.current_topic
        topic_key_to_move = index
        topic_object_to_move = topic
        return false

    # move topic being written in to top of list
    temp_list = $.extend([], @lj.app.topics)
    for i in [0...topic_key_to_move]
      temp_list[i+1] = @lj.app.topics[i]

    @lj.app.topics = $.extend([], temp_list)
    @lj.app.topics[0] = topic_object_to_move
    @lj.topics.sortTopicsList()

  removeTopicsInFolderFromData: (folder_id) =>
    # this function removes the topics of a specific folder from the JS data
    topic_keys = []

    $.each @lj.app.topics.filter((topic) => topic.folder_id == folder_id), (key, topic) =>
      @lj.jots.removeJotsInTopicFromData topic.id
      topic_keys.push key

    $.each topic_keys.reverse(), (array_key, topic_key) =>
      @lj.app.topics.remove topic_key