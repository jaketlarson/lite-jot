#= require litejot

class window.Search extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @initSearchListeners()

  initVars: =>
    @search_wrapper = $('#search-wrapper')
    @search_input = $('input#search-input')
    @search_button = $('#search-button')

    @clicking_button = false
    @current_terms = ""

    # Offset the time the search will be carried out from the time
    # the search box is updated, to avoid lag and unnecessary processes.
    @offset_timer = null
    @offset_timing = 400

    @jots_in_search_results = [] # array of jot id's that will be checked in @lj.jots.buildJotsList()

  initSearchListeners: =>
    @search_input.focus (e) =>
      @search_button.addClass('input-has-focus')
      @search_wrapper.addClass('active')
      @clicking_button = false

      # Hide clock in fullscreen mode
      if @lj.fullscreen.is_fullscreen
        @lj.clock.hideClock()

    @search_input.blur (e) =>
      @search_button.removeClass('input-has-focus')
      if @search_input.val().trim().length == 0 && !@clicking_button
        @search_wrapper.removeClass('active')

      if @clicking_button
        @clicking_button = false

      # Show clock in fullscreen mode
      if @lj.fullscreen.is_fullscreen
        @lj.clock.showClock()

    @search_input.keyup (e) =>
      # Don't search if we're just moving the cursor
      if e.keyCode == @lj.key_controls.key_codes.left && @search_input.val().length > 0
        # Do nothing, but don't allow the KeyControls to consider this as UI navigation.
        e.stopImmediatePropagation()
      else if e.keyCode == @lj.key_controls.key_codes.right && @search_input.val().length > 0
        # Do nothing, but don't allow the KeyControls to consider this as UI navigation.
        e.stopImmediatePropagation()
      else
        @setSearchOffsetTimer()

    @search_button.click (e) =>
      @clicking_button = true

      if @search_input.val().trim().length > 0
        @endSearchState(false)
        @focusSearchInput()

        # if we don't rebuild jots list, it will be empty
        @lj.topics.buildTopicsList true
        @lj.jots.buildJotsList()
      else
        @focusSearchInput()

  setSearchOffsetTimer: =>
    if @offset_timer
      clearTimeout @offset_timer

    @offset_timer = setTimeout(() =>
      @handleSearchKeyUp()
    , @offset_timing)

  handleSearchKeyUp: => # needs optimization
    @current_terms = @search_input.val().trim()
    if @current_terms.length > 0
      @jots_in_search_results = []
      @restoreMasterData()
      @search_button.attr('data-searching', 'true')

      keyword = @search_input.val().trim()
      # Filter through jots, handling the special case of uploads, too.
      # Uploads are searchable if they have text within their jot.content.identified_text property.
      jot_results = @lj.app.jots.filter((jot) => 
        if jot.jot_type == 'upload'
          # Adding the ability for better search through image annotations by checking
          # terms split by spaces match annotations. This should be extended to other jot type soon.
          is_relevant = true
          $.each keyword.toLowerCase().split(' '), (keyword_index, term) =>
            # skip if this was determined to be an irrelevant jot
            if !is_relevant
              return

            relevant_annotations = JSON.parse(jot.content).annotations_info.filter((annotation) =>
              annotation.description.toLowerCase().indexOf(term) > -1
            )
            is_relevant = relevant_annotations.length > 0

          return is_relevant

        else
          return jot.content.toLowerCase().indexOf(keyword.toLowerCase()) > -1)

      folder_keys = []
      topic_keys = []

      # Check airplane mode-created jots
      $.each jot_results.slice(0).concat(@lj.airplane_mode.getStoredJotsObject()), (key, jot) =>
        # if searching: checklist jots are special, so they need an extra loop
        if @lj.search.current_terms.length > 0 & jot.jot_type == 'checklist'
          items = JSON.parse jot.content
          items_matched = 0
          $.each items, (index, item) =>
            if item.value.toLowerCase().indexOf(@lj.search.current_terms.toLowerCase()) > -1
              items_matched++
          if items_matched == 0
            return

        # if searching: upload jots are searchable, but we need to target their 'identified_text' property
        if @lj.search.current_terms.length > 0 & jot.jot_type == 'checklist'
          items = JSON.parse jot.content
          items_matched = 0
          $.each items, (index, item) =>
            if item.value.toLowerCase().indexOf(@lj.search.current_terms.toLowerCase()) > -1
              items_matched++
          if items_matched == 0
            return

        @jots_in_search_results.push jot.id

        if jot.topic_id not in topic_keys
          if jot.topic_id != null
            topic_keys.push jot.topic_id

            topic = @lj.app.topics.filter((topic) => topic.id == jot.topic_id)[0]
            if topic
              if topic.folder_id not in folder_keys
                if topic.folder_id != null
                  folder_keys.push topic.folder_id

      folder_results = []
      $.each folder_keys, (index, folder_key) =>
        folder_object = @lj.app.folders.filter((folder) => folder.id == folder_key)[0]
        if folder_object
          folder_results.push folder_object

      topic_results = []
      $.each topic_keys, (index, topic_key) =>
        topic_object = @lj.app.topics.filter((topic) => topic.id == topic_key)[0]
        if topic_object
          topic_results.push topic_object

      @lj.app.store_master_folders = $.extend [], @lj.app.folders
      @lj.app.store_master_topics = $.extend [], @lj.app.topics
      
      @lj.app.folders = $.extend [], folder_results
      @lj.app.topics = $.extend [], topic_results

      if folder_results.length > 0
        @lj.app.current_folder = folder_results[0].id

      if topic_results.length > 0
        @lj.app.current_topic = topic_results[0].id

      @lj.buildUI()
      @focusSearchInput()

    else
      @endSearchState()

  endSearchState: (organize_dom=true) =>
    if @search_button.attr('data-searching') == 'true'
      @search_button.attr 'data-searching', 'false'
      @search_input.val('')
      @restoreMasterData organize_dom

      if !@search_input.is(':focus')
        @search_wrapper.removeClass('active')

    @current_terms = ""
    @jots_in_search_results = []
    $('li[data-jot].highlighted').removeClass 'highlighted'
    @lj.jots.updateHeading()

  restoreMasterData: (organize_dom=true) => # for search functionality
    if typeof @lj.app.store_master_folders != "undefined" && @lj.app.store_master_folders != null
      @lj.app.folders = $.extend [], @lj.app.store_master_folders
      @lj.app.store_master_folders = null

    if typeof @lj.app.store_master_topics != "undefined" && @lj.app.store_master_topics != null
      @lj.app.topics = $.extend [], @lj.app.store_master_topics
      @lj.app.store_master_topics = null
    
    @lj.buildUI organize_dom

  focusSearchInput: =>
    @lj.key_controls.clearKeyedOverData()
    @search_input.focus()
