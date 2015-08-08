#= require litejot

class window.Jots extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @initJotFormListeners()
    @initScrollListeners()

  initVars: =>
    @new_jot_form = $('form#new_jot')
    @new_jot_content = @new_jot_form.find('textarea#jot_content')
    @jots_heading = $('h2#jots-heading')
    @jots_heading_text = $('h2#jots-heading .heading-text')
    @jots_wrapper = $('#jots-wrapper')
    @jots_list = @jots_wrapper.find('ul#jots-list')
    @jot_temp_entry_template = $('#jot-temp-entry-template')
    @jots_empty_message_elem = @jots_wrapper.find('.empty-message')
    @jots_loading_icon = @jots_wrapper.find('i.loading')
    @edit_overlay = $('#edit-overlay')
    @edit_notice = $('#edit-notice')
    @jots_in_search_results = [] # array of jot id's that will be checked in @insertJotElem()

  clearJotsList: =>
    @jots_list.html('')
    @jots_empty_message_elem.show()

  updateHeading: =>
    if !@lj.app.current_topic
      @jots_heading_text.html('Jots')
    else
      topic_title = @lj.app.topics.filter((topic) => topic.id == @lj.app.current_topic)[0].title
      @jots_heading_text.html("Jots: #{topic_title}")

  buildJotsList: =>
    @clearJotsList()
    @updateHeading()
    @jots_loading_icon.fadeOut()

    if @lj.app.jots.filter((jot) => jot.topic_id == @lj.app.current_topic).length > 0
      @jots_empty_message_elem.hide()

      i = 0
      $.each @lj.app.jots, (index, jot) =>
        if jot.topic_id == @lj.app.current_topic
          @insertJotElem(jot)


      topic_title = @lj.app.topics.filter((topic) => topic.id == @lj.app.current_topic)[0].title
      @checkScrollPosition()

    @scrollJotsToBottom()

  initJotFormListeners: =>
    @new_jot_form.submit (e) =>
      e.preventDefault()
      if @new_jot_content.attr('data-editing') != 'true'
        @submitNewJot()

    @new_jot_content.keydown (e) =>
      if e.keyCode == @lj.key_controls.key_codes.enter && !e.shiftKey # enter key w/o shift key means submission
        e.preventDefault()
        @new_jot_form.submit()

  initScrollListeners: =>
    @jots_wrapper.scroll () =>
      @checkScrollPosition()

  checkScrollPosition: =>
    if @jots_wrapper.scrollTop() == 0
      @jots_heading.removeClass('is-scrolled-from-top')
    else
      @jots_heading.addClass('is-scrolled-from-top')

    if @jots_wrapper.scrollTop() + @jots_wrapper.height() == @jots_wrapper[0].scrollHeight
      @new_jot_content.removeClass('is-scrolled-from-bottom')
    else
      @new_jot_content.addClass('is-scrolled-from-bottom')

  submitNewJot: =>
    content = window.escapeHtml(@new_jot_content.val())

    if content.trim().length > 0
      @lj.search.endSearchState false

      key = @randomKey()
      @insertTempJotElem content, key
      @jots_empty_message_elem.hide()
      @scrollJotsToBottom()

      $.ajax(
        type: 'POST'
        url: @new_jot_form.attr('action')
        data: "content=#{encodeURIComponent(content)}&folder_id=#{@lj.app.current_folder}&topic_id=#{@lj.app.current_topic}"
        success: (data) =>
          @lj.app.jots.push data.jot
          @integrateTempJot data.jot, key

          if (typeof @lj.app.current_folder == 'undefined' || !@lj.app.current_folder) && typeof data.auto_folder != 'undefined'
            @lj.folders.hideNewFolderForm()
            @lj.folders.pushFolderIntoData data.auto_folder

          if (typeof @lj.app.current_topic == 'undefined' || !@lj.app.current_topic) && typeof data.auto_topic != 'undefined'
            @lj.topics.hideNewTopicForm()
            @lj.topics.pushTopicIntoData data.auto_topic

          # inform user of an auto generated folder or topic
          if typeof data.auto_folder != 'undefined' && typeof data.auto_topic != 'undefined'
            new HoverNotice(@lj, 'Folder and topic auto-generated.', 'success')
          if typeof data.auto_folder == 'undefined' && typeof data.auto_topic != 'undefined'
            new HoverNotice(@lj, 'Topic auto-generated.', 'success')

          # reset new jot form
          @new_jot_content.val('')

        error: (data) =>
          unless !data.responseJSON || typeof data.responseJSON.error == 'undefined'
            new HoverNotice(@lj, data.responseJSON.error, 'error')
          else
            new HoverNotice(@lj, 'Could not save jot. Please check internet connect or contact us.', 'error')
          @rollbackTempJot()
      )

      if @lj.app.folders.length > 1
        @lj.folders.moveCurrentFolderToTop()

      if @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder).length > 1
        @lj.topics.moveCurrentTopicToTop()

      @clearJotEntryTemplate()

  rollbackTempJot: =>
    @jots_list.find('li.temp').remove()

  insertTempJotElem: (content, key) =>
    content = content.replace /\n/g, '<br />'
    @jot_temp_entry_template.find('li')
    .attr('id', key).append("<div class='content'>#{content}</div>")
    .attr("data-before-content", "\uf141")
    .attr("title", "submitting jot...")

    build_entry = @jot_temp_entry_template.html()

    @jots_list.append build_entry

  integrateTempJot: (jot, key) =>
    elem = @jots_list.find("##{key}")
    elem.removeClass('temp').attr('data-jot', jot.id)

    to_insert = "<i class='fa fa-edit edit' title='Edit jot' />
                <i class='fa fa-trash delete' title='Delete jot' />
                <div class='input-edit-wrap'>
                  <input type='text' class='input-edit' />
                </div>"

    elem.append to_insert
    @setTimestamp jot
    @initJotBinds jot.id

  insertJotElem: (jot) =>
    flagged_class = if jot.is_flagged then 'flagged' else ''
    jot_content = jot.content.replace /\n/g, '<br />'
    highlighted_class = if (jot.id in @jots_in_search_results) then 'highlighted' else ''

    build_html = "<li data-jot='#{jot.id}' class='#{flagged_class} #{highlighted_class}'>"
    
    if jot.has_manage_permissions
      build_html += "<i class='fa fa-edit edit' title='Edit jot' />
                    <i class='fa fa-trash delete' title='Delete jot' />
                    <div class='input-edit-wrap'>
                      <input type='text' class='input-edit' />
                    </div>"

    build_html += "<div class='content'>
                    #{jot_content}
                  </div>
                </li>"
    @jots_list.append(build_html)
    @setTimestamp jot
    @initJotBinds jot.id

  setTimestamp: (jot) =>
    elem = @jots_list.find("[data-jot='#{jot.id}']")[0]
    data_before_content = jot.created_at_short
    if $(elem).hasClass('flagged')
      data_before_content = "\uf024 "+ data_before_content

    $(elem).attr("data-before-content", data_before_content)
    .attr("title", "created on #{jot.created_at_long}\nlast updated on #{jot.updated_at}")

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
      e.stopPropagation()
      @flagJot jot_id

    @jots_list.find("li[data-jot='#{jot_id}'] i.edit").click (e) =>
      @editJot(jot_id)
      return false

    @jots_list.find("li[data-jot='#{jot_id}'] i.delete").click (e) =>
      e.stopPropagation()
      @deleteJot jot_id

  flagJot: (id) =>
    elem = $("li[data-jot='#{id}']")
    is_flagged = elem.hasClass('flagged') ? true : false
    jot_object = @lj.app.jots.filter((jot) => jot.id == id)[0]

    if !jot_object.has_manage_permissions
      new HoverNotice(@lj, 'You do not have permission to flag this jot.', 'error')
      return

    @toggleFlagClientSide(jot_object)

    @setTimestamp (jot_object)

    is_flagged = !is_flagged
    $.ajax(
      type: 'PATCH'
      url: "/jots/#{id}"
      data: "is_flagged=#{is_flagged}"

      success: (data) =>
        # all actions carried out on correct assumption that action would pass

      error: (data) =>
        @toggleFlagClientSide(jot_object)
        unless !data.responseJSON || typeof data.responseJSON.error == 'undefined'
          new HoverNotice(@lj, data.responseJSON.error, 'error')
        else
          new HoverNotice(@lj, 'Could not flag jot.', 'error')
    )

  toggleFlagClientSide: (jot) =>
    elem = $("li[data-jot='#{jot.id}']")
    is_flagged = elem.hasClass('flagged') ? true : false

    unless is_flagged
      jot.is_flagged = true
      elem.addClass('flagged')

    else
      jot.is_flagged = false
      elem.removeClass('flagged')


  editJot: (id) =>
    elem = $("li[data-jot='#{id}']")
    content_elem = elem.find('.content')
    jot_object = @lj.app.jots.filter((jot) => jot.id == id)[0]

    if !jot_object.has_manage_permissions
      new HoverNotice(@lj, 'You do not have permission to edit this jot.', 'error')
      return

    raw_content = window.unescapeHtml(jot_object.content)
    submitted_edit = false

    @edit_overlay.show()
    @edit_overlay.find('#edit-notice').css(
      bottom: (@new_jot_content.height() - @edit_notice.height()/2)
      left: @new_jot_content.offset().left - @edit_notice.width()
    )
    elem.attr('data-editing', 'true')
    @new_jot_content.attr('data-editing', 'true').val(raw_content).focus()

    @new_jot_form.submit =>
      if @new_jot_content.attr('data-editing') == 'true'
        finishEditing()

    @new_jot_content.blur =>
      finishEditing()

    finishEditing = =>
      if !submitted_edit
        submitted_edit = true
        updated_content = window.escapeHtml(@new_jot_content.val())
        jot_object.content = updated_content #doing this here in case they switch topics before ajax complete
        
        @edit_overlay.hide()
        @new_jot_content.val('').attr('data-editing', 'false')
        elem.attr('data-editing', 'false')
        content_elem.html(updated_content.replace(/\n/g, '<br />'))
        
        # return keyboard controls
        @jots_wrapper.focus()
        elem.attr('data-keyed-over', 'true')

        # only update folder/topic order & send server request if the user
        # changed the content field of the jot
        if updated_content != raw_content
          @lj.folders.moveCurrentFolderToTop()
          @lj.topics.moveCurrentTopicToTop()

          $.ajax(
            type: 'PATCH'
            url: "/jots/#{id}"
            data: "content=#{encodeURIComponent(updated_content)}"

            success: (data) =>
              jot_object.content = data.content
              jot_object.created_at_long = data.created_at_long
              jot_object.created_at_short = data.created_at_short
              jot_object.updated_at = data.updated_at
              @setTimestamp jot_object

              new HoverNotice(@lj, 'Jot updated.', 'success')

            error: (data) =>
              unless !data.responseJSON || typeof data.responseJSON.error == 'undefined'
                new HoverNotice(@lj, data.responseJSON.error, 'error')
              else
                new HoverNotice(@lj, 'Could not update jot.', 'error')
          )

  deleteJot: (id) =>
    jot_object = @lj.app.jots.filter((jot) => jot.id == id)[0]
    if !jot_object.has_manage_permissions
      new HoverNotice(@lj, 'You do not have permission to delete this jot.', 'error')
      return

    elem = $("li[data-jot='#{id}']")
    elem.attr('data-deleting', 'true')

    $.ajax(
      type: 'POST'
      url: "/jots/#{id}"
      data: {'_method': 'delete'}

      success: (data) =>
        new HoverNotice(@lj, data.message, 'success')
        vanish()

      error: (data) =>
        elem.attr('data-deleting', false)
        unless typeof data.responseJSON.error == 'undefined'
          new HoverNotice(@lj, data.responseJSON.error, 'error')
        else
          new HoverNotice(@lj, 'Could not delete jot.', 'error')

    )

    vanish = =>
      setTimeout(() =>
        elem.attr('data-deleted', 'true')
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
      @positionEmptyMessage()
      return true
    else
      return false

  positionEmptyMessage: =>
    empty_message_width = @jots_empty_message_elem.width()
    empty_message_height = @jots_empty_message_elem.height()

    pos_left = (@jots_wrapper.width() - empty_message_width) / 2
    pos_top = @jots_wrapper.height() / 2 - empty_message_height

    @jots_empty_message_elem.css(
      'top': pos_top
      'left': pos_left
    )

  removeJotsInTopicFromData: (topic_id) =>
    # this function removes the jots of a specific topic from the JS data
    jot_keys = []

    $.each @lj.app.jots.filter((jot) => jot.topic_id == topic_id).reverse(), (key, jot) =>
      jot_keys.push key

    $.each jot_keys.reverse(), (array_key, topic_key) =>
      @lj.app.jots.remove topic_key
