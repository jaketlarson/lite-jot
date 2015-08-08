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

  initSearchListeners: =>
    @search_input.focus (e) =>
      @search_button.addClass('input-has-focus')
      @search_wrapper.addClass('active')

    @search_input.blur (e) =>
      @search_button.removeClass('input-has-focus')
      if @search_input.val().length == 0 && !@clicking_button
        @search_wrapper.removeClass('active')

      if @clicking_button
        @clicking_button = false

    @search_input.keyup (e) =>
      @handleSearchKeyUp()

    @search_button.click (e) =>
      @clicking_button = true

      if @search_input.val().trim().length > 0
        @endSearchState()
        @focusSearchInput()
      else
        @focusSearchInput()


  handleSearchKeyUp: => # needs optimization
    if @search_input.val().trim().length > 0
      @jots_in_search_results = []
      @restoreMasterData()
      @search_button.attr('data-searching', 'true')

      keyword = @search_input.val().trim()
      jot_results = @lj.app.jots.filter((jot) => jot.content.toLowerCase().search(keyword.toLowerCase()) > -1).reverse()
      folder_keys = []
      topic_keys = []

      $.each jot_results, (key, jot) =>
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

      @search_wrapper.removeClass('active')

    @jots_in_search_results = []
    $('li[data-jot].highlighted').removeClass('highlighted')

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
