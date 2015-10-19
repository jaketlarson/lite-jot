#= require litejot

class window.Folders extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @initScrollBind()
    @initDeleteFolderModalBinds()

  initVars: =>
    @folders_heading = $('h2#folders-heading')
    @folders_column = $('#folders-column')
    @folders_wrapper = $('#folders-wrapper')
    @folders_list = $('ul#folders-list')
    @new_folder_form_wrap = null
    @new_folder_title = null

  initScrollBind: =>
    @folders_wrapper.scroll =>
      @checkScrollPosition()

  checkScrollPosition: =>
    if @folders_wrapper.scrollTop() > 0
      @folders_heading.addClass('is-scrolled-from-top')
    else
      @folders_heading.removeClass('is-scrolled-from-top')

  initDeleteFolderModalBinds: =>
    $('#delete-folder-modal').keydown (e) =>
      if e.keyCode == @lj.key_controls.key_codes.esc
        @cancelDeleteFolder

      else if e.keyCode == @lj.key_controls.key_codes.y
        id = $("li[data-keyed-over='true']").data('folder')
        if !id
          # Backup method: find folder_id in a hidden field in the modal
          id = parseInt($(e.currentTarget).find('#folder_id').val())
        @confirmDeleteFolder id

  buildFoldersList: =>
    @folders_list.html('')

    if (typeof @lj.app.current_folder == 'undefined' || !@lj.app.current_folder || @lj.app.current_folder == null) && @lj.app.folders.length > 0
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
    if !folder.has_manage_permissions
      shared_icon_prefix = "<i class='fa fa-share-alt shared-icon-prefix'
                            title='Shared with you by #{folder.owner_display_name}<br />&amp;lt;#{folder.owner_email}&amp;gt;'>
                            </i>"
    else
      shared_icon_prefix = ""

    build_html = "<li data-folder='#{folder.id}' data-editing='false'>
                    #{shared_icon_prefix}
                    <span class='title'>#{folder.title}</span>
                    <div class='input-edit-wrap'>
                      <input type='text' class='input-edit' />
                    </div>"

    build_html += "<div class='options'>"
    if folder.has_manage_permissions
      build_html +="<i class='fa fa-share share' data-share title='Share folder' />
                    <i class='fa fa-pencil edit' data-edit title='Edit folder' />
                    <i class='fa fa-trash delete' data-delete title='Delete folder' />"
    else
      build_html += "<i class='fa fa-times unshare' data-unshare title='Stop sharing folder with me' />"
    
    build_html += "</div>
                  </li>"

    if append
      @folders_list.append build_html
    else
      @new_folder_form_wrap.after build_html

  updateFolderElem: (folder, append = true) =>
    elem = @folders_list.find("li[data-folder='#{folder.id}']")
    elem.find('.title').html folder.title

  sortFolderData: =>
    @lj.app.folders.sort((a, b) =>
      return b.updated_at_unix - a.updated_at_unix
    )

  sortFoldersList: (sort_dom=true, sort_folder_data_first=false) =>
    # sort_folder_data_first is called to make sure the folders are sorted
    # by last updated.. but this should not always be necessary.
    # Therefore, make it an option but not default.
    if sort_folder_data_first
      @sortFolderData()

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
        folder_elems = @lj.folders.folders_list.children('li:not(.new-folder-form-wrap)')
        folder_elems.detach().sort (a, b) =>
          return parseInt($(a).attr('data-sort')) - parseInt($(b).attr('data-sort'))

        @lj.folders.folders_list.append(folder_elems)
      , 250)

  initFolderBinds: (folder_id) =>
    @folders_list.find("li:not(.new-folder-form-wrap)[data-folder='#{folder_id}']").click (e) =>
      @lj.key_controls.clearKeyedOverData()
      @selectFolder($(e.currentTarget).data('folder'))

    @folders_list.find("li[data-folder='#{folder_id}'] [data-share]").click (e) =>
      new ShareSettings @lj, folder_id
      return false
    .cooltip({
      align: 'right'
    })

    @folders_list.find("li[data-folder='#{folder_id}'] .shared-icon-prefix")
    .cooltip({
      align: 'right'
    })

    @folders_list.find("li[data-folder='#{folder_id}'] [data-unshare]").click (e) =>
      @unshare folder_id, e.currentTarget
      return false
    .cooltip({
      align: 'right'
    })

    @folders_list.find("li[data-folder='#{folder_id}'] [data-edit]").click (e) =>
      @editFolder folder_id 
      return false
    .cooltip({
      align: 'right'
    })

    @folders_list.find("li[data-folder='#{folder_id}'] .input-edit").click (e) =>
      return false

    @folders_list.find("li[data-folder='#{folder_id}'] [data-delete]").click (e) =>
      @deleteFolderPrompt e.currentTarget
    .cooltip({
      align: 'right'
    })
    
  initNewFolderListeners: =>
    $('button.new-folder-button').mousedown (e) =>
      e.preventDefault()
      
      unless @new_folder_form_wrap.is(':visible') && @new_folder_form_wrap.attr('data-hidden') == 'true'
        @newFolder()

      @new_folder_title.focus() # dont like how there are two #folder_titles (from template)

    @new_folder_title.blur (e) =>
      folders_count = @lj.app.folders.length
      folder_title_length = @new_folder_title.val().trim().length

      if folders_count > 0 && folder_title_length == 0
        @hideNewFolderForm()

    .focus =>
      # Fixes auto-call to this function after creating new folder and still showing folder as keyed-over.
      @lj.key_controls.clearKeyedOverData()

    $('form#new_folder').submit (e) =>
      e.preventDefault()
      @submitNewFolder()

  newFolder: =>
    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return
      
    @showNewFolderForm()
    @sortFoldersList false

  submitNewFolder: =>
    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return

    @lj.key_controls.clearKeyedOverData()
    folder_title = @new_folder_title
    filtered_content = window.escapeHtml(folder_title.val())

    unless filtered_content.trim().length == 0
      folder_title.attr 'disabled', true

      @lj.connection.abortPossibleDataLoadXHR()
      $.ajax(
        type: 'POST'
        url: '/folders'
        data: "title=#{encodeURIComponent(filtered_content)}"
        success: (data) =>
          @lj.connection.startDataLoadTimer()
          @lj.search.endSearchState()
          @hideNewFolderForm()
          folder_title.attr 'disabled', false

          new HoverNotice(@lj, 'Folder created.', 'success')
          @pushFolderIntoData data.folder

          @lj.topics.newTopic()

        error: (data) =>
          @lj.connection.startDataLoadTimer()
          unless typeof data.responseJSON.error == 'undefined'
            new HoverNotice(@lj, data.responseJSON.error, 'error')
          else
            new HoverNotice(@lj, 'Could not create folder.', 'error')
        )

    else if @lj.app.folders.length > 0
      @lj.key_controls.keyToFirstFolder()
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
    if @new_folder_form_wrap.is(':visible')
      @new_folder_form_wrap.attr('data-hidden', 'true').css('opacity', 0)
      @sortFoldersList()

      setTimeout(() =>
        @new_folder_form_wrap.hide().css({
          opacity: 1
        })

        @new_folder_title.val('')
      , 250)

  selectFolder: (folder_id) =>
    if folder_id == @lj.app.current_folder
      return
      
    $("li[data-folder='#{@lj.app.current_folder}']").removeClass('current')
    elem = $("li[data-folder='#{folder_id}']")
    @lj.app.current_folder = folder_id
    elem.addClass('current').attr('data-keyed-over', true)
    topics_count = @lj.app.topics.filter((topic) => topic.folder_id == folder_id).length

    @lj.topics.buildTopicsList()

    if topics_count == 0
      @lj.topics.newTopic false

  editFolder: (id) =>
    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return

    elem = $("li[data-folder='#{id}']")
    input = elem.find('input.input-edit')
    title = elem.find('.title')
    folder_object = @lj.app.folders.filter((folder) => folder.id == id)[0]

    if !folder_object.has_manage_permissions
      new HoverNotice(@lj, 'You do not have permission to modify this folder.', 'error')
      return

    @lj.connection.abortPossibleDataLoadXHR()
    
    input.val(window.unescapeHtml(title.html()))
    elem.attr('data-editing', 'true')
    input.focus()

    submitted_edit = false

    input.blur (e) =>
      finishEditing()

    input.keydown (e) =>
      if e.keyCode == @lj.key_controls.key_codes.enter
        e.preventDefault()
        finishEditing()

    finishEditing = =>
      if !submitted_edit
        submitted_edit = true
        filtered_input = window.escapeHtml(input.val())
        elem.attr('data-editing', 'false')

        # return keyboard controls
        @folders_column.focus()

        is_changed = if folder_object.title != filtered_input then true else false
        if is_changed
          folder_object.title = filtered_input
          title.html(filtered_input)

          $.ajax(
            type: 'PATCH'
            url: "/folders/#{id}"
            data: "title=#{encodeURIComponent(filtered_input)}"

            success: (data) =>
              @lj.connection.startDataLoadTimer()
              new HoverNotice(@lj, 'Folder updated.', 'success')

            error: (data) =>
              @lj.connection.startDataLoadTimer()
              unless !data.responseJSON || typeof data.responseJSON.error == 'undefined'
                new HoverNotice(@lj, data.responseJSON.error, 'error')
              else
                new HoverNotice(@lj, 'Could not update folder.', 'error')
          )
        else
          @lj.connection.startDataLoadTimer()

  deleteFolderPrompt: (target) =>
    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return

    id = if typeof target != 'undefined' then id = $(target).closest('li').data('folder') else id = $("li[data-keyed-over='true']").data('folder')
    folder_object = @lj.app.folders.filter((folder) => folder.id == id)[0]

    if folder_object && !folder_object.has_manage_permissions
      new HoverNotice(@lj, 'You do not have permission to delete this folder.', 'error')
      return

    $('#delete-folder-modal').foundation 'reveal', 'open'
    $('#delete-folder-modal').html($('#delete-folder-modal-template').html()).attr('data-folder-id', id)

    $('#delete-folder-modal .cancel').click =>
      @cancelDeleteFolder()

    $('#delete-folder-modal .confirm').click =>
      @confirmDeleteFolder id

    # Focus on elem when shown.. using a timer for now
    # Hopefully a modal-shown callback will be available soon.
    setTimeout(() =>
      $('#delete-folder-modal').focus()
    , 250)

    # Set hidden folder id field of folder to delete in modal instance
    # This fixes the issue where a user could click the delete button,
    # but use the keyboard shortcut to confirm deletion.
    $('#delete-folder-modal #folder_id').val(id)

  confirmDeleteFolder: (id) =>
    $('#delete-folder-modal').foundation 'reveal', 'close'

    # return keyboard controls
    @folders_column.focus()

    setTimeout(() =>
      @deleteFolder id
    , 250)

  cancelDeleteFolder: =>
    $('#delete-folder-modal').attr('data-folder-id', '').foundation 'reveal', 'close'
    @folders_wrapper.focus()

  deleteFolder: (id) =>
    elem = $("li[data-folder='#{id}']")
    elem.attr('data-deleting', 'true')

    @lj.connection.abortPossibleDataLoadXHR()
    $.ajax(
      type: 'POST'
      url: "/folders/#{id}"
      data: {'_method': 'delete'}

      success: (data) =>
        @lj.connection.startDataLoadTimer()
        new HoverNotice(@lj, data.message, 'success')
        @vanish id

      error: (data) =>
        @lj.connection.startDataLoadTimer()
        elem.attr('data-deleting', false)
        unless typeof data.responseJSON.error == 'undefined'
          new HoverNotice(@lj, data.responseJSON.error, 'error')
        else
          new HoverNotice(@lj, 'Could not delete folder.', 'error')
    )

  vanish: (id) =>
    # Handles the real deleting
    elem = $("li[data-folder='#{id}']")
    elem.attr('data-deleted', 'true')

    @removeFolderFromDataById id

    if @lj.app.folders.length > 0
      if elem.prev('li[data-folder]').length > 0
        next_folder_elem = elem.prev('li[data-folder]')
      else
        next_folder_elem = elem.next('li[data-folder]')
      @selectFolder($(next_folder_elem).data('folder'))

    else # they deleted the last folder
      @lj.app.current_folder = null
      @newFolder()
      @lj.topics.buildTopicsList() # will render empty topics/jots

    @sortFoldersList false

    # Wait for animation
    setTimeout(() =>
      elem.remove()
    , 350)

  removeFolderFromDataById: (id) =>
    folder_key = null
    $.each @lj.app.folders, (index, folder) =>
      if folder.id == id
        folder_key = index
        return false
    @lj.app.folders.remove folder_key
    @lj.topics.removeTopicsInFolderFromData id

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

  unshare: (folder_id, share_icon_target) =>
    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return

    elem = $("li[data-folder='#{folder_id}']")
    elem.attr('data-deleting', 'true')
    share_id = @lj.app.folders.filter((folder) => folder.id == folder_id)[0].share_id

    @lj.connection.abortPossibleDataLoadXHR()
    $.ajax(
      type: 'POST'
      url: "/shares/#{share_id}"
      data: {'_method': 'delete'}

      success: (data) =>
        @lj.connection.startDataLoadTimer()
        new HoverNotice(@lj, data.message, 'success')
        @vanish folder_id
        $(share_icon_target).cooltip('destroy')

      error: (data) =>
        @lj.connection.startDataLoadTimer()
        elem.attr('data-deleting', false)
        unless !data.responseJSON || typeof data.responseJSON.error == 'undefined'
          new HoverNotice(@lj, data.responseJSON.error, 'error')
        else
          new HoverNotice(@lj, 'Could not remove shared folder.', 'error')
    )
