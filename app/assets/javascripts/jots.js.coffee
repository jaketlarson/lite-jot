#= require litejot

class window.Jots extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @initJotFormListeners()
    @initScrollListeners()
    @newJotWrapActive()
    @cleanCheckListTab()

  initVars: =>
    @new_jot_wrap = $('#new-jot-wrap')
    @new_jot_toolbar = $('#new-jot-wrap #jot-toolbar')
    @new_jot_heading = @new_jot_wrap.find('input#jot_heading')
    @new_jot_content = @new_jot_wrap.find('textarea#jot_content')
    @new_jot_checklist_tab = @new_jot_wrap.find('.tab-wrap#jot-checklist-tab')
    @new_jot_wrap_clicking = false
    @new_jot_current_tab = 'standard'
    @new_jot_break_option_wrap = @new_jot_toolbar.find('#break-option')
    @new_jot_break_value = false

    @jots_heading = $('h2#jots-heading')
    @jots_heading_text = $('h2#jots-heading .heading-text')
    @jots_wrapper = $('#jots-wrapper')
    @jots_list = @jots_wrapper.find('ul#jots-list')
    @jot_temp_entry_template = $('#jot-temp-entry-template')
    @jots_empty_message_elem = @jots_wrapper.find('.empty-message')
    @jots_loading_icon = @jots_wrapper.find('i.loading')
    @edit_overlay = $('#edit-overlay')
    @edit_notice = $('#edit-notice')
    @currently_editing_id = null
    @jots_in_search_results = [] # array of jot id's that will be checked in @insertJotElem()
    
    # ignore_this_key_down is used when moving from the last jot to new jot area
    # It's used because the keydown event from key controls
    # doubles up with keyup event for the checklist item bind
    # This is a quick fix
    @ignore_this_key_down = false

  clearJotsList: =>
    @jots_list.html('')
    @jots_empty_message_elem.show()

  updateHeading: =>
    if !@lj.app.current_topic
      @jots_heading_text.html('Jots')
    else
      topic_title = @lj.app.topics.filter((topic) => topic.id == @lj.app.current_topic)[0].title
      @jots_heading_text.html("Jots: #{topic_title}")

    if @lj.search.current_terms.length > 0
      @jots_heading_text.prepend("<span class='search-result-info-test'>Searching </span>")

  buildJotsList: =>
    @clearJotsList()
    @updateHeading()
    @jots_loading_icon.fadeOut()

    if @lj.app.jots.filter((jot) => jot.topic_id == @lj.app.current_topic).length > 0
      @jots_empty_message_elem.hide()

      i = 0

      # if searching, limit scope to keywords
      if @lj.search.current_terms.length > 0
        jots_scope = @lj.app.jots.filter((jot) => jot.content.toLowerCase().indexOf(@lj.search.current_terms.toLowerCase()) > -1)
      else
        jots_scope = @lj.app.jots

      $.each jots_scope, (index, jot) =>
        if jot.topic_id == @lj.app.current_topic
          # if searching: checklist jots are special, so they need an extra loop
          if @lj.search.current_terms.length > 0 & jot.jot_type == 'checklist'
            items = JSON.parse jot.content
            items_matched = 0
            $.each items, (index, item) =>
              if item.value.toLowerCase().indexOf(@lj.search.current_terms.toLowerCase()) > -1
                items_matched++
            if items_matched == 0
              return

          @insertJotElem jot

      # if searching, limit jots in local storage (emergency mode) 
      all_em_jots = @lj.emergency_mode.getStoredJotsObject()

      if @lj.search.current_terms.length > 0
        em_jots_scope = all_em_jots.filter((jot) => jot.content.toLowerCase().indexOf(@lj.search.current_terms.toLowerCase()) > -1)
      else
        em_jots_scope = all_em_jots

      $.each em_jots_scope, (index, jot) =>
        if jot.topic_id == @lj.app.current_topic
          @insertTempJotElem jot.content, jot.temp_key, jot.jot_type, jot.break

      topic_title = @lj.app.topics.filter((topic) => topic.id == @lj.app.current_topic)[0].title
      @checkScrollPosition()

    @scrollJotsToBottom()

  newJotSubmit: =>
    if @new_jot_content.attr('data-editing') != 'true'
      @submitNewJot()

  initJotFormListeners: =>
    @new_jot_content.keydown (e) =>
      if e.keyCode == @lj.key_controls.key_codes.enter && !e.shiftKey # enter key w/o shift key means submission
        e.preventDefault()
        if @currently_editing_id # if this is set, we're editing
          @finishEditing()
        else
          @newJotSubmit()

    @new_jot_heading.keydown (e) =>
      if e.keyCode == @lj.key_controls.key_codes.enter
        e.preventDefault()
        if @currently_editing_id # if this is set, we're editing
          @finishEditing()
        else
          @newJotSubmit()

    @new_jot_content.blur (e) =>
      @newJotWrapInactive()

    @new_jot_heading.blur (e) =>
      @newJotWrapInactive()

    @new_jot_content.focus (e) =>
      @newJotWrapActive()

    @new_jot_heading.focus (e) =>
      @newJotWrapActive()

    @new_jot_wrap.find('li.tab').click (e) =>
      @switchTab $(e.currentTarget).data('tab')
      @determineFocusForNewJot()

    @new_jot_break_option_wrap.click =>
      @toggleJotBreak()

    @edit_overlay.click =>
      @finishEditing()

  determineFocusForNewJot: =>
    if @new_jot_current_tab == 'standard'
      @new_jot_content.focus()
    else if @new_jot_current_tab == 'heading'
      @new_jot_heading.focus()
    else if @new_jot_current_tab == 'checklist'
      @lj.key_controls.keyToLastNewJotListItem()

  newJotWrapActive: =>
    @new_jot_wrap.addClass('active')

  newJotWrapInactive: =>
    @new_jot_wrap.removeClass('active')

  switchTab: (tab) =>
    if tab == @new_jot_current_tab
      return

    # Value of current input should be carried over
    if @new_jot_current_tab == 'standard'
      carry_over_value = @new_jot_content.val()
    else if @new_jot_current_tab == 'heading'
      carry_over_value = @new_jot_heading.val()
    else if @new_jot_current_tab == 'checklist'
      carry_over_value = @parseCheckListToText @getJotContent()

    if tab == 'standard'
      @new_jot_content.val(carry_over_value)
    else if tab == 'heading'
      @new_jot_heading.val(carry_over_value.replace(/\n/g, ' '))
    else if tab == 'checklist'
      @cleanCheckListTab()
      @populateCheckList JSON.stringify(@parseTextToCheckList(@getJotContent()))

    @new_jot_current_tab = tab

    # Toggle jot break automatically
    # For instance, headings are probably better off being broken from top.
    if tab == 'standard'
      @jotBreakOff()
    else if tab == 'heading'
      @jotBreakOn()
    else if tab == 'checklist'
      @jotBreakOff()

    @new_jot_wrap.find('li.tab.active').removeClass('active')
    @new_jot_wrap.find('.tab-wrap.active').removeClass('active')

    @new_jot_wrap.find("li.tab[data-tab='#{tab}']").addClass('active')
    @new_jot_wrap.find(".tab-wrap[data-tab='#{tab}']").addClass('active')

    @lj.sizeUI()
    @scrollJotsToBottom()
    @new_jot_wrap.focus()

  toggleJotBreak: =>
    if @new_jot_break_value
      @jotBreakOff()
    else
      @jotBreakOn()

  jotBreakOn: =>
    @new_jot_break_value = true
    @new_jot_break_option_wrap.find('.not-checked').hide()
    @new_jot_break_option_wrap.find('.is-checked').css('display', 'inline-block')

  jotBreakOff: =>
    @new_jot_break_value = false
    @new_jot_break_option_wrap.find('.is-checked').hide()
    @new_jot_break_option_wrap.find('.not-checked').css('display', 'inline-block')

  getJotContent: =>
    if @new_jot_current_tab == 'heading'
      return @new_jot_heading.val()
    else if @new_jot_current_tab == 'standard'
      return @new_jot_content.val()
    else if @new_jot_current_tab == 'checklist'
      return JSON.stringify(@serializeNewJotCheckList())
    else
      return ""

  clearJotInputs: =>
    @new_jot_heading.val('')
    @new_jot_content.val('')
    @cleanCheckListTab()

  cleanCheckListTab: =>
    if @new_jot_checklist_tab.find('li:not(.template)').length > 0
      @new_jot_checklist_tab.find('li:not(.template)').remove()

    @addNewCheckListItem()
    if @lj.init_data_loaded
      @lj.sizeUI()

    if @new_jot_current_tab == 'checklist'
      @new_jot_checklist_tab.find('li:not(.template) input.checklist-value').focus()

  # addNewCheckListItem does some binding that would normally
  # be done in key_controls.js, but since they are created in JS
  # the binds were just added here.
  addNewCheckListItem: =>
    html = @new_jot_checklist_tab.find('li.template').html()
    id = "checklist-item-#{@randomKey()}"
    @new_jot_checklist_tab.find('ul.jot-checklist').append("<li id='#{id}'>#{html}</li>")
   
    elem = $("li##{id}")

    @initCheckListItemBinds elem
    @scrollJotsToBottom()

  initCheckListItemBinds: (elem) =>
    elem.keyup (e) =>
      this_checklist_value = elem.find('input.checklist-value').val()

      if e.keyCode == @lj.key_controls.key_codes.enter
        if @currently_editing_id
          @finishEditing()
        else
          @submitNewJot()
        return

      if e.keyCode == @lj.key_controls.key_codes.up
        @lj.key_controls.keyToNextNewJotListItemUp()
        return

      if e.keyCode == @lj.key_controls.key_codes.down
        if @ignore_this_key_down
          @ignore_this_key_down = false
        else
          @lj.key_controls.keyToNextNewJotListItemDown()
        return

      if e.keyCode == @lj.key_controls.key_codes.right
        if @ignore_this_key_down
          @ignore_this_key_down = false
        else if this_checklist_value.trim().length == 0
          @lj.search.focusSearchInput()
          console.log 'wow'
          return

      if this_checklist_value.trim().length > 0
        elem.find('input.checklist-value').attr 'data-blank', 'false'

        num_empty_checkboxes = @new_jot_checklist_tab.find("li:not(.template) input.checklist-value[data-blank='true']").length
        if num_empty_checkboxes == 0
          @addNewCheckListItem()
          @lj.sizeUI()
      else
        elem.find('input.checklist-value').attr 'data-blank', 'true'

        if e.keyCode == @lj.key_controls.key_codes.left
          if @ignore_this_key_down
            @ignore_this_key_down = false
          else
            @lj.key_controls.keyToCurrentTopic()

      @removeExcessiveBlankCheckListItems()

    elem.find('input.checklist-value').focus (e) =>
      @lj.key_controls.curr_pos = 'new_jot_checklist'
      @lj.key_controls.switchKeyboardShortcutsPane()
      $(e.currentTarget).attr('data-keyed-over', 'true')

    elem.find('input.checklist-value').blur (e) =>
      $(e.currentTarget).attr('data-keyed-over', 'false')
      @removeExcessiveBlankCheckListItems()
      @lj.key_controls.clearKeyboardShortcutsPane()

  removeExcessiveBlankCheckListItems: =>
    num = 0
    $.each @new_jot_checklist_tab.find('li:not(.template)'), (index, item) =>
      if $(item).find("input.checklist-value[data-blank='true']").length
        num++
      if num > 1
        $(item).remove()
      @lj.sizeUI()

  initScrollListeners: =>
    @jots_wrapper.scroll () =>
      @checkScrollPosition()

  checkScrollPosition: =>
    if @jots_wrapper.scrollTop() == 0
      @jots_heading.removeClass('is-scrolled-from-top')
    else
      @jots_heading.addClass('is-scrolled-from-top')

    buffer = 1 # seems to be buggy in Chrome, so just add 1 to the test
    if @jots_wrapper.scrollTop() + @jots_wrapper.outerHeight() + buffer >= @jots_wrapper[0].scrollHeight
      @new_jot_wrap.removeClass('is-scrolled-from-bottom')
    else
      @new_jot_wrap.addClass('is-scrolled-from-bottom')

  serializeNewJotCheckList: =>
    items = []
    $.each @new_jot_checklist_tab.find('li:not(.template)'), (index, item) =>
      is_checked = $(item).find("input[type='checkbox'].checklist-checkbox").is(':checked')
      value = $(item).find('input.checklist-value').val()

      if value.trim().length > 0
        item_hash =
          checked: is_checked
          value: value
        items.push item_hash

    return items

  parseCheckListToHTML: (items) =>
    items = JSON.parse(items)
    html = "<ul class='checklist-jot'>"
    $.each items, (index, item) =>
      toggled_text = if item.toggled_text then item.toggled_text else "Click to toggle checkbox."
      html += "<li class='checklist-item' title='#{toggled_text}'>"
      html += "<div class='checkbox-wrap'><input type='checkbox'#{if item.checked then "checked" else ""}></div>"
      html += "#{item.value}"
      html += "</li>"

    html += "</ul>"

    return html

  parseCheckListToText: (items) =>
    items = JSON.parse(items)
    text = ""
    $.each items, (index, item) =>
      text += "#{item.value}\n"

    return text

  parseTextToCheckList: (text) =>
    items = []
    if text.length > 0
      text_to_items = text.split('\n')
      items = []
      if text_to_items.length > 0
        $.each text_to_items, (index, value) =>
          if value.trim().length > 0
            item_hash =
              checked: false
              value: value
            items.push item_hash

    return items


  populateCheckList: (content) =>
    items = JSON.parse(content)
    template = @new_jot_checklist_tab.find('li.template')
    template_html = template.html()

    $.each items, (index, item) =>
      id = "checklist-item-#{randomKey()}"
      html = "<li id='#{id}'>#{template_html}</li>"
      @new_jot_checklist_tab.find('ul').append(html)

      elem = $("li##{id}")
      elem.find('input.checklist-checkbox').prop('checked', item.checked)
      elem.find('input.checklist-value').val(item.value).attr('data-blank', false)

      @initCheckListItemBinds elem

    move_elem = @new_jot_checklist_tab.find("li:not(.template) input[data-blank='true']").closest('li')
    move_elem.remove()
    @new_jot_checklist_tab.find('ul').append(move_elem)
    @initCheckListItemBinds move_elem
    @lj.sizeUI()

  focusLastCheckListItem: =>
    @new_jot_checklist_tab.find('li:not(.template) input.checklist-value').last().focus()

  newJotLength: =>
    if @new_jot_current_tab == 'heading'
      return @new_jot_heading.val().trim().length
    else if @new_jot_current_tab == 'standard'
      return @new_jot_content.val().trim().length
    else if @new_jot_current_tab == 'checklist'
      return @serializeNewJotCheckList().length
    else
      return 0

  submitNewJot: =>
    if @lj.emergency_mode.active && !@lj.emergency_mode.terms_accepted_by_user
      @lj.emergency_mode.showTerms()
      return

    content = window.escapeHtml @getJotContent()
    jot_type = @new_jot_current_tab

    if @newJotLength() > 0
      @lj.search.endSearchState false

      key = @randomKey()
      @insertTempJotElem content, key, jot_type, @new_jot_break_value
      @jots_empty_message_elem.hide()
      @scrollJotsToBottom()

      # If emergency mode is on, then store the jot in local storage. Otherwise send to server
      if @lj.emergency_mode.active
        @lj.emergency_mode.storeJot content, key, jot_type, @new_jot_break_value
        # reset new jot inputs
        @clearJotInputs()

      else
        # reset new jot inputs
        @clearJotInputs()

        @lj.connection.abortPossibleDataLoadXHR()
        $.ajax(
          type: 'POST'
          url: "/jots/"
          data: "content=#{encodeURIComponent(content)}&folder_id=#{@lj.app.current_folder}&topic_id=#{@lj.app.current_topic}&jot_type=#{jot_type}&break_from_top=#{@new_jot_break_value}"
          success: (data) =>
            @lj.connection.startDataLoadTimer()
            @lj.app.jots.push data.jot
            @integrateTempJot data.jot, key

            if (typeof @lj.app.current_folder == 'undefined' || !@lj.app.current_folder) && typeof data.auto_folder != 'undefined'
              @lj.folders.hideNewFolderForm()
              @lj.folders.pushFolderIntoData data.auto_folder

            if (typeof @lj.app.current_topic == 'undefined' || !@lj.app.current_topic) && typeof data.auto_topic != 'undefined'
              @lj.topics.hideNewTopicForm()
              @lj.topics.pushTopicIntoData data.auto_topic

            # Inform user of an auto generated folder or topic
            if typeof data.auto_folder != 'undefined' && typeof data.auto_topic != 'undefined'
              new HoverNotice(@lj, 'Folder and topic auto-generated.', 'success')
            if typeof data.auto_folder == 'undefined' && typeof data.auto_topic != 'undefined'
              new HoverNotice(@lj, 'Topic auto-generated.', 'success')

            # Extra check against emptiness, in case @vanish() conflicts with
            # this ajax request timing and the error message shows up
            # with the new jot..
            @checkIfJotsEmpty()

          error: (data) =>
            @lj.connection.startDataLoadTimer()
            unless !data.responseJSON || typeof data.responseJSON.error == 'undefined'
              new HoverNotice(@lj, data.responseJSON.error, 'error')
            else
              new HoverNotice(@lj, 'Could not save jot. Please check internet connect or contact us.', 'error')
            
            # Handle this gracefully
            @rollbackTempJot()
            @switchTab(jot_type)
            if jot_type == 'heading'
              @new_jot_heading.val(content)
            else if jot_type == 'standard'
              @new_jot_content.val(content)
            else if jot_type == 'checklist'
              @populateCheckList content
            @determineFocusForNewJot()

        )

      if @lj.app.folders.length > 1
        @lj.folders.moveCurrentFolderToTop()

      if @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder).length > 1
        @lj.topics.moveCurrentTopicToTop()

      @clearJotEntryTemplate()

  rollbackTempJot: =>
    @jots_list.find('li.temp').remove() # may need refinement

  insertTempJotElem: (content, key, jot_type, break_from_top) =>
    content = content.replace /\n/g, '<br />'
    @jot_temp_entry_template.find('li')
    .attr('id', key)
    .attr("title", "submitting jot...")

    timestamp = $("<div class='timestamp'><i class='fa fa-exchange'></i></div>");
    @jot_temp_entry_template.find('li').append timestamp

    if jot_type == 'checklist'
      @jot_temp_entry_template.find('li').append "<div class='content'>#{@parseCheckListToHTML(content)}</div>"
    else
      @jot_temp_entry_template.find('li').append "<div class='content'>#{content}</div>"

    if jot_type == 'heading'
      @jot_temp_entry_template.find('li').addClass('heading')

    if break_from_top
      @jot_temp_entry_template.find('li').addClass('break-from-top')

    build_entry = @jot_temp_entry_template.html()

    # parse possible links
    build_entry = Autolinker.link(build_entry)

    @jots_list.append build_entry

    # reset template where necessary (classes, content)
    @jot_temp_entry_template.find('li').removeClass('heading').removeClass('break-from-top')
    @jot_temp_entry_template.find('li .content').remove()

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
    heading_class = if jot.jot_type == 'heading' then 'heading' else ''
    break_class = if jot.break_from_top then 'break-from-top' else ''
    #highlighted_class = if (jot.id in @jots_in_search_results) then 'highlighted' else ''
    jot_content = jot.content.replace /\n/g, '<br />'

    build_html = "<li data-jot='#{jot.id}' class='jot-item #{flagged_class} #{heading_class} #{break_class}'>"
    build_html += "<div class='timestamp'></div>"

    if jot.has_manage_permissions
      build_html += "<i class='fa fa-edit edit' title='Edit jot' />
                    <i class='fa fa-trash delete' title='Delete jot' />
                    <div class='input-edit-wrap'>
                      <input type='text' class='input-edit' />
                    </div>"

    build_html += "<div class='content'>"

    if jot.jot_type == 'checklist'
      build_html += @parseCheckListToHTML jot.content
    else
      build_html += jot_content

    build_html += "</div>
                  </li>"

    # parse possible links
    build_html = Autolinker.link build_html

    @jots_list.append(build_html)
    @setTimestamp jot
    @initJotBinds jot.id
    if jot.jot_type == 'checklist'
      @initJotElemChecklistBind jot.id

  updateJotElem: (jot) =>
    elem = @jots_list.find("li[data-jot='#{jot.id}']")
    classes = ""
    if jot.is_flagged then classes += "flagged "
    if jot.jot_type == 'heading' then classes += "heading "
    if jot.break_from_top then classes += "break-from-top "
    #if (jot.id in @jots_in_search_results) then classes += "highlighted "
    elem.attr 'class', classes

    jot_content = jot.content.replace /\n/g, '<br />'

    if jot.jot_type == 'checklist'
      jot_content = @parseCheckListToHTML jot_content

    # parse possible links
    jot_content = Autolinker.link jot_content

    elem.find('.content').html jot_content
    @setTimestamp jot
    if jot.jot_type == 'checklist'
      @initJotElemChecklistBind jot.id

  setTimestamp: (jot) =>
    elem = @jots_list.find("[data-jot='#{jot.id}'] .timestamp")
    html = "<i class='flag-icon fa fa-flag'></i> "+ jot.created_at_short

    $(elem).html(html)
    .attr("title", "Written by #{jot.author_display_name}.<br>
                    Created on #{jot.created_at_long}.<br>
                    Last updated on #{jot.updated_at}.<br>
                    Click to toggle flag.")
    $(elem).cooltip({direction: 'left', align: 'bottom', class: 'timestamp'})

    # Update timestamp tooltip,
    # just in case this method call was to update the jot elem
    elem.cooltip 'update'

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
    @jots_list.find("li[data-jot='#{jot_id}'] .content").click (e) =>
      e.stopPropagation()
      @editJot jot_id

    @jots_list.find("li[data-jot='#{jot_id}'] .timestamp").click (e) =>
      e.stopPropagation()
      @flagJot jot_id

    @jots_list.find("li[data-jot='#{jot_id}'] i.edit").click (e) =>
      @editJot(jot_id)
      return false
    .cooltip({
      align: 'left'
    })

    @jots_list.find("li[data-jot='#{jot_id}'] i.delete").click (e) =>
      e.stopPropagation()
      @deleteJot jot_id
    .cooltip({
      align: 'left'
    })

  initJotElemChecklistBind: (jot_id) =>
    @jots_list.find("li[data-jot='#{jot_id}'] li.checklist-item").click (e) => 
      e.stopPropagation()
      @handleCheckboxEvent e, $(e.currentTarget), jot_id

      # If the clicked target was not the checkbox, then manipulate the checkbox event
      if $(e.target).prop('tagName') != 'INPUT'
        checkbox = $(event.currentTarget).find("input[type='checkbox']")
        checkbox.prop 'checked', !checkbox.is(':checked')

    .cooltip({
      direction: 'left'
      align: 'bottom'
    })


  handleCheckboxEvent: (e, elem, jot_id) =>
    # toggle checkbox
    parent_ul = elem.closest('ul')
    index = parent_ul.find("li.checklist-item").index elem
    jot_object = @lj.app.jots.filter((jot) => jot.id == jot_id)[0]
    content = JSON.parse(jot_object.content)
    content[index].checked = !content[index].checked
    jot_object.content = JSON.stringify content

    @toggleCheckJotItem jot_object, e, index

    return false


  toggleCheckJotItem: (jot, event, checkbox_index) =>
    if @lj.emergency_mode.active
      event.preventDefault()
      @lj.emergency_mode.feature_unavailable_notice()
      return

    checkbox = $(event.currentTarget).find("input[type='checkbox']")

    @lj.connection.abortPossibleDataLoadXHR()
    $.ajax(
      type: 'PATCH'
      url: "/jots/check_box/#{jot.id}"
      data: "content=#{jot.content}&checkbox_index=#{checkbox_index}"

      success: (data) =>
        @lj.connection.startDataLoadTimer()

        # all actions carried out on correct assumption that action would pass
        checkbox.closest('li').attr 'title', JSON.parse(data.jot.content)[checkbox_index].toggled_text
        .cooltip('update')
      error: (data) =>
        @lj.connection.startDataLoadTimer()
        checkbox.prop 'checked', !checkbox.is(':checked')
        unless !data.responseJSON || typeof data.responseJSON.error == 'undefined'
          new HoverNotice(@lj, data.responseJSON.error, 'error')
        else
          new HoverNotice(@lj, 'Could not toggle checkbox.', 'error')
    )

  flagJot: (id) =>
    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return

    elem = $("li[data-jot='#{id}']")
    is_flagged = elem.hasClass('flagged') ? true : false
    jot_object = @lj.app.jots.filter((jot) => jot.id == id)[0]

    @toggleFlagClientSide(jot_object)

    is_flagged = !is_flagged
    @lj.connection.abortPossibleDataLoadXHR()
    $.ajax(
      type: 'PATCH'
      url: "/jots/flag/#{id}"
      data: "is_flagged=#{is_flagged}"

      success: (data) =>
        @lj.connection.startDataLoadTimer()
        # all actions carried out on correct assumption that action would pass

      error: (data) =>
        @lj.connection.startDataLoadTimer()
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
    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return

    @lj.connection.abortPossibleDataLoadXHR()

    @currently_editing_id = id
    elem = $("li[data-jot='#{id}']")
    content_elem = elem.find('.content')
    jot_object = @lj.app.jots.filter((jot) => jot.id == id)[0]
    raw_content = window.unescapeHtml(jot_object.content)

    if !jot_object.has_manage_permissions
      new HoverNotice(@lj, 'You do not have permission to edit this jot.', 'error')
      return

    if jot_object.jot_type == 'heading'
      @switchTab 'heading'
      @new_jot_heading.val(raw_content).focus()
    else if jot_object.jot_type == 'checklist'
      @switchTab 'checklist'
      @populateCheckList(raw_content)
      @focusLastCheckListItem()
    else
      @switchTab 'standard'
      @new_jot_content.val(raw_content).focus()

    if jot_object.break_from_top
      @jotBreakOn()
    else
      @jotBreakOff()

    @edit_overlay.show()
    @edit_overlay.find('#edit-notice').css(
      bottom: (@new_jot_wrap.height()/2 - @edit_notice.height()/2)
      left: @new_jot_wrap.offset().left - @edit_notice.width()
    )
    elem.attr('data-editing', 'true')
    @new_jot_wrap.attr('data-editing', 'true')

  finishEditing: =>
    if @currently_editing_id
      id = @currently_editing_id
      @currently_editing_id = null
      elem = $("li[data-jot='#{id}']")
      content_elem = elem.find('.content')
      jot_object = @lj.app.jots.filter((jot) => jot.id == id)[0]
      old_content = jot_object.content
      raw_content = window.unescapeHtml(jot_object.content)

      updated_content = window.escapeHtml @getJotContent()
      jot_object.content = updated_content #doing this here in case they switch topics before ajax complete
      
      @edit_overlay.hide()
      @new_jot_wrap.attr('data-editing', 'false')
      jot_length = @newJotLength()
      @clearJotInputs()
      elem.attr('data-editing', 'false')
      
      # return keyboard controls
      @jots_wrapper.focus()
      @lj.key_controls.clearKeyedOverData()
      elem.attr('data-keyed-over', 'true')

      # only update folder/topic order & send server request if the user
      # changed the content field of the jot
      if jot_length > 0 && (updated_content != raw_content || @new_jot_break_value != jot_object.break_from_top || @new_jot_current_tab != jot_object.jot_type)
        @lj.folders.moveCurrentFolderToTop()
        @lj.topics.moveCurrentTopicToTop()

        jot_object.jot_type = @new_jot_current_tab
        if jot_object.jot_type == 'checklist'
          content_elem.html Autolinker.link(@parseCheckListToHTML(updated_content))
        else
          content_elem.html Autolinker.link(updated_content.replace(/\n/g, '<br />'))

        jot_object.break_from_top = @new_jot_break_value
        if @new_jot_break_value
          elem.addClass 'break-from-top'
        else
          elem.removeClass 'break-from-top'

        if @new_jot_current_tab == 'heading'
          elem.addClass 'heading'
        else
          elem.removeClass 'heading'

        $.ajax(
          type: 'PATCH'
          url: "/jots/#{id}"
          data: "content=#{encodeURIComponent(updated_content)}&break_from_top=#{@new_jot_break_value}&jot_type=#{@new_jot_current_tab}"

          success: (data) =>
            @lj.connection.startDataLoadTimer()
            jot_object.content = data.jot.content
            jot_object.created_at_long = data.jot.created_at_long
            jot_object.created_at_short = data.jot.created_at_short
            jot_object.updated_at = data.jot.updated_at
            @setTimestamp jot_object

            new HoverNotice(@lj, 'Jot updated.', 'success')

          error: (data) =>
            @lj.connection.startDataLoadTimer()
            unless !data.responseJSON || typeof data.responseJSON.error == 'undefined'
              new HoverNotice(@lj, data.responseJSON.error, 'error')
            else
              new HoverNotice(@lj, 'Could not update jot.', 'error')

            # Handle this gracefully
            @editJot jot_object.id
            @switchTab(jot_object.jot_type)
            if jot_object.jot_type == 'heading'
              @new_jot_heading.val(updated_content)
            else if jot_object.jot_type == 'standard'
              @new_jot_content.val(updated_content)
            else if jot_object.jot_type == 'checklist'
              @populateCheckList updated_content
            @determineFocusForNewJot()
        )
      else
        @lj.connection.startDataLoadTimer()

  deleteJot: (id) =>
    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return
      
    jot_object = @lj.app.jots.filter((jot) => jot.id == id)[0]
    if !jot_object.has_manage_permissions
      new HoverNotice(@lj, 'You do not have permission to delete this jot.', 'error')
      return

    elem = $("li[data-jot='#{id}']")
    elem.attr('data-deleting', 'true')

    @lj.connection.abortPossibleDataLoadXHR()
    $.ajax(
      type: 'POST'
      url: "/jots/#{id}"
      data: {'_method': 'delete'}

      success: (data) =>
        @lj.connection.startDataLoadTimer()
        new HoverNotice(@lj, data.message, 'success')
        @vanish id

      error: (data) =>
        @lj.connection.startDataLoadTimer()
        elem.attr('data-deleting', false)
        unless typeof data.responseJSON == 'undefined' || data.responseJSON.error == 'undefined'
          new HoverNotice(@lj, data.responseJSON.error, 'error')
        else
          new HoverNotice(@lj, 'Could not delete jot.', 'error')
    )

  vanish: (id) =>
    elem = $("li[data-jot='#{id}']")

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
      @determineFocusForNewJot()
      @jots_empty_message_elem.show()
      @positionEmptyMessage()
      return true
    else
      @jots_empty_message_elem.hide()
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

    $.each @lj.app.jots, (key, jot) =>
      if jot.topic_id == topic_id
        jot_keys.push key

    $.each jot_keys.reverse(), (array_key, topic_key) =>
      @lj.app.jots.remove topic_key
