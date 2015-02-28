#= require lightjot

class window.Jots extends LightJot
  constructor: (@lj) ->
    @initVars()
    @initJotFormListeners()

  initVars: =>
    @new_jot_form = $('form#new_jot')
    @new_jot_content = @new_jot_form.find('textarea#jot_content')
    @jots_wrapper = $('#jots-wrapper')
    @jots_list = @jots_wrapper.find('ul#jots-list')
    @jot_entry_template = $('#jot-entry-template')
    @jots_empty_message_elem = @jots_wrapper.find('.empty-message')
    @jots_loading_icon = @jots_wrapper.find('i.loading')

  buildJotsList: =>
    @jots_list.html('')
    @jots_loading_icon.fadeOut()

    if @lj.app.jots.filter((jot) => jot.topic_id == @lj.app.current_topic).length > 0
      @jots_empty_message_elem.hide()

      i = 0
      $.each @lj.app.jots, (index, jot) =>
        if jot.topic_id == @lj.app.current_topic
          @jots_list.append("<li>#{jot.content}</li>")


    else
      @jots_empty_message_elem.show()

    @scrollJotsToBottom()

  initJotFormListeners: =>
    @new_jot_form.submit (e) =>
      e.preventDefault()
      @submitNewJot()

    @new_jot_content.keydown (e) =>
      if e.keyCode == @lj.key_codes.enter && !e.shiftKey # enter key w/o shift key means submission
        e.preventDefault()
        @new_jot_form.submit()

  submitNewJot: =>
    content = @new_jot_content.val()
    @jot_entry_template.find('li').append(content)
    build_entry = @jot_entry_template.html()

    @jots_list.append(build_entry)
    @jots_empty_message_elem.hide()
    @scrollJotsToBottom()

    $.ajax(
      type: 'POST'
      url: @new_jot_form.attr('action')
      data: "content=#{content}&topic_id=#{@lj.app.current_topic}"
      success: (data) =>
        console.log data
        @lj.app.jots.push data.jot

      error: (data) =>
        console.log data
    )

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

    console.log @lj.app.topics
    console.log 'to'
    @lj.app.topics = $.extend([], temp_list)
    console.log @lj.app.topics


    @lj.app.topics[0] = topic_object_to_move
    @lj.topics.sortTopicsList()

    # reset new jot form
    @clearJotEntryTemplate()
    @new_jot_content.val('')

  scrollJotsToBottom: =>
    @jots_wrapper.scrollTop @jots_wrapper[0].scrollHeight

  clearJotEntryTemplate: =>
    @jot_entry_template.find('li').html('')
