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

    # virtual architecture user is navigating w/ keyboard
    @key_nav = {}

    @key_nav.folders =
      left: null
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
      right: @keyToNewJot
      e: @editTopicKeyedAt
      n: @keyToNewTopic
      del: @lj.topics.deleteTopicPrompt
      backspace: @lj.topics.deleteTopicPrompt

    @key_nav.jots =
      left: @keyToCurrentTopic
      up: @keyToNextJotUp
      down: @keyToNextJotDown
      right: null
      e: @editJotKeyedAt
      f: @flagJotKeyedAt
      n: @keyToNewJot
      del: @deleteJotKeyedAt
      backspace: @deleteJotKeyedAt
      s: @lj.jots.focusSearchInput

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
    @lj.jots.new_jot_content.keydown (e) =>
      jots_count = @lj.app.jots.filter((jot) => jot.topic_id == @lj.app.current_topic).length
      if e.keyCode == @key_codes.up && $(e.currentTarget).val().trim().length == 0 && jots_count > 0
        $(e.currentTarget).blur()
        @keyToLastJot()

      if e.keyCode == @key_codes.left && $(e.currentTarget).val().trim().length == 0
        $(e.currentTarget).blur()
        @keyToCurrentTopic()

    @lj.jots.search_input.keydown (e) =>
      if e.keyCode == @key_codes.down
        @keyToFirstJot()

      if e.keyCode == @key_codes.esc
        @lj.jots.endSearchState()

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

    @lj.topics.topics_wrapper.keydown (e) =>
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

    @lj.folders.folders_wrapper.keydown (e) =>
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

    @lj.folders.folders_wrapper.focus (e) =>
      @curr_pos = 'folders'
      @switchKeyboardShortcutsPane()

    @lj.topics.topics_wrapper.focus (e) =>
      @curr_pos = 'topics'
      @switchKeyboardShortcutsPane()

    @lj.jots.jots_wrapper.focus (e) =>
      @curr_pos = 'jots'
      @switchKeyboardShortcutsPane()

    @lj.jots.new_jot_content.focus (e) =>
      @curr_pos = 'new_jot'
      @switchKeyboardShortcutsPane()
      @clearKeyedOverData() # may need a better way

    @lj.jots.search_input.focus (e) =>
      @curr_pos = 'search_jots'
      @switchKeyboardShortcutsPane()

    @lj.folders.folders_wrapper.blur (e) =>
      @clearKeyboardShortcutsPane()
      #@clearKeyedOverData()

    @lj.topics.topics_wrapper.blur (e) =>
      @clearKeyboardShortcutsPane()
      #@clearKeyedOverData()

    @lj.jots.jots_wrapper.blur (e) =>
      @clearKeyboardShortcutsPane()
      #@clearKeyedOverData()

    @lj.jots.new_jot_content.blur (e) =>
      @clearKeyboardShortcutsPane()
      #@clearKeyedOverData()

    @lj.jots.search_input.blur (e) =>
      @clearKeyboardShortcutsPane()
      #@clearKeyedOverData()

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
          console.log data

        error: (data) =>
          console.log data
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
          console.log data

        error: (data) =>
          console.log data
      )

    @lj.sizeUI()

  switchKeyboardShortcutsPane: =>
    panes = 
      folders: '#keyboard-shortcuts #folder-keys'
      topics: '#keyboard-shortcuts #topic-keys'
      jots: '#keyboard-shortcuts #jot-keys'
      new_jot: '#keyboard-shortcuts #new_jot-keys'
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
    return $($('html').find("li[data-keyed-over='true']")[0])

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

    if @lj.jots.jots_wrapper.find('li').length > 0
      elem = $(@lj.jots.jots_wrapper.find('li')[@lj.jots.jots_wrapper.find('li').length - 1])
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
    if @lj.jots.jots_wrapper.find("li[data-keyed-over='true']").length > 0
      elem = @getKeyedOverElem()

     if elem.index() < @lj.jots.jots_wrapper.find('li').length - 1
        @cur_pos = 'jot'
        @cur_pos_index = elem.index()
        @clearKeyedOverData()
        nextElem = elem.next()
        nextElem.attr('data-keyed-over', 'true')
        @lj.moveElemIntoView nextElem, @lj.jots.jots_wrapper

      else
        @keyToNewJot()

  keyToNewJot: =>
    @clearKeyedOverData()
    @lj.jots.new_jot_content.focus()

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

    @lj.topics.topics_wrapper.focus()

    elem = $(@lj.topics.topics_wrapper.find("li[data-topic='#{@lj.app.current_topic}']")[0])
    elem.attr('data-keyed-over', 'true')
    @lj.moveElemIntoView elem, @lj.topics.topics_wrapper

  keyToLastTopic: =>
    @clearKeyedOverData()
    @lj.topics.topics_wrapper.focus()

    if @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder).length > 0
      elem = $(@lj.topics.topics_wrapper.find('li')[@lj.topics.topics_wrapper.find('li').length - 1])
      elem.attr('data-keyed-over', 'true')
      @curr_pos = 'jot'
      @curr_pos_index = @lj.topics.topics_wrapper.find('li').length - 1
      @openTopicKeyedTo()
      @lj.moveElemIntoView elem, @lj.topics.topics_wrapper

  keyToFirstTopic: =>
    @clearKeyedOverData()
    @lj.topics.topics_wrapper.focus()

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

    @lj.folders.folders_wrapper.focus()

    @clearKeyedOverData()
    elem = $(@lj.folders.folders_wrapper.find("li[data-folder='#{@lj.app.current_folder}']")[0])
    elem.attr('data-keyed-over', 'true')
    @lj.moveElemIntoView elem, @lj.folders.folders_wrapper
    @openFolderKeyedTo()

  keyToLastFolder: =>
    @clearKeyedOverData()
    @lj.folders.folders_wrapper.focus()

    if @lj.folders.folders_wrapper.find('li').length > 0
      elem = $(@lj.folders.folders_wrapper.find('li')[@lj.folders.folders_wrapper.find('li').length - 1])
      elem.attr('data-keyed-over', 'true')
      @curr_pos = 'jot'
      @curr_pos_index = @lj.folders.folders_wrapper.find('li').length - 1
      @lj.moveElemIntoView elem, @lj.folders.folders_wrapper
      @openFolderKeyedTo()

  keyToFirstFolder: =>
    @clearKeyedOverData()
    @lj.folders.folders_wrapper.focus()

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
