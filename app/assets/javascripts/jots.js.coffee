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
      data: "content=#{content}&folder_id=#{@lj.app.current_folder}&topic_id=#{@lj.app.current_topic}"
      success: (data) =>
        console.log data
        @lj.app.jots.push data.jot

      error: (data) =>
        console.log data
    )

    @lj.folders.moveCurrentFolderToTop()
    @lj.topics.moveCurrentTopicToTop()

    # reset new jot form
    @clearJotEntryTemplate()
    @new_jot_content.val('')

  scrollJotsToBottom: =>
    @jots_wrapper.scrollTop @jots_wrapper[0].scrollHeight

  clearJotEntryTemplate: =>
    @jot_entry_template.find('li').html('')
