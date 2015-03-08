#= require lightjot

class window.Folders extends LightJot
  constructor: (@lj) ->
    @initVars()

  initVars: =>
    @folders_wrapper = $('#folders-wrapper')
    @folders_list = $('ul#folders-list')

  buildFoldersList: =>
    @folders_list.html('')

    if typeof @lj.app.current_folder == 'undefined' && @lj.app.folders.length > 0
      @lj.app.current_folder = @lj.app.folders[0].id

    @folders_list.prepend("#{$('#new-folder-template').html()}")
    $.each @lj.app.folders, (index, folder) =>
      @insertFolderElem(folder)

      if @lj.app.current_folder == folder.id
        $("li[data-folder='#{folder.id}']").addClass('current')

    $.each @lj.app.folders, (index, folders) =>
      @initFolderBinds(folders.id)

    @sortFoldersList()
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
      @folders_list.find('.new-folder-form-wrap').after build_html

  sortFoldersList: (sort_dom=true) =>
    offset_top = 0

    if @folders_list.find('li.new-folder-form-wrap').is(':visible') && @folders_list.find('li.new-folder-form-wrap').attr('data-hidden') == 'false'
      offset_top += @folders_list.find('li.new-folder-form-wrap').outerHeight()

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

    @folders_list.find("li[data-folder='#{folder_id}'] [data-delete]").click (e1) =>
      $('#delete-folder-modal').foundation 'reveal', 'open'
      $('#delete-folder-modal').html($('#delete-folder-modal-template').html())

      $('#delete-folder-modal .cancel').click (e2) ->
        $('#delete-folder-modal').foundation 'reveal', 'close'

      $('#delete-folder-modal .confirm').click (e2) =>
        id = $(e1.currentTarget).closest('li').data('folder')

        $('#delete-folder-modal').foundation 'reveal', 'close'

        setTimeout(() =>
          @deleteFolder(id)
        , 250)

  initNewFolderListeners: =>
    $('.new-folder-icon').mousedown (e) =>
      if !@folders_list.find('li.new-folders-form-wrap').is(':visible') && @folders_list.find('li.new-folder-form-wrap').attr('data-hidden') == 'true'
        e.preventDefault()
        @newFolder()
        @folders_list.find('input#folder_title').focus() # dont like how there are two #folder_titles (from template)

    @folders_list.find('input#folder_title').blur (e) =>
      if @folders_list.find('form#new_folder #folder_title').val().trim().length == 0
        @hideNewFolderForm()

    $('form#new_folder').submit (e) =>
      e.preventDefault()
      @submitNewFolder()

  newFolder: =>
    @showNewFolderForm()
    @sortFoldersList false

  submitNewFolder: =>
    folder_title = @folders_list.find('form#new_folder #folder_title')
    unless folder_title.val().trim().length == 0
      folder_title.attr 'disabled', true

      $.ajax(
        type: 'POST'
        url: '/folders'
        data: "title=#{folder_title.val()}"
        success: (data) =>
          @hideNewFolderForm()
          console.log data
          if @lj.app.folders.length == 0
            @lj.app.folders.push data.folder
          else
            @lj.app.folders.unshift data.folder

          @insertFolderElem data.folder, false
          @sortFoldersList()
          @selectFolder(data.folder.id)
          @initFolderBinds(data.folder.id)
          folder_title.attr 'disabled', false

        error: (data) =>
          console.log data
        )

    else
      @hideNewFolderForm()

  showNewFolderForm: =>
    @folders_list.find('li.new-folder-form-wrap').show().attr('data-hidden', 'false')

  hideNewFolderForm: =>
    @folders_list.find('li.new-folder-form-wrap').attr('data-hidden', 'true').css('opacity', 0)

    @sortFoldersList()

    setTimeout(() =>
      @folders_list.find('li.new-folder-form-wrap').hide().css({
        opacity: 1
      })

      @folders_list.find('form#new_folder #folder_title').val('')
    , 250)

  selectFolder: (folder_id) =>
    $("li[data-folder='#{@lj.app.current_folder}']").removeClass('current')
    elem = $("li[data-folder='#{folder_id}']")
    @lj.app.current_folder = folder_id
    elem.addClass('current')

    @lj.topics.buildTopicsList()

  editFolder: (id) =>
    elem = $("li[data-folder='#{id}']")
    input = elem.find('input.input-edit')
    title = elem.find('.title')
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
        elem.attr('data-editing', 'false')
        title.html(input.val())
        @lj.jots.new_jot_content.focus()

        $.ajax(
          type: 'PATCH'
          url: "/folders/#{id}"
          data: "title=#{input.val()}"

          success: (data) =>
            console.log data

          error: (data) =>
            console.log data
        )

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
      @sortFoldersList()

      next_folder_elem = @folders_list.find('li:not(.new-folder-form-wrap)')[0]
      @selectFolder($(next_folder_elem).data('folder'))

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
