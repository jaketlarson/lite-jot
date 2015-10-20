#= require litejot

class window.Jots extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @initJotFormListeners()
    @initResizeListeners()
    @initScrollListeners()
    @initJotColumnOptionsListener()
    @newJotWrapActive()
    @cleanCheckListTab()

  initVars: =>
    @new_jot_wrap = $('#new-jot-wrap')
    @new_jot_toolbar = $('#new-jot-wrap #jot-toolbar')
    @new_jot_heading = @new_jot_wrap.find('input#jot_heading')
    @new_jot_content = @new_jot_wrap.find('textarea#jot_content')
    @new_jot_content_original_height = @new_jot_content.outerHeight()
    @new_jot_checklist_tab = @new_jot_wrap.find('.tab-wrap#jot-checklist-tab')
    @new_jot_wrap_clicking = false
    @new_jot_current_tab = 'standard'
    @new_jot_break_option_wrap = @new_jot_toolbar.find('#jot-toolbar-break-option')
    @new_jot_break_value = false
    @palette_icon = $('#jot-palette-icon-wrap')
    @palette = $('#jot-palette')
    @palette_hide_timer = null
    @palette_hide_timer_length = 250
    @palette_current = 'default'
    @append_jot_link = $('.add-new-jot-to-end-link') # shows when editing other jots

    @jots_column = $('#jots-column')
    @jots_heading = $('h2#jots-heading')
    @jots_heading_text = $('h2#jots-heading .heading-text')
    @jots_wrapper = $('#jots-wrapper')
    @jots_list = @jots_wrapper.find('ul#jots-list')
    @jot_temp_entry_template = $('#jot-temp-entry-template')
    @jots_empty_message_elem = @jots_wrapper.find('.empty-message')
    @edit_overlay = $('#edit-overlay')
    @edit_notice = $('#edit-notice')
    @remember_palette_while_editing = null
    @currently_editing_id = null
    @jots_in_search_results = [] # array of jot id's that will be checked in @insertJotElem()
    @text_resize_factor = parseInt(@jots_heading.find('#jots-column-options .font-change .range-slider').attr('data-slider')) / 100 # current text resize factor
    @timestamp_text_max_px = .55*16 # .55rem * 16px/rem
    @content_text_default_px = .95*16 # .95rem * 16px/rem
    @update_jot_size_save_timer = null # used to prevent flooding of requests when saving jot size pref
    @update_jot_size_save_timer_length = 2000

    # ignore_this_key_down is used when moving from the last jot to new jot area
    # It's used because the keydown event from key controls
    # doubles up with keyup event for the checklist item bind
    # This is a quick fix
    @ignore_this_key_down = false

    # Number of jots per "page" or loaded batch
    @jots_per_page = 10
    @current_page = 1

    # load_on_scroll is used by @lj.topics.selectTopic to turn off
    # load-more functionality (loadMoreJots()) while jots list
    # is populated
    @load_on_scroll = false

  clearJotsList: =>
    @jots_list.find('> li:not(#new-jot-wrap)').remove()

  updateHeading: =>
    if !@lj.app.current_topic
      @jots_heading_text.html 'Jots'
    else
      topic_title = @lj.app.topics.filter((topic) => topic.id == @lj.app.current_topic)[0].title
      @jots_heading_text.html topic_title

    if @lj.search.current_terms.length > 0
      @jots_heading_text.prepend("<span class='search-result-info-test'>Searching </span>")

  buildJotsList: (mode) =>
    @clearJotsList()
    @updateHeading()
    @resetPageCounter()
    @disableLoadOnScroll()

    rel_jots = @lj.app.jots.filter((jot) => jot.topic_id == @lj.app.current_topic)
    if rel_jots.length > 0
      @jots_empty_message_elem.hide()

      i = 0

      # if searching, limit scope to keywords
      if @lj.search.current_terms.length > 0
        jots_scope = @lj.app.jots.filter((jot) => jot.content.toLowerCase().indexOf(@lj.search.current_terms.toLowerCase()) > -1)
      else
        jots_scope = @lj.app.jots
        jots_scope = rel_jots.slice(-1*@jots_per_page)

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
          @insertTempJotElem jot.content, jot.temp_key, jot.jot_type, jot.break, jot.color

      topic_title = @lj.app.topics.filter((topic) => topic.id == @lj.app.current_topic)[0].title
      @checkScrollPosition()

    # Use a timeout til scroll otherwise scrollbar wouldn't hit bottom
    setTimeout(() =>
      @scrollJotsToBottom()
    , 10)

    @enableLoadOnScroll()

  buildPage: (to, from) =>
    # rel_jots & jots scope is referring to jots stored in the app data, mirroring server
    # rel_em_jots & all_em_jots refers to jots saved on the browser in emergency mode.
    
    # NOTE: at this time, EM-stored jots are not using pagination..
    # they're just being built as a package on topic load in the
    # @buildJotsList method.. This could be a future improvement
    # to finish the (commented) attempt at making EM jots part of
    # the pagination flow, instead of one big batch.

    rel_jots = @lj.app.jots.filter((jot) =>
      jot.topic_id == @lj.app.current_topic
    )

    # rel_em_jots = @lj.emergency_mode.getStoredJotsObject().filter((jot) => jot.topic_id == @lj.app_current_topic)
    first_jot_pos = -1 * to
    last_jot_pos = -1 * from

    jots_scope = $.extend([], rel_jots.slice(first_jot_pos, last_jot_pos)).reverse()
    # em_jots_scope = $.extend([], rel_em_jots.slice(first_jot_pos, last_jot_pos)).reverse()

    # remaining_space = @jots_per_page - rel_em_jots.length
    # jots_scope = jots_scope.slice -1*remaining_space
    total_height = 0

    # $.each em_jots_scope, (index, jot) =>
    #   @insertTempJotElem jot.content, jot.temp_key, jot.jot_type, jot.break, jot.color method='prepend'
    #   total_height += @jots_list.find("li##{jot.temp_key}").outerHeight()

    $.each jots_scope, (index, jot) =>
      if $("li[data-jot='#{jot.id}']").length == 0
        @insertJotElem jot, method='prepend'
        total_height += @jots_list.find("li[data-jot='#{jot.id}']").outerHeight(true)

    return total_height

    # handle EM-stored jots

  newJotSubmit: =>
    if @new_jot_content.attr('data-editing') != 'true'
      @submitNewJot()

  initJotFormListeners: =>
    @new_jot_content.keyup (e) =>
      if !@currently_editing_id || true # 
        @checkIfJotContentExpands e

    @new_jot_content.keydown (e) =>
      if e.keyCode == @lj.key_controls.key_codes.enter && !e.shiftKey # enter key w/o shift key means submission
        e.preventDefault()
        if @currently_editing_id # if this is set, we're editing
          @finishEditing()
        else
          @newJotSubmit()

      if e.keyCode == @lj.key_controls.key_codes.tab
        e.preventDefault()

        @handleTabInJotContent e.shiftKey

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

    @palette_icon.mouseenter =>
      @showPalette()

    @palette_icon.mouseleave =>
      @hidePalette()

    @palette.mouseenter =>
      @showPalette()

    @palette.mouseleave =>
      @hidePalette()

    @palette.find('[data-color]').click (e) =>
      @palette.hide()
      @determineFocusForNewJot()
      @chooseColor e

    @append_jot_link.click (e) =>
      # Only shows when editing and the jot form is elsewhere.
      @append_jot_link.hide()
      @finishEditing()
      @determineFocusForNewJot()

  initResizeListeners: =>
    @jots_heading.find('#jots-column-options [data-slider]').on 'change.fndtn.slider', () =>
      @updateJotSize()

  determineFocusForNewJot: =>
    if @new_jot_current_tab == 'standard'
      @new_jot_content.focus()
    else if @new_jot_current_tab == 'heading'
      @new_jot_heading.focus()
    else if @new_jot_current_tab == 'checklist'
      @lj.key_controls.keyToLastNewJotListItem()

    @scrollJotsToBottom()

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
      @sizeJotContent()
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
    @new_jot_wrap.addClass('break-from-top')

    # If user is writing new jot, make sure they don't lose view of the new-jot-wrap.
    if !@currently_editing_id
      @scrollJotsToBottom()

  jotBreakOff: =>
    @new_jot_break_value = false
    @new_jot_break_option_wrap.find('.is-checked').hide()
    @new_jot_break_option_wrap.find('.not-checked').css('display', 'inline-block')
    @new_jot_wrap.removeClass('break-from-top')

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
    @new_jot_content.css 'height', @new_jot_content_original_height
    @cleanCheckListTab()

  cleanCheckListTab: =>
    if @new_jot_checklist_tab.find('li:not(.template)').length > 0
      @new_jot_checklist_tab.find('li:not(.template)').remove()

    @addNewCheckListItem()
    if @lj.init_data_loaded
      @lj.sizeUI()

    if @new_jot_current_tab == 'checklist'
      @new_jot_checklist_tab.find('li:not(.template) input.checklist-value').focus()

  # addNewCheckListItem / initCheckListItemBinds binding
  # that would normally be done in key_controls.js, but
  # since they are created in JS the binds were just added here.
  addNewCheckListItem: =>
    scrollToBottom = @isScrolledToBottom()
    html = @new_jot_checklist_tab.find('li.template').html()
    id = "checklist-item-#{@randomKey()}"
    @new_jot_checklist_tab.find('ul.jot-checklist').append("<li id='#{id}'>#{html}</li>")
   
    elem = $("li##{id}")
    @initCheckListItemBinds elem

    # Using a timeout here because scrollJotsToBottom
    # seems to be quicker than the DOM
    # Could be more elegant, possibly.
    setTimeout(() =>
      if scrollToBottom
        @scrollJotsToBottom()
    , 10)

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
    @jots_wrapper.scroll =>
      @checkScrollPosition()

  checkScrollPosition: =>
    if @jots_wrapper.scrollTop() == 0
      @jots_heading.removeClass('is-scrolled-from-top')
    else
      @jots_heading.addClass('is-scrolled-from-top')

    close_to_top = @jots_wrapper.scrollTop() - @lj.scroll_padding_factor*@jots_wrapper.height() <= 0
    if close_to_top && @load_on_scroll && @lj.search.current_terms.length == 0
      @loadMoreJots()

    # Do a quick check to see if more jots can be loaded to UI.
    @enoughJotsLoaded()

  # Called when scrolling and attempting to shows more jots,
  # if there are any more
  loadMoreJots: (override=false) =>
    # Don't load more if searching (yet, eventually will be programmed)
    if @lj.search.current_terms.length > 0
      return

    # override param can be used if we don't want to waste
    # time checking @allJotsLoaded() again, since it can
    # and very possibly was, called by @enoughJotsLoadeD()
    @current_page++
    to = @jots_per_page*(@current_page-1) + @jots_per_page
    from = @jots_per_page * (@current_page-1)

    if override || !@allJotsLoaded()
      total_height = @buildPage to, from
      @jots_wrapper.scrollTop total_height

  # Called until enough jots are loaded so that the user has
  # a scrollbar.
  enoughJotsLoaded: =>
    # Don't load more if searching (yet, eventually will be programmed)
    if @lj.search.current_terms.length > 0
      return

    if !@jots_wrapper.hasScrollBar()
      if !@allJotsLoaded()
        @loadMoreJots true
        @enoughJotsLoaded()

  # Returns whether or not all jots are showing on screen already
  allJotsLoaded: =>
    jots_data = @lj.app.jots.filter((jot) => jot.topic_id == @lj.app.current_topic)
    if jots_data.length > 0
      if $("li[data-jot='#{jots_data[0].id}']").length == 1
        return true
      else
        return false
    else
      return true

  enableLoadOnScroll: =>
    @load_on_scroll = true

  disableLoadOnScroll: =>
    @load_on_scroll = false

  resetPageCounter: =>
    @current_page = 1

  serializeNewJotCheckList: =>
    items = []
    $.each @new_jot_checklist_tab.find('li:not(.template)'), (index, item) =>
      # id will only be set if editing.
      id = $(item).find('input.checklist-item-id').val()
      is_checked = $(item).find("input[type='checkbox'].checklist-checkbox").is(':checked')
      value = $(item).find('input.checklist-value').val()

      if value.trim().length > 0
        item_hash =
          id: id
          checked: is_checked
          value: value
        items.push item_hash

    return items

  parseCheckListToHTML: (items, disabled=false) =>
    items = JSON.parse(items)
    html = "<ul class='checklist-jot'>"
    $.each items, (index, item) =>
      toggled_text = if item.toggled_text then item.toggled_text else "Click to toggle checkbox."
      html += "<li class='checklist-item' data-checklist-item-id='#{item.id}' title='#{toggled_text}'>"
      html += "<div class='checkbox-wrap'><input type='checkbox'#{if item.checked then " checked" else ""}#{if disabled then " disabled" else ""}></div>"
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

  # populateCheckList is used for editing and re-populating checklist
  # upon a submit-new-jot error.
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
      if item.id
        elem.find('input.checklist-item-id').val(item.id).attr('data-blank', false)

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
      @insertTempJotElem content, key, jot_type, @new_jot_break_value, @palette_current
      @jots_empty_message_elem.hide()
      @scrollJotsToBottom()

      # If emergency mode is on, then store the jot in local storage. Otherwise send to server
      if @lj.emergency_mode.active
        @lj.emergency_mode.storeJot content, key, jot_type, @new_jot_break_value, @palette_current
        # reset new jot inputs
        @clearJotInputs()

      else
        # reset new jot inputs
        @clearJotInputs()

        @lj.connection.abortPossibleDataLoadXHR()
        $.ajax(
          type: 'POST',
          url: "/jots/",
          data: { content: content, folder_id: @lj.app.current_folder, topic_id: @lj.app.current_topic, jot_type: jot_type, break_from_top: @new_jot_break_value, color: @palette_current }

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


  # Called when user submits a jot.
  # Adds jot to UI in a loading status.
  insertTempJotElem: (content, key, jot_type, break_from_top, color, method='append') =>
    content = content.replace /\n/g, '<br />'
    color = if color && color.length > 0 then @lj.colors[color] else @lj.colors['default']
    @jot_temp_entry_template.find('li')
    .attr('id', key)
    .attr("title", "submitting jot...")

    timestamp = $("<div class='timestamp'><i class='fa fa-exchange'></i></div>");
    @jot_temp_entry_template.find('li').append timestamp

    if jot_type == 'checklist'
      @jot_temp_entry_template.find('li').append "<div class='content-wrap'><div class='content' style='color: #{color}'>#{@parseCheckListToHTML(content, disabled=true)}</div></div>"
    else
      @jot_temp_entry_template.find('li').append "<div class='content-wrap'><div class='content' style='color: #{color}'>#{content}</div></div>"

    if jot_type == 'heading'
      @jot_temp_entry_template.find('li').addClass('heading')

    if break_from_top
      @jot_temp_entry_template.find('li').addClass('break-from-top')

    build_entry = @jot_temp_entry_template.html()

    # parse possible links
    build_entry = Autolinker.link(build_entry)

    if method == 'append'
      if @currently_editing_id 
        # Then we're editing, and have no idea where the new-jot-wrap is.
        @jots_list.append build_entry
      else
        $(build_entry).insertBefore @new_jot_wrap
    else if method == 'prepend'
      @jots_list.prepend build_entry

    @sizeText()

    # reset template where necessary (classes, content)
    @jot_temp_entry_template.find('li').removeClass('heading').removeClass('break-from-top')
    @jot_temp_entry_template.find('li .content-wrap').remove()
    @jot_temp_entry_template.find('li .timestamp').remove()

  # Updates the temporarily-added jot into a permanent jot if it saved successfully
  # on the server.
  integrateTempJot: (jot, key) =>
    elem = @jots_list.find("##{key}")
    elem.removeClass('temp').addClass('jot-item')
    .attr('data-jot', jot.id).attr('id', '').attr('title', '')

    to_insert = "<i class='fa fa-trash delete' title='Delete jot' />"

    elem.append to_insert
    elem.find("input[type='checkbox']").prop('disabled', false)
    @setTimestamp jot
    @initJotBinds jot.id

    if jot.jot_type == 'checklist'
      @initJotElemChecklistBind jot.id
      content = JSON.parse(jot.content)

      # Can assume checkboxe elems are in order of object
      $.each elem.find('li.checklist-item'), (key, checklist_item) =>
        $(checklist_item).attr 'data-checklist-item-id', content[key].id


  # Used to insert a jot element on the UI.
  # This is not called when a user submits a jot. Instead, insertTempJotElem is called.
  insertJotElem: (jot, method='append', before_id=null, flash=false) =>
    # improve this class code stuff.. make it an array and then join by spaces.
    flagged_class = if jot.is_flagged then 'flagged' else ''
    heading_class = if jot.jot_type == 'heading' then 'heading' else ''
    email_tag_class = if jot.jot_type == 'email_tag' then 'email-tag' else ''
    break_class = if jot.break_from_top then 'break-from-top' else ''
    jot_content = jot.content.replace /\n/g, '<br />'
    flash_class = if flash then 'flash' else ''
    content_title = if jot.jot_type == 'email_tag' then 'Click to open email thread transcript' else ''

    $html = $("<li />")
    $html.attr 'data-jot', jot.id
    $html.addClass "jot-item #{flagged_class} #{heading_class} #{break_class} #{flash_class} #{email_tag_class}'"
    $html.attr 'data-tagged-email-id', jot.tagged_email_id
    $html.append "<div class='timestamp'></div>"

    if jot.has_manage_permissions
      $html.append "<i class='fa fa-trash delete' title='Delete jot' />"

    $html.append "<div class='content-wrap' title='#{content_title}' />"

    if jot.user_id != @lj.app.user.id
      $html.find('.content-wrap').append "<div class='author' title='#{jot.author_email}'>#{jot.author_display_name}</div>"

    $html.find('.content-wrap').append "<div class='content' />"

    if jot.jot_type == 'checklist'
      $html.find('.content').append @parseCheckListToHTML jot.content
    else if jot.jot_type == 'email_tag'
      $html.find('.content').append "<i class='fa fa-lock private-jot-icon' title='Jot is private, and is hidden from users shared with this folder.'></i>
                     <i class='fa fa-envelope email-tag-icon' title='This jot is an email tag.'></i>
                     #{jot_content}"
    else
      $html.find('.content').append jot_content

    # parse possible links
    $html.html Autolinker.link $html.html()

    if method == 'append'
      if @currently_editing_id 
        # Then we're editing, and have no idea where the new-jot-wrap is.
        @jots_list.append $html
      else
        $html.insertBefore @new_jot_wrap

    else if method == 'prepend'
      @jots_list.prepend $html
    else if method == 'before'
      # Uses passed param 'before_id' and inserts elem after the corresponding jot.
      target = @jots_list.find("li[data-jot='#{before_id}']")
      if target.length == 1
        $html.insertBefore target

    @setTimestamp jot
    @initJotBinds jot.id

    if jot.jot_type == 'checklist'
      @initJotElemChecklistBind jot.id

    # handle coloring
    if jot.color && jot.color.length > 0
      $html.find('.content').css 'color', @lj.colors[jot.color]

    @sizeText jot.id

  updateJotElem: (jot) =>
    elem = @jots_list.find("li[data-jot='#{jot.id}']")
    classes = "jot-item "
    if jot.is_flagged then classes += "flagged "
    if jot.jot_type == 'heading' then classes += "heading "
    if jot.break_from_top then classes += "break-from-top "
    elem.attr 'class', classes

    jot_content = jot.content.replace /\n/g, '<br />'

    if jot.jot_type == 'checklist'
      jot_content = @parseCheckListToHTML jot_content
    else if jot.jot_type == 'email_tag'
      jot_content = "<i class='fa fa-eye private-jot-icon' title='Jot is private, and is hidden from users shared with this folder.'></i>
                     <i class='fa fa-envelope email-tag-icon' title='This jot is an email tag.'></i>
                     #{jot_content}"

    # parse possible links
    jot_content = Autolinker.link jot_content

    elem.find('.content').html jot_content
    @initPrivateAndEmailTagBinds jot

    @setTimestamp jot
    if jot.jot_type == 'checklist'
      @initJotElemChecklistBind jot.id

    # handle coloring
    if jot.color && jot.color.length > 0
      @jots_list.find("li[data-jot='#{jot.id}'] .content").css 'color', @lj.colors[jot.color]

    @sizeText jot.id

  sortJotData: =>
    @lj.app.jots.sort((a, b) =>
      return a.created_at_unix - b.created_at_unix
    )

  setTimestamp: (jot) =>
    elem = @jots_list.find("[data-jot='#{jot.id}'] .timestamp")
    html = "<i class='flag-icon fa fa-flag'></i> "+ jot.created_at_short

    $(elem).html(html).attr("title", "Created on #{jot.created_at_long}.\nLast updated on #{jot.updated_at}")

    # Update timestamp tooltip,
    # just in case this method call was to update the jot elem

  scrollJotsToBottom: =>
    @jots_wrapper.scrollTop @jots_wrapper[0].scrollHeight

  isScrolledToBottom: =>
    buffer = 1 # seems to be buggy in Chrome, so just add 1 to the test
    @jots_wrapper.scrollTop() + @jots_wrapper.outerHeight() + buffer >= @jots_wrapper[0].scrollHeight

  clearJotEntryTemplate: =>
    @jot_temp_entry_template.find('li').html('')

  randomKey: =>
    build_key = ""
    possibilities = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890"

    for i in [0..50]
      build_key += possibilities.charAt(Math.floor(Math.random() * possibilities.length))

    return build_key;

  initJotBinds: (jot_id) =>
    jot = @lj.app.jots.filter((jot) => jot.id == jot_id)[0]
    elem = @jots_list.find("li[data-jot='#{jot_id}']")

    elem.click (e) =>
      e.stopPropagation() # is this necessary?
      @editJot jot_id

    elem.find(".timestamp").click (e) =>
      e.stopPropagation() # is this necessary?
      @flagJot jot_id

    elem.find(".author").click (e) =>
      e.stopPropagation() # shouldn't edit on click
    .cooltip()

    elem.find("i.delete").click (e) =>
      e.stopPropagation() # is this necessary?
      @deleteJot jot_id
    .cooltip({
      align: 'left'
    })

    elem.find("a").click (e) =>
      e.stopPropagation()

    @initPrivateAndEmailTagBinds jot

  initPrivateAndEmailTagBinds: (jot) =>
    elem = @jots_list.find("li[data-jot='#{jot.id}']")
    elem.find(".private-jot-icon").cooltip()

    if jot.jot_type == 'email_tag'
      elem.find(".email-tag-icon").cooltip()
      elem.find('.content').click =>
        email_id = elem.attr('data-tagged-email-id')
        new window.EmailViewer @lj, email_id
      .cooltip({
        direction: 'left'
        align: 'bottom'
        zIndex: 1000
      })

  initJotElemChecklistBind: (jot_id) =>
    @jots_list.find("li[data-jot='#{jot_id}'] li.checklist-item input[type='checkbox']").change (e) => 
      e.stopPropagation()
      @handleCheckboxEvent e, $(e.currentTarget).closest('li'), jot_id

    @jots_list.find("li[data-jot='#{jot_id}'] li.checklist-item").cooltip({
      direction: 'left'
    })

    .click (e) =>
      e.stopPropagation()

  handleCheckboxEvent: (e, elem, jot_id) =>
    # toggle checkbox
    parent_ul = elem.closest('ul')
    id = elem.attr 'data-checklist-item-id'
    jot_object = @lj.app.jots.filter((jot) => jot.id == jot_id)[0]
    content = JSON.parse(jot_object.content)
    item = content.filter((item) => item.id == id)[0]
    item.checked = !item.checked
    jot_object.content = JSON.stringify content

    @toggleCheckJotItem jot_object, e, id

    return false

  toggleCheckJotItem: (jot, event, checklist_item_id) =>
    if @lj.emergency_mode.active
      event.preventDefault()
      @lj.emergency_mode.feature_unavailable_notice()
      return

    checkbox = @jots_list.find("li[data-jot='#{jot.id}'] li[data-checklist-item-id='#{checklist_item_id}'] input[type='checkbox']")

    @lj.connection.abortPossibleDataLoadXHR()
    $.ajax(
      type: 'PATCH'
      url: "/jots/check_box/#{jot.id}"
      data: "content=#{jot.content}&checklist_item_id=#{checklist_item_id}"

      success: (data) =>
        @lj.connection.startDataLoadTimer()

        # all actions carried out on correct assumption that action would pass
        updated_item = JSON.parse(data.jot.content).filter((item) => item.id == checklist_item_id)[0]
        toggled_text = updated_item.toggled_text
        checkbox.closest('li').attr 'title', toggled_text
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

    @lj.connection.abortPossibleData

    # If currently editing another jot, wrap up and switch gears.
    if @currently_editing_id
      @finishEditing editingAnother=true

    @currently_editing_id = id
    elem = $("li[data-jot='#{id}']")
    content_elem = elem.find('.content')
    jot_object = @lj.app.jots.filter((jot) => jot.id == id)[0]
    raw_content = window.unescapeHtml(jot_object.content)

    if !jot_object.has_manage_permissions
      new HoverNotice(@lj, 'You do not have permission to edit this jot.', 'error')
      return

    if jot_object.jot_type == 'email_tag'
      new HoverNotice(@lj, 'At this time, email tags cannot be edited.', 'error')
      return

    @new_jot_wrap.insertAfter elem
    elem.hide()
    @new_jot_wrap.attr 'data-editing', 'true'
    @append_jot_link.css 'display', 'block'

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
      @sizeJotContent()

    if jot_object.break_from_top
      @jotBreakOn()
    else
      @jotBreakOff()

    @remember_palette_while_editing = @palette_current
    if jot_object.color && jot_object.color.length > 0
      @palette_current = jot_object.color
      @applyPaletteColor @palette_current
    else
      @applyPaletteColor 'default'

  finishEditing: (editingAnother=false) =>
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
      
      elem.show()

      # editingAnother is set to true when the user switches from one jot edit
      # to another, and having this check here will make it smoother.
      # Otherwise, the UI jumps when doing unnecessary manipulation (the appending/hiding)
      if !editingAnother
        @jots_list.append @new_jot_wrap
        @append_jot_link.hide()

      jot_length = @newJotLength()
      @clearJotInputs()
      elem.attr('data-editing', 'false')
      
      # return keyboard controls
      @jots_list.focus()
      @lj.key_controls.clearKeyedOverData()
      elem.attr('data-keyed-over', 'true')

      # return to old palette color
      jot_color = @palette_current
      @palette_current = @remember_palette_while_editing
      @remember_palette_while_editing = null
      @applyPaletteColor @palette_current

      # only update folder/topic order & send server request if the user changed the jot
      if jot_length > 0 && (updated_content != raw_content || @new_jot_break_value != jot_object.break_from_top || @new_jot_current_tab != jot_object.jot_type) || jot_color != jot_object.color
        @lj.folders.moveCurrentFolderToTop()
        @lj.topics.moveCurrentTopicToTop()

        jot_object.jot_type = @new_jot_current_tab

        if jot_object.jot_type == 'checklist'
          content_elem.html Autolinker.link(@parseCheckListToHTML(updated_content))
          @sizeText jot_object.id
          $.each elem.find('li'), (key, item_elem) =>
            @initJotElemChecklistBind id
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

        # update color
        jot_object.color = jot_color

        $.ajax(
          type: 'PATCH'
          url: "/jots/#{id}"
          data: "content=#{encodeURIComponent(updated_content)}&break_from_top=#{@new_jot_break_value}&jot_type=#{@new_jot_current_tab}&color=#{jot_color}"

          success: (data) =>
            @lj.connection.startDataLoadTimer()
            jot_object.content = data.jot.content
            jot_object.created_at_long = data.jot.created_at_long
            jot_object.created_at_short = data.jot.created_at_short
            jot_object.updated_at = data.jot.updated_at
            @updateJotElem jot_object

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
    elem.attr('data-deleted', 'true')

    @removeJotFromDataById id

    setTimeout(() =>
      elem.remove()
      @checkIfJotsEmpty()
    , 350)

  removeJotFromDataById: (id) =>
    jot_key = null
    $.each @lj.app.jots, (index, jot) =>
      if jot.id == id
        jot_key = index
        return false

    @lj.app.jots.remove(jot_key)

  checkIfJotsEmpty: =>
    if @lj.app.jots.filter((jot) => if(jot) then (jot.topic_id == @lj.app.current_topic) else false).length == 0
      @determineFocusForNewJot()
      #@jots_empty_message_elem.show()
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

  canEdit: (id, jot) => # allow jot id or jot object.
    if !jot
      jot = @lj.app.jots.filter((jot) => jot.id == id)
    if jot.length == 0 then return false
    if !jot.has_manage_permissions then return false
    if jot.jot_type == 'email_tag' then return false
    return true

  showPalette: =>
    @palette.show()
    @positionPalette()

    if @palette_hide_timer
      clearTimeout @palette_hide_timer

  hidePalette: =>
    @palette_hide_timer = setTimeout(() =>
      @palette.hide()
    , @palette_hide_timer_length)

  positionPalette: =>
    pal_top = @palette_icon.offset().top - @palette.height() + @palette_icon.height()/2
    pal_left = @palette_icon.offset().left + @palette_icon.width()

    @palette.css({
      top: pal_top
      left: pal_left
    })

  chooseColor: (event) =>
    color = $(event.currentTarget).attr('data-color')
    @applyPaletteColor color

  applyPaletteColor: (color) =>
    @palette_current = color
    @palette.find('li.active').removeClass('active')
    @palette.find("[data-color='#{color}']").addClass 'active'

    @new_jot_content.css 'color', @lj.colors[color]
    @new_jot_heading.css 'color', @lj.colors[color]
    @new_jot_checklist_tab.find("input[type='text']").css 'color', @lj.colors[color]
    @palette_icon.css 'color', @lj.colors[color]

  checkIfJotContentExpands: (event) =>
    @sizeJotContent()

  sizeJotContent: =>
    if @new_jot_content[0].scrollHeight > @new_jot_content_original_height
      @new_jot_content.css 'height', @new_jot_content[0].scrollHeight+1
      @scrollJotsToBottom()

  initJotColumnOptionsListener: =>
    @jots_heading.find('a.options-dropdown-link').click =>
      console.log 'test'
      setTimeout(() =>
        $(document).foundation 'slider', 'reflow'
      ,100)
      # super hacky.. posted on GitHub about this:
      # https://github.com/zurb/foundation/issues/6946

  sizeText: (id) =>
    if !id
      selector = "li.jot-item, li.temp"
    else
      selector = "li.jot-item[data-jot='#{id}'], li.temp"

    if @content_text_default_px*@text_resize_factor > @content_text_default_px
      timestamp_size = @timestamp_text_max_px
      timestamp_lineheight = @content_text_default_px*1.5
    else
      timestamp_size = @timestamp_text_max_px*@text_resize_factor
    timestamp_lineheight = @content_text_default_px*1.5*@text_resize_factor

    @jots_list.find(selector).find('.checklist-item, i:not(.flag-icon)').andSelf().css(
      fontSize: @content_text_default_px*@text_resize_factor+'px'
      lineHeight: @content_text_default_px*1.5*@text_resize_factor+'px'
    )

    @jots_list.find(selector).find('.timestamp, .timestamp i').css(
      fontSize: timestamp_size+'px'
      lineHeight: timestamp_lineheight+'px'
    )

  updateJotSize: =>
    @text_resize_factor = parseInt(@jots_heading.find('#jots-column-options .font-change .range-slider').attr('data-slider')) / 100
    @sizeText()

    if @update_jot_size_save_timer
      clearTimeout @update_jot_size_save_timer

    @update_jot_size_save_timer = setTimeout(() =>
      @lj.user_settings.updatePreference 'jot_size', @text_resize_factor
    , @update_jot_size_save_timer_length)

  handleTabInJotContent: (shift_pressed) =>
    start_pos = @new_jot_content.get(0).selectionStart
    end_pos = @new_jot_content.get(0).selectionEnd
    val = @new_jot_content.val()

    if start_pos == end_pos
      # We have to determine if we are indenting, dedenting or breaking lines
      # Lite Jot uses the tab to break line when the character
      # before the mouse position is actual content (not \n or \t).
      unless shift_pressed
        if start_pos != 0 && val[start_pos-1] != "\t" && val[start_pos-1] != "\n"
          insert_char = "\n"
        else
          insert_char = "\t"

        new_val = val.substring(0, start_pos) \
                  + insert_char \
                  + val.substring(start_pos)
        @new_jot_content.val(new_val).setCursorPosition(start_pos+1)

      else
        if start_pos == 0
          # shift+tab doesn't do anything on empty content
          return

        if val[start_pos-1] == "\t" || val[start_pos-1] == "\n"
          new_val = val.substring(0, start_pos-1) \
                    + val.substring(start_pos)

          @new_jot_content.val(new_val).setCursorPosition(start_pos-1)

    else
      # We have to indent or dedent several things
      selection_val = val.substring(start_pos, end_pos)
      original_length = selection_val.length

      unless shift_pressed
        selection_val = selection_val.replace(/\n/g, "\n\t")
        selection_val = "\t"+selection_val

        new_val = val.substring(0, start_pos) \
                  + selection_val \
                  + val.substring(end_pos)

        new_length = selection_val.length
        length_diff = original_length - new_length

      else
        selection_val = selection_val.replace(/\n\t/g, "\n")

        if selection_val[0] == "\t"
          selection_val = selection_val.substring(1)

        new_val = val.substring(0, start_pos) \
                  + selection_val \
                  + val.substring(end_pos)

        new_length = selection_val.length
        length_diff = original_length - new_length

      @new_jot_content.val(new_val).selectRange(start_pos, end_pos-length_diff)

