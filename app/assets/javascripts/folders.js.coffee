#= require lightjot

class window.Folders extends LightJot
  constructor: (@lj) ->
    @initVars()
    @initDeleteFolderModalBinds()

  initVars: =>
    @folders_wrapper = $('#folders-wrapper')
    @folders_list = $('ul#folders-list')
    @new_folder_form_wrap = null
    @new_folder_title = null

  initDeleteFolderModalBinds: =>
    $('#delete-folder-modal').keydown (e) =>
      if e.keyCode == @lj.key_controls.key_codes.esc
        @cancelDeleteFolder

      else if e.keyCode == @lj.key_controls.key_codes.y
        id = $("li[data-keyed-over='true']").data('folder')
        @confirmDeleteFolder id

  buildFoldersList: =>
    @folders_list.html('')

    if (typeof @lj.app.current_folder == 'undefined' || @lj.app.current_folder == null) && @lj.app.folders.length > 0
      @lj.app.current_folder = @lj.app.folders[0].id

    @folders_list.prepend("#{$('#new-folder-template').html()}")
    @new_folder_form_wrap = @folders_wrapper.find('li.new-folder-form-wrap')
    @new_folder_title = @new_folder_form_wrap.find('input#folder_title')

    if @lj.app.folders.length > 0
      $.each @lj.app.folders, (index, folder) =>
        @insertFolderElem(folder)

        if @lj.app.current_folder == folder.id
          $("li[data-folder='#{folder.id}']").addClass('current')

      $.each @lj.app.folders, (index, folders) =>
        @initFolderBinds(folders.id)

      @sortFoldersList()

    else
      @showNewFolderForm()

    @initNewFolderListeners()

  insertFolderElem: (folder, append = true) =>
    build_html = "<li data-folder='#{folder.id}' data-editing='false'>
                    <span class='title'>#{folder.title}</span>
                    <div class='input-edit-wrap'>
                      <input type='text' class='input-edit' />
                    </div>
                    <i class='fa fa-pencil edit' data-edit />
                    <i class='fa fa-trash delete' data-delete />
                  </li>"

    if append
      @folders_list.append build_html
    else
      @new_folder_form_wrap.after build_html

  sortFoldersList: (sort_dom=true) =>
    offset_top = 0

    if @new_folder_form_wrap.is(':visible') && @new_folder_form_wrap.attr('data-hidden') == 'false'
      offset_top += @new_folder_form_wrap.outerHeight()

    $.each @lj.app.folders, (index, folder) =>
      # data-hidden is used on the new-topic li while it is being hidden but not quite !.is(:visible) yet
      folder_elem = @folders_list.find("li[data-folder='#{folder.id}']")

      if $(folder_elem).is(':visible') && $(folder_elem).attr('data-hidden') != 'true'
        $(folder_elem).css('top', offset_top).attr('data-sort', offset_top)
        height = $(folder_elem).outerHeight()
        offset_top += height

    if sort_dom
      setTimeout(() =>
        folder_elems = @lj.folders.folders_list.children('li')
        folder_elems.detach().sort (a, b) =>
          return parseInt($(a).attr('data-sort')) - parseInt($(b).attr('data-sort'))

        @lj.folders.folders_list.append(folder_elems)
      , 250)

  initFolderBinds: (folder_id) =>
    @folders_list.find("li:not(.new-folder-form-wrap)[data-folder='#{folder_id}']").click (e) =>
      @selectFolder($(e.currentTarget).data('folder'))

    @folders_list.find("li[data-folder='#{folder_id}'] [data-edit]").click (e) =>
      @editFolder(folder_id)
      return false

    @folders_list.find("li[data-folder='#{folder_id}'] .input-edit").click (e) =>
      return false

    @folders_list.find("li[data-folder='#{folder_id}'] [data-delete]").click (e) =>
      @deleteFolderPrompt e.currentTarget

  initNewFolderListeners: =>
    $('.new-folder-icon').mousedown (e) =>
      if !@new_folder_form_wrap.is(':visible') && @new_folder_form_wrap.attr('data-hidden') == 'true'
        e.preventDefault()
        @newFolder()
        @new_folder_title.focus() # dont like how there are two #folder_titles (from template)

    @new_folder_title.blur (e) =>
      folders_count = @lj.app.folders.length
      folder_title_length = @new_folder_title.val().trim().length

      if folders_count > 0 && folder_title_length == 0
        @hideNewFolderForm()

    $('form#new_folder').submit (e) =>
      e.preventDefault()
      @submitNewFolder()

  newFolder: =>
    @showNewFolderForm()
    @sortFoldersList false

  submitNewFolder: =>
    @lj.key_controls.clearKeyedOverData()
    folder_title = @new_folder_title

    unless folder_title.val().trim().length == 0
      folder_title.attr 'disabled', true

      $.ajax(
        type: 'POST'
        url: '/folders'
        data: "title=#{folder_title.val()}"
        success: (data) =>
          @lj.jots.endSearchState()
          @hideNewFolderForm()
          console.log data
          @pushFolderIntoData data.folder
          folder_title.attr 'disabled', false

          @lj.topics.newTopic()

        error: (data) =>
          console.log data
        )

    else
      @hideNewFolderForm()

  pushFolderIntoData: (folder) =>
    if @lj.app.folders.length == 0
      @lj.app.folders.push folder
    else
      @lj.app.folders.unshift folder

    @insertFolderElem folder, false
    @sortFoldersList()
    @selectFolder folder.id, true
    @initFolderBinds folder.id

  showNewFolderForm: =>
    @new_folder_form_wrap.show().attr('data-hidden', 'false')
    @new_folder_title.focus()

  hideNewFolderForm: =>
    @new_folder_form_wrap.attr('data-hidden', 'true').css('opacity', 0)

    @sortFoldersList()

    setTimeout(() =>
      @new_folder_form_wrap.hide().css({
        opacity: 1
      })

      @new_folder_title.val('')
    , 250)

  selectFolder: (folder_id, new_folder_init=false) =>
    if folder_id == @lj.app.current_folder
      return
      
    $("li[data-folder='#{@lj.app.current_folder}']").removeClass('current')
    elem = $("li[data-folder='#{folder_id}']")
    @lj.app.current_folder = folder_id
    elem.addClass('current')
    topics_count = @lj.app.topics.filter((topic) => topic.folder_id == folder_id).length

    @lj.topics.buildTopicsList()

    if topics_count == 0
      @lj.topics.newTopic false

  editFolder: (id) =>
    elem = $("li[data-folder='#{id}']")
    input = elem.find('input.input-edit')
    title = elem.find('.title')
    folder_object = @lj.app.folders.filter((folder) => folder.id == id)[0]
    input.val(title.html())
    elem.attr('data-editing', 'true')
    input.focus()

    submitted_edit = false

    input.blur (e) =>
      finishEditing()

    input.keydown (e) =>
      if e.keyCode == @lj.key_codes.enter
        e.preventDefault()
        finishEditing()

    finishEditing = =>
      if !submitted_edit
        submitted_edit = true
        folder_object.title = input.val()
        elem.attr('data-editing', 'false')
        title.html(input.val())
        @folders_wrapper.focus()

        $.ajax(
          type: 'PATCH'
          url: "/folders/#{id}"
          data: "title=#{input.val()}"

          success: (data) =>
            console.log data

          error: (data) =>
            console.log data
        )

  deleteFolderPrompt: (target) =>
    id = if typeof target != 'undefined' then id = $(target).closest('li').data('folder') else id = $("li[data-keyed-over='true']").data('folder')

    $('#delete-folder-modal').foundation 'reveal', 'open'
    $('#delete-folder-modal').html($('#delete-folder-modal-template').html()).attr('data-folder-id', id)

    $('#delete-folder-modal .cancel').click =>
      @cancelDeleteFolder()

    $('#delete-folder-modal .confirm').click =>
      @confirmDeleteFolder id

  confirmDeleteFolder: (id) =>
    $('#delete-folder-modal').foundation 'reveal', 'close'
    @folders_wrapper.focus()

    setTimeout(() =>
      @deleteFolder id
    , 250)

  cancelDeleteFolder: =>
    $('#delete-folder-modal').attr('data-folder-id', '').foundation 'reveal', 'close'
    @folders_wrapper.focus()

  deleteFolder: (id) =>
    elem = $("li[data-folder='#{id}']")
    elem.attr('data-deleting', 'true')

    $.ajax(
      type: 'POST'
      url: "/folders/#{id}"
      data: {'_method': 'delete'}

      success: (data) =>
        console.log data

      error: (data) =>
        console.log data
    )

    setTimeout(() =>
      folder_key = null
      $.each @lj.app.folders, (index, folder) =>
        if folder.id == id
          folder_key = index
          return false

      @lj.app.folders.remove(folder_key)
      elem.remove()
      @sortFoldersList false

      if @lj.app.folders.length > 0
        next_folder_elem = @folders_list.find('li:not(.new-folder-form-wrap)')[0]
        @selectFolder($(next_folder_elem).data('folder'))
      else
        @newFolder()

    , 350)

  moveCurrentFolderToTop: =>
    folder_key_to_move = null
    folder_object_to_move = null

    # find folder to move
    $.each @lj.app.folders, (index, folder) =>
      if folder.id == @lj.app.current_folder
        folder_key_to_move = index
        folder_object_to_move = folder
        return false

    # move folder being written in to top of list
    temp_list = $.extend([], @lj.app.folders)
    for i in [0...folder_key_to_move]
      temp_list[i+1] = @lj.app.folders[i]

    @lj.app.folders = $.extend([], temp_list)
    @lj.app.folders[0] = folder_object_to_move
    @lj.folders.sortFoldersList()
