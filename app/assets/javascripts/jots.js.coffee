#= require lightjot

class window.Jots extends LightJot
  constructor: (@lj) ->
    @lj = @lj
    console.log @lj
    @initVars()
    @initJotFormListeners()

  initVars: =>
    @new_jot_form = $('form#new_jot')
    @new_jot_content = @new_jot_form.find('textarea#jot_content')
    @jots_wrapper = $('#jots-wrapper')
    @jots_list = @jots_wrapper.find('ul#jots-list')
    @jot_entry_template = $('#jot-entry-template')

  buildJotsList: =>
    @jots_list.html('')
    console.log @app
    $.each @lj.app.jots, (index, jot) =>
      if jot.topic_id == @lj.app.current_topic
        @jots_list.append("<li>#{jot.content}</li>")

    @scrollJotsToBottom()

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
        @app.jots.push data.jot

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
