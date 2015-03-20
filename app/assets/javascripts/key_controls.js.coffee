#= require lightjot

class window.KeyControls extends LightJot
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
      h: 72
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

    @key_nav.topics =
      left: @keyToCurrentFolder
      up: @keyToNextTopicUp
      down: @keyToNextTopicDown
      right: @keyToNewJot
      e: @editTopicKeyedAt
      n: @keyToNewTopic
      del: @lj.topics.deleteTopicPrompt

    @key_nav.jots =
      left: @keyToCurrentTopic
      up: @keyToNextJotUp
      down: @keyToNextJotDown
      right: null
      e: @editJotKeyedAt
      h: @flagJotKeyedAt
      n: @keyToNewJot
      del: @deleteJotKeyedAt
      s: @lj.jots.focusSearchInput

    @curr_pos = 'new_jot'
    @curr_pos_index = null


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
      is_editing = if @lj.jots.jots_wrapper.find("li[data-editing='true']").length > 0 then true else false

      if is_editing
        if e.keyCode == @key_codes.up || e.keyCode == @key_codes.down
          @getKeyedOverElem().find('input.input-edit')[0].blur()

        else
          return
      else
        e.preventDefault()

      if e.keyCode == @key_codes.up
        @key_nav.jots.up()

      if e.keyCode == @key_codes.down
        @key_nav.jots.down()

      if e.keyCode == @key_codes.left
        @key_nav.jots.left()

      if e.keyCode == @key_codes.e
        @key_nav.jots.e()

      if e.keyCode == @key_codes.h
        @key_nav.jots.h()

      if e.keyCode == @key_codes.n
        @key_nav.jots.n()

      if e.keyCode == @key_codes.del || e.keyCode == @key_codes.backspace
        @key_nav.jots.del()

      if e.keyCode == @key_codes.s
        @key_nav.jots.s()

    @lj.topics.topics_wrapper.keydown (e) =>
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

      if e.keyCode == @key_codes.up
        @key_nav.topics.up()

      if e.keyCode == @key_codes.down
        @key_nav.topics.down()

      if e.keyCode == @key_codes.left
        @key_nav.topics.left()

      if e.keyCode == @key_codes.e
        @key_nav.topics.e()
        
      if e.keyCode == @key_codes.right
        @key_nav.topics.right()

      if e.keyCode == @key_codes.n
        @key_nav.topics.n()

      if e.keyCode == @key_codes.del || e.keyCode == @key_codes.backspace
        @key_nav.topics.del()

    @lj.folders.folders_wrapper.keydown (e) =>
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

      if e.keyCode == @key_codes.up
        @key_nav.folders.up()

      if e.keyCode == @key_codes.down
        @key_nav.folders.down()
        
      if e.keyCode == @key_codes.right
        @key_nav.folders.right()

      if e.keyCode == @key_codes.e
        @key_nav.folders.e()

      if e.keyCode == @key_codes.n
        @key_nav.folders.n()

      if e.keyCode == @key_codes.del || e.keyCode == @key_codes.backspace
        @key_nav.folders.del()


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
    $('header a#keyboard-shortcuts-link').click =>
      @toggleKeyboardShortcutsHelp()

    $('#keyboard-shortcuts .default').show()

  clearKeyboardShortcutsPane: =>
    @curr_pos = null
    @switchKeyboardShortcutsPane()
    $('#keyboard-shortcuts .default').show()

  toggleKeyboardShortcutsHelp: =>
    keyboard_shortcuts_list = $('#keyboard-shortcuts')
    keyboard_shortcuts_link = $('header a#keyboard-shortcuts-link')
    help_is_visible = if keyboard_shortcuts_list.is(':visible') then true else false

    if help_is_visible
      keyboard_shortcuts_list.hide()
      keyboard_shortcuts_link.removeClass('active')

    else
      keyboard_shortcuts_list.show()
      keyboard_shortcuts_link.addClass('active')

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

    if @lj.jots.jots_wrapper.find('li').length > 0
      $(@lj.jots.jots_wrapper.find('li')[@lj.jots.jots_wrapper.find('li').length - 1]).attr('data-keyed-over', 'true')
      @curr_pos = 'jot'
      @curr_pos_index = @lj.jots.jots_wrapper.find('li').length - 1

  keyToFirstJot: =>
    @clearKeyedOverData()
    @lj.jots.jots_wrapper.focus()

    if @lj.jots.jots_wrapper.find('li').length > 0
      $(@lj.jots.jots_wrapper.find('li')[0]).attr('data-keyed-over', 'true')
      @curr_pos = 'jot'
      @cur_pos_index = 0

  keyToNextJotUp: =>
    if @lj.jots.jots_wrapper.find("li[data-keyed-over='true']").length > 0
      elem = @getKeyedOverElem()
      
      if elem.index() > 0
        @cur_pos = 'jot'
        @cur_pos_index = elem.index()
        @clearKeyedOverData()
        nextElem = elem.prev()
        nextElem.attr('data-keyed-over', 'true')

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

  keyToLastTopic: =>
    @clearKeyedOverData()
    @lj.topics.topics_wrapper.focus()

    if @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder).length > 0
      $(@lj.topics.topics_wrapper.find('li')[@lj.topics.topics_wrapper.find('li').length - 1]).attr('data-keyed-over', 'true')
      @curr_pos = 'jot'
      @curr_pos_index = @lj.topics.topics_wrapper.find('li').length - 1
      @openTopicKeyedTo()

  keyToFirstTopic: =>
    @clearKeyedOverData()
    @lj.topics.topics_wrapper.focus()

    if @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder).length > 0
      $(@lj.topics.topics_wrapper.find('li:not(.new-topic-form-wrap)')[0]).attr('data-keyed-over', 'true')
      @curr_pos = 'topic'
      @cur_pos_index = 0
      @openTopicKeyedTo()

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
    @openFolderKeyedTo()

  keyToLastFolder: =>
    @clearKeyedOverData()
    @lj.folders.folders_wrapper.focus()

    if @lj.folders.folders_wrapper.find('li').length > 0
      $(@lj.folders.folders_wrapper.find('li')[@lj.folders.folders_wrapper.find('li').length - 1]).attr('data-keyed-over', 'true')
      @curr_pos = 'jot'
      @curr_pos_index = @lj.folders.folders_wrapper.find('li').length - 1
      @openFolderKeyedTo()

  keyToFirstFolder: =>
    @clearKeyedOverData()
    @lj.folders.folders_wrapper.focus()

    if @lj.folders.folders_wrapper.find('li:not(.new-folder-form-wrap)').length > 0 #change this to use filter instead!
      $(@lj.folders.folders_wrapper.find('li:not(.new-folder-form-wrap)')[0]).attr('data-keyed-over', 'true')
      @curr_pos = 'folder'
      @cur_pos_index = 0
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
