#= require litejot

class window.KeyControls extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @initKeyBinds()
    @initKeyboardShortcutsHelpBind()

  initVars: =>
    @key_codes =
      enter: 13
      left: 37
      up: 38
      right: 39
      down: 40
      del: 46
      backspace: 8
      e: 69
      f: 70
      n: 78
      esc: 27
      s: 83
      y: 89
      b: 66

    # virtual architecture user is navigating w/ keyboard
    @key_nav = {}

    @key_nav.folders =
      up: @keyToNextFolderUp
      down: @keyToNextFolderDown
      right: @keyToCurrentTopic
      e: @editFolderKeyedAt
      n: @keyToNewFolder
      del: @lj.folders.deleteFolderPrompt
      backspace: @lj.folders.deleteFolderPrompt

    @key_nav.topics =
      left: @keyToCurrentFolder
      up: @keyToNextTopicUp
      down: @keyToNextTopicDown
      right: @keyToNewJotFromSearchOrTopic
      e: @editTopicKeyedAt
      n: @keyToNewTopic
      del: @lj.topics.deleteTopicPrompt
      backspace: @lj.topics.deleteTopicPrompt

    @key_nav.jots =
      left: @keyToCurrentTopic
      up: @keyToNextJotUp
      down: @keyToNextJotDown
      right: @lj.search.focusSearchInput
      e: @editJotKeyedAt
      f: @flagJotKeyedAt
      n: @keyToNewJot
      del: @deleteJotKeyedAt
      backspace: @deleteJotKeyedAt
      s: @lj.search.focusSearchInput

    @key_nav.jot_toolbar =
      left: @keyToLeftJotToolbarTab
      right: @keyToRightJotToolbarTab
      up: @keyToNewJot
      b: @lj.jots.toggleJotBreak

    @key_nav.search_jots =
      down: @keyToFirstJotOrNew
      esc: @lj.search.endSearchState
      left: @keyToNewJotFromSearchOrTopic

    @curr_pos = 'new_jot'
    @curr_pos_index = null

  # Returns whether or not the given key code is valid within the
  # controls scope by cross referencing the master keycodes object
  # and using that key (if it exists) to check the controls_scope.
  # The controls_scope would be the object of key names mapped to 
  # functions. E.g., to check if key code 46 in @key_nav.jots then
  # use isValidControl(46, @key_nav.jots)
  isValidControl: (key_code, controls_scope) =>
    key_name = null
    $.each @key_codes, (key, code) =>
      if code == key_code
        key_name = key
        return

    if key_name == null || typeof(controls_scope[key_name]) == 'undefined'
      return false
    else
      return true

  getControlFunctionByKeyCode: (key_code, controls_scope) =>
    key_name = null
    $.each @key_codes, (key, code) =>
      if code == key_code
        key_name = key
        return

    if key_name == null || typeof(controls_scope[key_name]) == 'undefined'
      return false
    else
      return controls_scope[key_name]

  initKeyBinds: =>
    # New Jot, standard content type
    @lj.jots.new_jot_content.keydown (e) =>
      jots_count = @lj.app.jots.filter((jot) => jot.topic_id == @lj.app.current_topic).length
      if e.keyCode == @key_codes.up && $(e.currentTarget).val().trim().length == 0 && jots_count > 0 && !@lj.jots.currently_editing_id
        $(e.currentTarget).blur()
        @keyToLastJot()

      if e.keyCode == @key_codes.left && $(e.currentTarget).val().trim().length == 0 && !@lj.jots.currently_editing_id
        $(e.currentTarget).blur()
        @keyToCurrentTopic()

      if e.keyCode == @key_codes.right && $(e.currentTarget).val().trim().length == 0 && !@lj.jots.currently_editing_id
        @lj.search.focusSearchInput()

      if e.keyCode == @key_codes.down && $(e.currentTarget).val().trim().length == 0
        @keyToNewJotsTabs()

    # New Jot, heading type
    @lj.jots.new_jot_heading.keydown (e) =>
      jots_count = @lj.app.jots.filter((jot) => jot.topic_id == @lj.app.current_topic).length
      if e.keyCode == @key_codes.up && $(e.currentTarget).val().trim().length == 0 && jots_count > 0 && !@lj.jots.currently_editing_id
        $(e.currentTarget).blur()
        @keyToLastJot()

      if e.keyCode == @key_codes.left && $(e.currentTarget).val().trim().length == 0 && !@lj.jots.currently_editing_id
        $(e.currentTarget).blur()
        @keyToCurrentTopic()

      if e.keyCode == @key_codes.right && $(e.currentTarget).val().trim().length == 0 && !@lj.jots.currently_editing_id
        @lj.search.focusSearchInput()

      if e.keyCode == @key_codes.down && $(e.currentTarget).val().trim().length == 0
        @keyToNewJotsTabs()




    @lj.jots.jots_wrapper.keydown (e) =>
      if !@isValidControl(e.keyCode, @key_nav.jots)
        return

      is_editing = if @lj.jots.jots_wrapper.find("li[data-editing='true']").length > 0 then true else false

      if is_editing
        if e.keyCode == @key_codes.up || e.keyCode == @key_codes.down
          @getKeyedOverElem().find('input.input-edit')[0].blur()

        else
          return
      else
        e.preventDefault()

      if @isValidControl e.keyCode, @key_nav.jots
        @getControlFunctionByKeyCode(e.keyCode, @key_nav.jots).call()

    @lj.topics.topics_column.keydown (e) =>
      console.log 'what'
      if !@isValidControl(e.keyCode, @key_nav.jots)
        return

      new_field_has_focus = @lj.topics.new_topic_title.is(':focus')
      is_editing = if @lj.topics.topics_wrapper.find("li[data-editing='true']").length > 0 then true else false

      if new_field_has_focus && @lj.topics.new_topic_title.val().trim().length == 0
        if e.keyCode == @key_codes.left
          @key_nav.topics.left()
        else if e.keyCode == @key_codes.right
          @key_nav.topics.right()

      if is_editing || new_field_has_focus
        topics_count = @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder).length

        if (e.keyCode == @key_codes.up || e.keyCode == @key_codes.down) && topics_count > 0
          @getKeyedOverElem().find('input.input-edit')[0].blur() # needs improvement

        else
          return
      else
        e.preventDefault()

      if !@lj.topics.new_topic_title.is(':focus')
        e.preventDefault()

      if @isValidControl e.keyCode, @key_nav.topics
        @getControlFunctionByKeyCode(e.keyCode, @key_nav.topics).call()

    @lj.folders.folders_column.keydown (e) =>
      if !@isValidControl(e.keyCode, @key_nav.jots)
        return

      new_field_has_focus = @lj.folders.new_folder_title.is(':focus')
      is_editing = if @lj.folders.folders_wrapper.find("li[data-editing='true']").length > 0 then true else false

      if new_field_has_focus && @lj.folders.new_folder_title.val().trim().length == 0
        if e.keyCode == @key_codes.right
          @key_nav.folders.right()

      if is_editing || new_field_has_focus
        folders_count = @lj.app.folders.length

        if (e.keyCode == @key_codes.up || e.keyCode == @key_codes.down) && folders_count > 0
          @getKeyedOverElem().find('input.input-edit')[0].blur() # needs improvement

        else
          return
      else
        e.preventDefault()

      if !@lj.folders.new_folder_title.is(':focus')
        e.preventDefault()

      if @isValidControl e.keyCode, @key_nav.folders
        @getControlFunctionByKeyCode(e.keyCode, @key_nav.folders).call()

    @lj.search.search_input.keydown (e) =>
      if @isValidControl e.keyCode, @key_nav.search_jots
        @getControlFunctionByKeyCode(e.keyCode, @key_nav.search_jots).call()

    @lj.jots.new_jot_toolbar.keyup (e) =>
      if @isValidControl e.keyCode, @key_nav.jot_toolbar
        e.stopImmediatePropagation()
        @getControlFunctionByKeyCode(e.keyCode, @key_nav.jot_toolbar).call()

    @lj.folders.folders_column.focus (e) =>
      @curr_pos = 'folders'
      @switchKeyboardShortcutsPane()

      # only clear keyed over settings if not in folders column already
      # this avoids bugs with editing and deleting
      if @lj.folders.folders_column.find('[data-keyed-over=true]').length == 0
        @clearKeyedOverData()

    @lj.topics.topics_column.focus (e) =>
      @curr_pos = 'topics'
      @switchKeyboardShortcutsPane()
      @clearKeyedOverData()

      # only clear keyed over settings if not in topics column already
      # this avoids bugs with editing and deleting
      if @lj.topics.topics_column.find('[data-keyed-over=true]').length == 0
        @clearKeyedOverData()

    @lj.jots.jots_wrapper.focus (e) =>
      @curr_pos = 'jots'
      @switchKeyboardShortcutsPane()
      @clearKeyedOverData()

    @lj.jots.new_jot_content.focus (e) =>
      @curr_pos = 'new_jot_content'
      @switchKeyboardShortcutsPane()
      @clearKeyedOverData()

    @lj.jots.new_jot_heading.focus (e) =>
      @curr_pos = 'new_jot_header'
      @switchKeyboardShortcutsPane()

    @lj.search.search_input.focus (e) =>
      @curr_pos = 'search_jots'
      @switchKeyboardShortcutsPane()
      @clearKeyedOverData()

    @lj.jots.new_jot_toolbar.focus (e) =>
      @curr_pos = 'jot_toolbar'
      @switchKeyboardShortcutsPane()
      @clearKeyedOverData()

    @lj.folders.folders_column.blur (e) =>
      @clearKeyboardShortcutsPane()

    @lj.topics.topics_column.blur (e) =>
      @clearKeyboardShortcutsPane()

    @lj.jots.jots_wrapper.blur (e) =>
      @clearKeyboardShortcutsPane()
      @clearKeyedOverData()

    @lj.jots.new_jot_content.blur (e) =>
      @clearKeyboardShortcutsPane()

    @lj.jots.new_jot_heading.blur (e) =>
      @clearKeyboardShortcutsPane()

    @lj.search.search_input.blur (e) =>
      @clearKeyboardShortcutsPane()

    @lj.jots.new_jot_toolbar.blur (e) =>
      @clearKeyboardShortcutsPane()

  initKeyboardShortcutsHelpBind: =>
    $('nav a#keyboard-shortcuts-link').click =>
      @toggleKeyboardShortcutsHelp()

    $('#keyboard-shortcuts .default').show()

  clearKeyboardShortcutsPane: =>
    @curr_pos = null
    @switchKeyboardShortcutsPane()
    $('#keyboard-shortcuts .default').show()

  toggleKeyboardShortcutsHelp: =>
    keyboard_shortcuts_list = $('#keyboard-shortcuts')
    keyboard_shortcuts_link = $('nav a#keyboard-shortcuts-link')
    help_is_visible = if keyboard_shortcuts_list.is(':visible') then true else false

    if help_is_visible
      keyboard_shortcuts_list.removeClass('active')
      keyboard_shortcuts_link.removeClass('active')

      data = 
        user: 
          is_viewing_key_controls: 0

      $.ajax(
        type: 'PATCH'
        url: "/users"
        data: data
        success: (data) =>

        error: (data) =>
      )

    else
      keyboard_shortcuts_list.addClass('active')
      keyboard_shortcuts_link.addClass('active')

      data = 
        user: 
          is_viewing_key_controls: 1

      $.ajax(
        type: 'PATCH'
        url: "/users"
        data: data
        success: (data) =>

        error: (data) =>
      )

    @lj.sizeUI()

  switchKeyboardShortcutsPane: =>
    panes = 
      folders: '#keyboard-shortcuts #folder-keys'
      topics: '#keyboard-shortcuts #topic-keys'
      jots: '#keyboard-shortcuts #jot-keys'
      new_jot_content: '#keyboard-shortcuts #new_jot_content-keys'
      new_jot_header: '#keyboard-shortcuts #new_jot_header-keys'
      new_jot_checklist: '#keyboard-shortcuts #new_jot_checklist-keys'
      jot_toolbar: '#keyboard-shortcuts #jot_toolbar-keys'
      search_jots: '#keyboard-shortcuts #search_jots-keys'

    $('#keyboard-shortcuts .default').hide()

    $.each panes, (key, selector) =>
      if key == @curr_pos
        $(selector).show()

      else
        $(selector).hide()

  clearKeyedOverData: =>
    $("[data-keyed-over='true']").attr('data-keyed-over', 'false')

  getKeyedOverElem: =>
    return $($('html').find("[data-keyed-over='true']")[0])

  switchKeyedOverElem: (new_elem) =>
    @clearKeyedOverData()
    new_elem.attr('data-keyed-over', 'true')

  keyToLastJot: =>
    @clearKeyedOverData()
    @lj.jots.jots_wrapper.focus()
    # Using a delay due to issues with chrome not scrolling to bottom immediately
    setTimeout(() =>
      @lj.jots.scrollJotsToBottom()
    , 1)

    if @lj.jots.jots_wrapper.find('li.jot-item').length > 0
      elem = $(@lj.jots.jots_wrapper.find('li.jot-item')[@lj.jots.jots_wrapper.find('li.jot-item').length - 1])
      elem.attr('data-keyed-over', 'true')
      @curr_pos = 'jot'
      @curr_pos_index = @lj.jots.jots_wrapper.find('li').length - 1

  keyToFirstJot: =>
    @clearKeyedOverData()
    @lj.jots.jots_wrapper.focus()

    if @lj.jots.jots_wrapper.find('li').length > 0
      elem = $(@lj.jots.jots_wrapper.find('li')[0])
      elem.attr('data-keyed-over', 'true')
      @curr_pos = 'jot'
      @cur_pos_index = 0
      @lj.moveElemIntoView elem, @lj.jots.jots_wrapper

  keyToFirstJotOrNew: =>
    if @lj.jots.jots_wrapper.find('li').length > 0
      @keyToFirstJot()

    else
      @keyToNewJot()

  keyToNextJotUp: =>
    if @lj.jots.jots_wrapper.find("li[data-keyed-over='true']").length > 0
      elem = @getKeyedOverElem()
      
      if elem.index() > 0
        @cur_pos = 'jot'
        @cur_pos_index = elem.index()
        @clearKeyedOverData()
        nextElem = elem.prev()
        nextElem.attr('data-keyed-over', 'true')
        @lj.moveElemIntoView nextElem, @lj.jots.jots_wrapper

      else
        @keyToLastJot()

  keyToNextJotDown: =>
    if @lj.jots.jots_wrapper.find("li.jot-item[data-keyed-over='true']").length > 0
      elem = @getKeyedOverElem()

     if elem.index() < @lj.jots.jots_wrapper.find('li.jot-item').length - 1
        @cur_pos = 'jot'
        @cur_pos_index = elem.index()
        @clearKeyedOverData()
        nextElem = elem.next()
        nextElem.attr('data-keyed-over', 'true')
        @lj.moveElemIntoView nextElem, @lj.jots.jots_wrapper

      else
        @lj.jots.ignore_this_key_down = true
        @keyToNewJot()

  keyToNewJot: =>
    @clearKeyedOverData()
    @lj.jots.determineFocusForNewJot()

  # keyToNewJotFromSearchOrTopic is special because it sets 
  # @lj.jots.ignore_this_key_down = true to fix the checklist
  # keydown bug, where it would skip two elems, due to the 
  # keydown/keyup event conflict
  keyToNewJotFromSearchOrTopic: =>
    @clearKeyedOverData()
    @lj.jots.ignore_this_key_down = true
    @lj.jots.determineFocusForNewJot()

  flagJotKeyedAt: =>
    id = $(@lj.jots.jots_wrapper.find("li[data-keyed-over='true']")[0]).attr('data-jot')
    @lj.jots.flagJot parseInt(id)

  editJotKeyedAt: =>
    id = $(@lj.jots.jots_wrapper.find("li[data-keyed-over='true']")[0]).attr('data-jot')
    @lj.jots.editJot parseInt(id)

  deleteJotKeyedAt: =>
    id = $(@lj.jots.jots_wrapper.find("li[data-keyed-over='true']")[0]).attr('data-jot')
    @lj.jots.deleteJot parseInt(id)
    @keyToNextJotUp()

  keyToCurrentTopic: =>
    @clearKeyedOverData()

    if @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder).length == 0
      @lj.topics.newTopic()
      return

    @lj.topics.topics_column.focus()

    elem = $(@lj.topics.topics_wrapper.find("li[data-topic='#{@lj.app.current_topic}']")[0])
    elem.attr('data-keyed-over', 'true')
    @lj.moveElemIntoView elem, @lj.topics.topics_wrapper

  keyToLastTopic: =>
    @clearKeyedOverData()
    @lj.topics.topics_column.focus()

    if @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder).length > 0
      elem = $(@lj.topics.topics_wrapper.find('li')[@lj.topics.topics_wrapper.find('li').length - 1])
      elem.attr('data-keyed-over', 'true')
      @curr_pos = 'jot'
      @curr_pos_index = @lj.topics.topics_wrapper.find('li').length - 1
      @openTopicKeyedTo()
      @lj.moveElemIntoView elem, @lj.topics.topics_wrapper

  keyToFirstTopic: =>
    @clearKeyedOverData()
    @lj.topics.topics_column.focus()

    if @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder).length > 0
      elem = $(@lj.topics.topics_wrapper.find('li:not(.new-topic-form-wrap)')[0])
      elem.attr('data-keyed-over', 'true')
      @curr_pos = 'topic'
      @cur_pos_index = 0
      @openTopicKeyedTo()
      @lj.moveElemIntoView elem, @lj.topics.topics_wrapper

    else
      @lj.topics.newTopic()

  keyToNextTopicUp: =>
    if @lj.topics.topics_wrapper.find("li[data-keyed-over='true']").length > 0
      elem = @getKeyedOverElem()
      
      if elem.index() > 1 # index 0 has new-form
        @cur_pos = 'topic'
        @cur_pos_index = elem.index()
        @clearKeyedOverData()
        nextElem = elem.prev()
        nextElem.attr('data-keyed-over', 'true')
        @lj.moveElemIntoView nextElem, @lj.topics.topics_wrapper
        @openTopicKeyedTo()

      else
        @keyToLastTopic()

  keyToNextTopicDown: =>
    if @lj.topics.topics_wrapper.find("li[data-keyed-over='true']").length > 0
      elem = @getKeyedOverElem()

     if elem.index() < @lj.topics.topics_wrapper.find('li').length - 1
        @cur_pos = 'topic'
        @cur_pos_index = elem.index()
        @clearKeyedOverData()
        nextElem = elem.next()
        nextElem.attr('data-keyed-over', 'true')
        @lj.moveElemIntoView nextElem, @lj.topics.topics_wrapper
        @openTopicKeyedTo()

      else
        @keyToFirstTopic()

  openTopicKeyedTo: =>
    elem = $(@lj.topics.topics_wrapper.find("li[data-keyed-over='true']")[0])
    @lj.topics.selectTopic elem.data('topic')

  keyToNewTopic: =>
    @lj.topics.newTopic()
    @lj.topics.topics_list.find('input#topic_title')[0].focus()

  editTopicKeyedAt: =>
    id = $(@lj.topics.topics_wrapper.find("li[data-keyed-over='true']")[0]).attr('data-topic')
    @lj.topics.editTopic parseInt(id)

  keyToCurrentFolder: =>
    if typeof @lj.app.current_folder == 'undefined'
      @lj.folders.new_folder_title.focus()
      return

    @lj.folders.folders_column.focus()

    @clearKeyedOverData()
    elem = $(@lj.folders.folders_wrapper.find("li[data-folder='#{@lj.app.current_folder}']")[0])
    elem.attr('data-keyed-over', 'true')
    @lj.moveElemIntoView elem, @lj.folders.folders_wrapper
    @openFolderKeyedTo()

  keyToLastFolder: =>
    @clearKeyedOverData()
    @lj.folders.folders_column.focus()

    if @lj.folders.folders_wrapper.find('li').length > 0
      elem = $(@lj.folders.folders_wrapper.find('li')[@lj.folders.folders_wrapper.find('li').length - 1])
      elem.attr('data-keyed-over', 'true')
      @curr_pos = 'jot'
      @curr_pos_index = @lj.folders.folders_wrapper.find('li').length - 1
      @lj.moveElemIntoView elem, @lj.folders.folders_wrapper
      @openFolderKeyedTo()

  keyToFirstFolder: =>
    @clearKeyedOverData()
    @lj.folders.folders_column.focus()

    if @lj.folders.folders_wrapper.find('li:not(.new-folder-form-wrap)').length > 0 #change this to use filter instead!
      elem = $(@lj.folders.folders_wrapper.find('li:not(.new-folder-form-wrap)')[0])
      elem.attr('data-keyed-over', 'true')
      @curr_pos = 'folder'
      @cur_pos_index = 0
      @lj.moveElemIntoView elem, @lj.folders.folders_wrapper
      @openFolderKeyedTo()

  keyToNextFolderUp: =>
    if @lj.folders.folders_wrapper.find("li[data-keyed-over='true']").length > 0
      elem = @getKeyedOverElem()
      
      if elem.index() > 1 # index 0 has new-form
        @cur_pos = 'folder'
        @cur_pos_index = elem.index()
        @clearKeyedOverData()
        nextElem = elem.prev('li:not(.new-folder-form-wrap)')
        nextElem.attr('data-keyed-over', 'true')
        @lj.moveElemIntoView nextElem, @lj.folders.folders_wrapper
        @openFolderKeyedTo()

      else
        @keyToLastFolder()
      @openFolderKeyedTo()

  keyToNextFolderDown: =>
    if @lj.folders.folders_wrapper.find("li[data-keyed-over='true']").length > 0
      elem = @getKeyedOverElem()

      if elem.index() < @lj.folders.folders_wrapper.find('li').length - 1
        @cur_pos = 'folder'
        @cur_pos_index = elem.index()
        @clearKeyedOverData()
        nextElem = elem.next()
        nextElem.attr('data-keyed-over', 'true')
        @lj.moveElemIntoView nextElem, @lj.folders.folders_wrapper
        @openFolderKeyedTo()

      else
        @keyToFirstFolder()

  keyToNewFolder: =>
    @lj.folders.newFolder()
    @lj.folders.folders_list.find('input#folder_title')[0].focus()

  openFolderKeyedTo: =>
    elem = $(@lj.folders.folders_wrapper.find("li[data-keyed-over='true']")[0])
    @lj.folders.selectFolder elem.data('folder')

  editFolderKeyedAt: =>
    id = $(@lj.folders.folders_wrapper.find("li[data-keyed-over='true']")[0]).attr('data-folder')
    @lj.folders.editFolder parseInt(id)

  keyToNewJotsTabs: =>
    @clearKeyedOverData()
    @lj.jots.new_jot_toolbar.focus()

    @lj.jots.new_jot_toolbar.find('li.active').attr('data-keyed-over', 'true')

  keyToLeftJotToolbarTab: =>
    if @lj.jots.new_jot_toolbar.find("li[data-keyed-over='true']").length > 0
      elem = @getKeyedOverElem()

      @cur_pos = 'jot_toolbar'
      @cur_pos_index = elem.index()
      @clearKeyedOverData()

      if elem.index() > 0
        nextElem = elem.prev()
      else
        @keyToLastJotToolbarTab()
        return

      nextElem.attr('data-keyed-over', 'true')
      @lj.jots.switchTab nextElem.data('tab')

  keyToRightJotToolbarTab: =>
    if @lj.jots.new_jot_toolbar.find("li[data-keyed-over='true']").length > 0
      elem = @getKeyedOverElem()

      @cur_pos = 'jot_toolbar'
      @cur_pos_index = elem.index()
      @clearKeyedOverData()

      if elem.index() < @lj.jots.new_jot_toolbar.find('li.tab').length - 1
        nextElem = elem.next()
      else
        @keyToFirstJotToolbarTab()
        return

      nextElem.attr('data-keyed-over', 'true')
      @lj.jots.switchTab nextElem.data('tab')

  keyToFirstJotToolbarTab: =>
    @clearKeyedOverData()

    elem = $(@lj.jots.new_jot_toolbar.find('li.tab').first())
    elem.attr('data-keyed-over', 'true')
    @curr_pos = 'jot_toolbar'
    @cur_pos_index = 0
    @lj.jots.switchTab elem.data('tab')

  keyToLastJotToolbarTab: =>
    @clearKeyedOverData()

    elem = $(@lj.jots.new_jot_toolbar.find('li.tab').last())
    elem.attr('data-keyed-over', 'true')
    @curr_pos = 'jot_toolbar'
    @cur_pos_index = 0
    @lj.jots.switchTab elem.data('tab')

  keyToNextNewJotListItemDown: =>
    checklist_value_input = @getKeyedOverElem()
    if checklist_value_input.length > 0
      li_elem = checklist_value_input.closest('li')
      checklist_value_input.attr('data-keyed-over', false)
      @cur_pos = 'jot_toolbar'
      @cur_pos_index = li_elem.index

      if li_elem.index() < @lj.jots.new_jot_checklist_tab.find('li:not(.template) input.checklist-value').length
        nextElem = li_elem.next().find('input.checklist-value')
        nextElem.attr('data-keyed-over', 'true').focus()
        @lj.moveElemIntoView nextElem, @lj.jots.new_jot_checklist_tab
      else
        @keyToNewJotsTabs()

  keyToNextNewJotListItemUp: =>
    checklist_value_input = @getKeyedOverElem()
    if checklist_value_input.length > 0
      li_elem = checklist_value_input.closest('li')

      if li_elem.index() > 1
        @cur_pos = 'jot_toolbar'
        @cur_pos_index = li_elem.index
        checklist_value_input.attr('data-keyed-over', false)
        nextElem = li_elem.prev().find('input.checklist-value')
        nextElem.attr('data-keyed-over', 'true').focus()
        @lj.moveElemIntoView nextElem, @lj.jots.new_jot_checklist_tab

      else
        @keyToLastJot()

  keyToLastNewJotListItem: =>
    elem = @lj.jots.new_jot_checklist_tab.find('li:not(.template)')
    elem.find('input.checklist-value').attr('data-keyed-over', 'true').focus()
    @lj.moveElemIntoView elem, @lj.jots.new_jot_checklist_tab
    
