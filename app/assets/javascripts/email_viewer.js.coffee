#= require litejot

class window.EmailViewer extends LiteJot
  constructor: (@lj, @email_id) ->
    if !@email_id
      new HoverNotice(@lj, 'Email ID not provided.', 'error')
      return

    @initVars()
    @openModal()
    @loadEmail()
    @initCloseBind()

  initVars: =>
    @modal = $('#email-viewer-modal')
    @modal_template = $('#email-viewer-modal-template')

  initInstanceVars: =>
    @loader = @modal.find '.loader'

  openModal: =>
    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return

    @modal.foundation 'reveal', 'open'
    @modal.focus()
    @modal.html(@modal_template.html())
    @initInstanceVars()

  initCloseBind: =>
    $('#email-viewer-modal .close').click =>
      $('#email-viewer-modal').foundation 'reveal', 'close'

  loadEmail: =>
    viewer = @modal.find("iframe.thread-view")
    viewer.attr("src", "/gmail_api/#{@email_id}")
    viewer.load =>
      viewer.slideDown(200)
      @loader.hide()
