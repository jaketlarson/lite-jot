#= require lightjot

class window.KeyControls extends LightJot
  constructor: (@lj) ->
    @initVars()
    @initKeyBinds()

  initVars: =>
    @key_codes =
      enter: 13
      left: 37
      up: 38
      right: 39
      down: 40
      delete: 46
      h: 72
      n: 78

    # virtual architecture user is navigating w/ keyboard
    @key_nav = {}

    @key_nav.folders =
      left: null
      up: @keyToNextFolderUp
      down: @keyToNextFolderDown
      right: @keyToFirstTopic
      n: @keyToNewFolder

    @key_nav.topics =
      left: @keyToCurrentFolder
      up: @keyToNextTopicUp
      down: @keyToNextTopicDown
      right: @keyToNewJot
      n: @keyToNewTopic

    @key_nav.jots =
      left: @keyToCurrentTopic
      up: @keyToNextJotUp
      down: @keyToNextJotDown
      right: null
      h: @highlightJotKeyedAt
      n: @keyToNewJot


    @curr_pos = 'new-jot'
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

    @lj.jots.jots_wrapper.keydown (e) =>
      e.preventDefault()

      if e.keyCode == @key_codes.up
        @key_nav.jots.up()

      if e.keyCode == @key_codes.down
        @key_nav.jots.down()

      if e.keyCode == @key_codes.left
        @key_nav.jots.left()

      if e.keyCode == @key_codes.h
        @key_nav.jots.h()

      if e.keyCode == @key_codes.n
        @key_nav.jots.n()

    @lj.topics.topics_wrapper.keydown (e) =>
      if !@lj.topics.topics_list.find('form#new_topic #topic_title').is(':focus')
        e.preventDefault()

      if e.keyCode == @key_codes.up
        @key_nav.topics.up()

      if e.keyCode == @key_codes.down
        @key_nav.topics.down()

      if e.keyCode == @key_codes.left
        @key_nav.topics.left()
        
      if e.keyCode == @key_codes.right
        @key_nav.topics.right()

      if e.keyCode == @key_codes.n
        @key_nav.topics.n()

    @lj.folders.folders_wrapper.keydown (e) =>
      if !@lj.folders.folders_list.find('form#new_folder #folder_title').is(':focus')
        e.preventDefault()

      if e.keyCode == @key_codes.up
        @key_nav.folders.up()

      if e.keyCode == @key_codes.down
        @key_nav.folders.down()
        
      if e.keyCode == @key_codes.right
        @key_nav.folders.right()

      if e.keyCode == @key_codes.n
        @key_nav.folders.n()


  clearKeyedOverData: =>
    $("[data-keyed-over='true']").attr('data-keyed-over', 'false')

  getKeyedOverElem: =>
    return $($('html').find("li[data-keyed-over='true']")[0])

  keyToLastJot: =>
    @clearKeyedOverData()
    @lj.jots.jots_wrapper.focus()

    if @lj.jots.jots_wrapper.find('li').length > 0
      $(@lj.jots.jots_wrapper.find('li')[@lj.jots.jots_wrapper.find('li').length - 1]).attr('data-keyed-over', 'true')
      @curr_pos = 'jot'
      @curr_pos_index = @lj.jots.jots_wrapper.find('li').length - 1

  keyToFirstJot: =>
    @clearKeyedOverData()

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

  highlightJotKeyedAt: =>
    id = $(@lj.jots.jots_wrapper.find("li[data-keyed-over='true']")[0]).attr('data-jot')
    @lj.jots.highlightJot id

  keyToCurrentTopic: =>
    @clearKeyedOverData()

    if typeof @lj.app.current_topic == 'undefined'
      return

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

  keyToCurrentFolder: =>
    if typeof @lj.app.current_folder == 'undefined'
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
