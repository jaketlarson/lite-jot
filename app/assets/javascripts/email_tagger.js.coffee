#= require litejot

class window.EmailTagger extends LiteJot
  constructor: (@lj, @folder_id) ->
    @initVars()
    @initModalOpenBind()
    # @initNewShareBinds()
    # @buildShares()
    # @updateSharedWithCount()

  initVars: =>
    @modal = $('#email-tagger-modal')
    @modal_template = $('#email-tagger-modal-template')
    @email_thread_template = $('#email-thread-template')

  initInstanceVars: =>
    @modal_info = @modal.find '.modal-info'
    @loader = @modal.find '.loader'
    @threads_list = @modal.find 'ul.threads-list'
    @current_page = 1

  initModalOpenBind: =>
    $('#email-tagger-modal-link').click =>
      @openModal()
      return

  initInfoTooltip: =>
    console.log @modal_info
    @modal_info.cooltip({
      direction: 'right'
      align: 'bottom'
    })

  initInstance: =>
    @initInstanceVars()
    @initInfoTooltip()
    @loadThreads()

  openModal: =>
    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return
      
    @modal.foundation 'reveal', 'open'
    @modal.focus()
    @modal.html(@modal_template.html())

    @initInstance()

    $('#email-tagger-modal .cancel').click =>
      $('#email-tagger-modal').foundation 'reveal', 'close'

  loadThreads: =>
    @loader.show()

    $.ajax(
      type: 'GET'
      url: '/gmail_api'
      success: (data) =>
        @loader.hide()
        console.log data
        @buildThreads data.threads

      error: (data) =>
        @loader.hide()
    )

  buildThreads: (threads) =>
    $.each threads, (index, thread) =>
      new_elem = $(@email_thread_template.html())
      new_elem.attr('data-thread', thread.id)
      new_elem.find('span.snippet').html("#{thread.snippet}. . .")

      @threads_list.append new_elem
      @initThreadBind thread.id

  initThreadBind: (id) =>
    elem = @modal.find("[data-thread='#{id}']")
    elem.find('.view-thread').click =>
      @toggleThread id
    .cooltip()

    elem.find('.tag').click =>
      console.log 'tag'
    .cooltip()

  toggleThread: (id) =>
    thread_preview = @modal.find("[data-thread='#{id}'] .thread-preview")

    if thread_preview.is(':visible')
      thread_preview.slideUp()

    else
      @loader.show()
      viewer = thread_preview.find("iframe.thread-viewer")
      viewer.attr("src", "/gmail_api/#{id}")
      thread_preview.slideDown()
      viewer.load =>
        @loader.hide()

