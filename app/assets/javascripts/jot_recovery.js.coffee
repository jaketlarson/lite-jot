#= require litejot

# Important note:
# Jot Recovery module does not directly restore elements back into the
# UI. It takes advantage of the eventual live-reload process that will
# scan through and handle it correctly. DRY.

class window.JotRecovery extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @initOpenBind()

  initVars: =>
    @modal = $('#jot-recovery-modal')
    @modal_link = $('nav a#jot-recovery-modal-link')
    @modal_template = $('#jot-recovery-modal-template')

  initInstanceVars: =>
    @loader = @modal.find('.loader')
    @try_again_wrap = @modal.find('.try-again-wrap')
    @try_again_trigger = @modal.find('a.try-again')
    @modal_info = @modal.find('.modal-info')
    @empty_wrap = @modal.find('.empty-wrap')
    @item_table = @modal.find('table.archived-jots-table')
    @item_template = @modal.find('.item-template')

    @primary_action_buttons_wrap = @modal.find('.primary-action-buttons-wrap')
    @delete_button = @modal.find('button.delete-selected')
    @restore_button = @modal.find('button.restore-selected')
    @delete_confirmation_wrap = @modal.find('.delete-confirmation-wrap')
    @check_all_checkbox = @item_table.find("input:checkbox#check-all-archived-jots")

    @xhr_waiting = false

  initCloseBind: =>
    @modal.find('.cancel').click =>
      @modal.foundation 'reveal', 'close'

  initOpenBind: =>
    @modal_link.click =>
      if @lj.emergency_mode.active
        @lj.emergency_mode.feature_unavailable_notice()
        return

      @modal.foundation 'reveal', 'open'
      @modal.html @modal_template.html()
      @initInstance()

  initTryAgainBind: =>
    @try_again_trigger.click =>
      @loadJots()

  initInfoTooltip: =>
    @modal_info.cooltip({
      direction: 'right'
      align: 'bottom'
    })

  initCheckAllBind: =>
    @check_all_checkbox.change (e) =>
      elem = $(e.currentTarget)
      if elem.prop 'checked'
        @checkAll()
      else
        @uncheckAll()

  initActionButtonBinds: =>
    @restore_button.click =>
      @restoreSelected()

    @delete_button.click =>
      @showDeleteConfirmation()

    @delete_confirmation_wrap.find('a.confirm-delete').click =>
      @hideDeleteConfirmation()
      @deleteSelected()

    @delete_confirmation_wrap.find('a.cancel-delete').click =>
      @hideDeleteConfirmation()

  initInstance: =>
    @initInstanceVars()
    @initCloseBind()
    @initTryAgainBind()
    @loadJots()
    @initInfoTooltip()
    @initCheckAllBind()
    @initActionButtonBinds()

  loadJots: =>
    @loader.show()
    @try_again_wrap.hide()

    $.ajax(
      type: 'GET'
      url: '/archived_jots'
      success: (data) =>
        @loader.hide()
        if data.archived_jots.length == 0
          @empty_wrap.show()
          @item_table.hide()

        else
          @buildList data.archived_jots
          @item_table.show()

      error: (data) =>
        @loader.hide()
        @try_again_wrap.show()
        console.log data
    )

  buildList: (items) =>
    $.each items, (index, item) =>
      elem = $("<tr data-archived-jot='#{item.id}'>#{@item_template.html()}</tr>")
      elem.find('.folder-title').html item.folder_title
      elem.find('.topic-title').html item.topic_title

      if item.jot_type == 'checklist'
        content = @lj.jots.parseCheckListToHTML item.content, disabled=true
        elem.find('.content').addClass 'checklist'
      else if item.jot_type == 'heading'
        elem.find('.content').addClass 'heading'
        content = item.content
      else
        content = item.content

      elem.find('.content').html content
      elem.appendTo @item_table.find('tbody')

      @initItemBind item.id

  initItemBind: (id) =>
    $("tr[data-archived-jot='#{id}']").click (e) =>
      if $(e.target).prop('tagName') != 'INPUT'
        elem = $("tr[data-archived-jot='#{id}']")
        checkbox = elem.find(".recovery-checkbox-wrap input:checkbox")
        checkbox.prop 'checked', !checkbox.prop('checked')

      @updateCheckedCounts()

  checkboxCheckedCount: =>
    @item_table.find("tbody tr:not(.item-template) .recovery-checkbox-wrap input:checkbox:checked").length

  updateCheckedCounts: =>
    count = @checkboxCheckedCount()

    @delete_button.find('.selected-count').html count
    @restore_button.find('.selected-count').html count

    if count == 0
      @delete_button.prop 'disabled', true
      @restore_button.prop 'disabled', true
    else
      @delete_button.prop 'disabled', false
      @restore_button.prop 'disabled', false

    # Depending on checkbox:checked counts, handle
    # automatic "check all" checkbox checked/unchecked status.
    # Start by comparing checked count to number of checkboxes
    if count == @item_table.find("tbody tr:not(.item-template) .recovery-checkbox-wrap input:checkbox").length
      @check_all_checkbox.prop 'checked', true
    else
      @check_all_checkbox.prop 'checked', false


  checkAll: =>
    @item_table.find("tbody tr:not(.item-template) .recovery-checkbox-wrap input:checkbox").prop 'checked', true
    @updateCheckedCounts()
    return

  uncheckAll: =>
    @item_table.find("tbody tr:not(.item-template)  .recovery-checkbox-wrap input:checkbox").prop 'checked', false
    @updateCheckedCounts()
    return

  getIdsOfSelected: =>
    ids = []

    $.each @item_table.find("tbody tr:not(.item-template) .recovery-checkbox-wrap input:checkbox:checked"), (key, elem) =>
      id = $(elem).closest("[data-archived-jot]").data('archived-jot')
      ids.push id

    return ids

  removeArchivedJotElems: (ids) =>
    $.each ids, (index, id) =>
      @item_table.find("[data-archived-jot='#{id}']").remove()

    @updateCheckedCounts()

  showDeleteConfirmation: =>
    @primary_action_buttons_wrap.hide()
    @delete_confirmation_wrap.show()

  hideDeleteConfirmation: =>
    @primary_action_buttons_wrap.show()
    @delete_confirmation_wrap.hide()

  restoreSelected: =>
    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return

    if @xhr_waiting
      return

    @xhr_waiting = true
    @loader.show()
    ids = @getIdsOfSelected()

    $.ajax(
      type: 'POST'
      url: '/archived_jots/restore'
      data: { ids: ids }
      success: (data) =>
        @xhr_waiting = false
        new HoverNotice(@lj, 'Jot(s) restored. Changes will appear momentarily.', 'success')
        @loader.hide()
        @removeArchivedJotElems ids
        @checkIfEmpty()

      error: (data) =>
        @xhr_waiting = false
        new HoverNotice(@lj, 'Could not restore jot(s). Please try again, or contact us.', 'error')
        @loader.hide()
    )

  deleteSelected: =>
    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return

    if @xhr_waiting
      return

    @xhr_waiting = true
    @loader.show()
    ids = @getIdsOfSelected()

    $.ajax(
      type: 'DELETE'
      url: '/archived_jots'
      data: { ids: ids }
      success: (data) =>
        @xhr_waiting = false
        new HoverNotice(@lj, 'Jot(s) permanently deleted.', 'success')
        @loader.hide()
        @removeArchivedJotElems ids
        @checkIfEmpty()

      error: (data) =>
        @xhr_waiting = false
        new HoverNotice(@lj, 'Could not delete jot(s). Please try again, or contact us.', 'error')
        @loader.hide()
    )

  checkIfEmpty: =>
    count = @item_table.find("tbody tr:not(.item-template)").length
    if count == 0
      @item_table.hide()
      @empty_wrap.show()

    else
      @item_table.show()
      @empty_wrap.hide()
