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
    @jot_temp_entry_template = $('#jot-temp-entry-template')
    @jots_empty_message_elem = @jots_wrapper.find('.empty-message')
    @jots_loading_icon = @jots_wrapper.find('i.loading')

  buildJotsList: =>
    console.log 'eey'
    @jots_list.html('')
    @jots_loading_icon.fadeOut()

    if @lj.app.jots.filter((jot) => jot.topic_id == @lj.app.current_topic).length > 0
      @jots_empty_message_elem.hide()

      i = 0
      $.each @lj.app.jots, (index, jot) =>
        if jot.topic_id == @lj.app.current_topic
          @insertJotElem(jot)

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
    if content.trim().length > 0
      key = @randomKey()
      @insertTempJotElem(content, key)
      @jots_empty_message_elem.hide()
      @scrollJotsToBottom()

      $.ajax(
        type: 'POST'
        url: @new_jot_form.attr('action')
        data: "content=#{content}&folder_id=#{@lj.app.current_folder}&topic_id=#{@lj.app.current_topic}"
        success: (data) =>
          console.log data
          @lj.app.jots.push data.jot
          @integrateTempJot(data.jot, key)

          if typeof @lj.app.current_folder == 'undefined' && typeof data.auto_folder != 'undefined'
            @lj.folders.hideNewFolderForm()
            @lj.folders.pushFolderIntoData data.auto_folder

          if typeof @lj.app.current_topic == 'undefined' && typeof data.auto_topic != 'undefined'
            @lj.topics.hideNewTopicForm()
            @lj.topics.pushTopicIntoData data.auto_topic

        error: (data) =>
          console.log data
      )

      if @lj.app.folders.length > 1
        @lj.folders.moveCurrentFolderToTop()

      if @lj.app.topics.length > 1
        @lj.topics.moveCurrentTopicToTop()

      # reset new jot form
      @clearJotEntryTemplate()
      @new_jot_content.val('')

  insertTempJotElem: (content, key) =>
    content = @new_jot_content.val()
    @jot_temp_entry_template.find('li').attr('id', key).append("<div class='content'>#{content}</div>")
    build_entry = @jot_temp_entry_template.html()

    @jots_list.append(build_entry)

  integrateTempJot: (jot, key) =>
    elem = @jots_list.find("##{key}")
    elem.removeClass('temp').attr('data-jot', jot.id)

    to_insert = "<i class='fa fa-tag highlight' />
                <i class='fa fa-trash delete' />
                <div class='input-edit-wrap'>
                  <input type='text' class='input-edit' />
                </div>"

    elem.append(to_insert)

    @initJotBinds jot.id

  insertJotElem: (jot) =>
    highlighted_class = if jot.is_highlighted then 'highlighted' else ''
    @jots_list.append("<li data-jot='#{jot.id}' class='#{highlighted_class}'>
                        <i class='fa fa-tag highlight' />
                        <i class='fa fa-trash delete' />
                        <div class='content'>
                          #{jot.content}
                        </div>
                        <div class='input-edit-wrap'>
                          <input type='text' class='input-edit' />
                        </div>
                      </li>")

    @initJotBinds jot.id

  scrollJotsToBottom: =>
    @jots_wrapper.scrollTop @jots_wrapper[0].scrollHeight

  clearJotEntryTemplate: =>
    @jot_temp_entry_template.find('li').html('')

  randomKey: =>
    build_key = ""
    possibilities = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890"

    for i in [0..50]
      build_key += possibilities.charAt(Math.floor(Math.random() * possibilities.length))

    return build_key;

  initJotBinds: (jot_id) =>
    @jots_list.find("li[data-jot='#{jot_id}']").click (e) =>
      @editJot(jot_id)
      return false

    @jots_list.find("li[data-jot='#{jot_id}'] i.highlight").click (e) =>
      e.stopPropagation()
      @highlightJot jot_id

    @jots_list.find("li[data-jot='#{jot_id}'] i.delete").click (e) =>
      e.stopPropagation()
      @deleteJot jot_id

  highlightJot: (id) =>
    elem = $("li[data-jot='#{id}']")
    is_highlighted = elem.hasClass('highlighted') ? true : false
    jot_object = @lj.app.jots.filter((jot) => jot.id == parseInt(id))[0]

    unless is_highlighted
      jot_object.is_highlighted = true
      elem.addClass('highlighted')

    else
      jot_object.is_highlighted = false
      elem.removeClass('highlighted')

    is_highlighted = !is_highlighted
    $.ajax(
      type: 'PATCH'
      url: "/jots/#{id}"
      data: "is_highlighted=#{is_highlighted}"

      success: (data) =>
        console.log data

      error: (data) =>
        console.log data
    )


  editJot: (id) =>
    elem = $("li[data-jot='#{id}']")
    input = elem.find('input.input-edit')
    content_elem = elem.find('.content')
    raw_content = @lj.app.jots.filter((jot) => jot.id == id)[0].content

    input.val(raw_content)
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
        content_elem.html(input.val())

        @lj.jots.new_jot_content.focus()

        # only update folder/topic order & send server request if the user
        # changed the content field of the jot
        if input.val() != raw_content
          @lj.folders.moveCurrentFolderToTop()
          @lj.topics.moveCurrentTopicToTop()

          $.ajax(
            type: 'PATCH'
            url: "/jots/#{id}"
            data: "content=#{input.val()}"

            success: (data) =>
              console.log data

            error: (data) =>
              console.log data
          )

  deleteJot: (id) =>
    elem = $("li[data-jot='#{id}']")
    elem.attr('data-deleting', 'true')

    $.ajax(
      type: 'POST'
      url: "/jots/#{id}"
      data: {'_method': 'delete'}

      success: (data) =>
        console.log data

      error: (data) =>
        console.log data
    )

    setTimeout(() =>
      jot_key = null
      $.each @lj.app.jots, (index, jot) =>
        if jot.id == id
          jot_key = index
          return false

      @lj.app.jots.remove(jot_key)
      elem.remove()

      @checkIfJotsEmpty()

    , 350)

  checkIfJotsEmpty: =>
    if @lj.app.jots.filter((jot) => jot.topic_id == @lj.app.current_topic).length == 0
      @jots_empty_message_elem.show()