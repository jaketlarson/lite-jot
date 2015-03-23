#= require lightjot

class window.Jots extends LightJot
  constructor: (@lj) ->
    @initVars()
    @initJotFormListeners()
    @initSearchListeners()

  initVars: =>
    @new_jot_form = $('form#new_jot')
    @new_jot_content = @new_jot_form.find('textarea#jot_content')
    @jots_wrapper = $('#jots-wrapper')
    @jots_list = @jots_wrapper.find('ul#jots-list')
    @jot_temp_entry_template = $('#jot-temp-entry-template')
    @jots_empty_message_elem = @jots_wrapper.find('.empty-message')
    @jots_loading_icon = @jots_wrapper.find('i.loading')
    @search_input = $('input#search-input')
    @search_button = $('#search-button')

  clearJotsList: =>
    @jots_list.html('')

  buildJotsList: =>
    @clearJotsList()
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
      if @new_jot_content.attr('data-editing') != 'true'
        @submitNewJot()

    @new_jot_content.keydown (e) =>
      if e.keyCode == @lj.key_codes.enter && !e.shiftKey # enter key w/o shift key means submission
        e.preventDefault()
        @new_jot_form.submit()

  initSearchListeners: =>
    @search_input.focus (e) =>
      @search_button.addClass('input-has-focus')

    @search_input.blur (e) =>
      @search_button.removeClass('input-has-focus')

    @search_input.keyup (e) =>
      @handleSearchKeyUp()

    @search_button.click (e) =>
      if @search_input.val().trim().length > 0
        @endSearchState()
        @focusSearchInput()
      else
        @focusSearchInput()

  handleSearchKeyUp: => # needs optimization
    if @search_input.val().trim().length > 0
      @restoreMasterData()
      @search_button.attr('data-searching', 'true')

      keyword = @search_input.val().trim()
      jot_results = @lj.app.jots.filter((jot) => jot.content.toLowerCase().search(keyword.toLowerCase()) > -1).reverse()
      folder_keys = []
      topic_keys = []

      $.each jot_results, (key, jot) =>
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

  submitNewJot: =>
    content = @new_jot_content.val()

    if content.trim().length > 0
      @endSearchState false

      key = @randomKey()
      @insertTempJotElem content, key
      @jots_empty_message_elem.hide()
      @scrollJotsToBottom()

      $.ajax(
        type: 'POST'
        url: @new_jot_form.attr('action')
        data: "content=#{content}&folder_id=#{@lj.app.current_folder}&topic_id=#{@lj.app.current_topic}"
        success: (data) =>
          @lj.app.jots.push data.jot
          @integrateTempJot data.jot, key
          console.log data.jot

          if typeof @lj.app.current_folder == 'undefined' && typeof data.auto_folder != 'undefined'
            @lj.folders.hideNewFolderForm()
            @lj.folders.pushFolderIntoData data.auto_folder

          if typeof @lj.app.current_topic == 'undefined' && typeof data.auto_topic != 'undefined'
            @lj.topics.hideNewTopicForm()
            @lj.topics.pushTopicIntoData data.auto_topic

        error: (xhr, textStatus, errorThrown) =>

          if textStatus == 'timeout' # test this 
            console.log 'retrying!'
            $.ajax(this)
            return

          if xhr.status == 500
            # add error handling

          else
            # add error handling

      )

      if @lj.app.folders.length > 1
        @lj.folders.moveCurrentFolderToTop()

      if @lj.app.topics.filter((topic) => topic.folder_id == @lj.app.current_folder).length > 1
        @lj.topics.moveCurrentTopicToTop()

      # reset new jot form
      @clearJotEntryTemplate()
      @new_jot_content.val('')

  insertTempJotElem: (content, key) =>
    content = @new_jot_content.val().replace /\n/g, '<br />'
    @jot_temp_entry_template.find('li')
    .attr('id', key).append("<div class='content'>#{content}</div>")
    .attr("data-before-content", "\uf141")
    .attr("title", "submitting jot...")

    build_entry = @jot_temp_entry_template.html()

    @jots_list.append build_entry

  integrateTempJot: (jot, key) =>
    elem = @jots_list.find("##{key}")
    elem.removeClass('temp').attr('data-jot', jot.id)

    to_insert = "<i class='fa fa-flag flag' />
                <i class='fa fa-trash delete' />
                <div class='input-edit-wrap'>
                  <input type='text' class='input-edit' />
                </div>"

    elem.append to_insert
    @setTimestamp jot
    @initJotBinds jot.id

  insertJotElem: (jot) =>
    flagged_class = if jot.is_flagged then 'flagged' else ''
    jot_content = jot.content.replace /\n/g, '<br />'

    @jots_list.append("<li data-jot='#{jot.id}' class='#{flagged_class}'>
                        <i class='fa fa-flag flag' />
                        <i class='fa fa-trash delete' />
                        <div class='content'>
                          #{jot_content}
                        </div>
                        <div class='input-edit-wrap'>
                          <input type='text' class='input-edit' />
                        </div>
                      </li>")

    @setTimestamp jot
    @initJotBinds jot.id

  setTimestamp: (jot) =>
    elem = @jots_list.find("[data-jot='#{jot.id}']")[0]
    $(elem).attr("data-before-content", "#{jot.created_at_short}")
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
      @editJot(jot_id)
      return false

    @jots_list.find("li[data-jot='#{jot_id}'] i.flag").click (e) =>
      e.stopPropagation()
      @flagJot jot_id

    @jots_list.find("li[data-jot='#{jot_id}'] i.delete").click (e) =>
      e.stopPropagation()
      @deleteJot jot_id

  flagJot: (id) =>
    elem = $("li[data-jot='#{id}']")
    is_flagged = elem.hasClass('flagged') ? true : false
    jot_object = @lj.app.jots.filter((jot) => jot.id == id)[0]

    unless is_flagged
      jot_object.is_flagged = true
      elem.addClass('flagged')

    else
      jot_object.is_flagged = false
      elem.removeClass('flagged')

    is_flagged = !is_flagged
    $.ajax(
      type: 'PATCH'
      url: "/jots/#{id}"
      data: "is_flagged=#{is_flagged}"

      success: (data) =>
        console.log data

      error: (data) =>
        console.log data
    )


  editJot: (id) =>
    elem = $("li[data-jot='#{id}']")
    content_elem = elem.find('.content')
    jot_object = @lj.app.jots.filter((jot) => jot.id == id)[0]
    raw_content = jot_object.content
    submitted_edit = false

    $('body').append("<div id='edit-overlay'><h1>Editing Jot</h1></div>")
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
        updated_content = @new_jot_content.val()
        jot_object.content = updated_content #doing this here in case they switch topics before ajax complete
        
        $('#edit-overlay').remove()
        @new_jot_content.val('').attr('data-editing', 'false')
        elem.attr('data-editing', 'false')
        content_elem.html(updated_content)
        @jots_wrapper.focus()

        # only update folder/topic order & send server request if the user
        # changed the content field of the jot
        if updated_content != raw_content
          @lj.folders.moveCurrentFolderToTop()
          @lj.topics.moveCurrentTopicToTop()

          $.ajax(
            type: 'PATCH'
            url: "/jots/#{id}"
            data: "content=#{updated_content}"

            success: (data) =>
              jot_object.content = data.content
              jot_object.created_at_long = data.created_at_long
              jot_object.created_at_short = data.created_at_short
              jot_object.updated_at = data.updated_at
              @setTimestamp jot_object

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