#= require litejot

class window.Support extends LiteJot
  constructor: (@lj) ->
    @initVars()
    if @modal_link.is(':visible')
      @initBinds()

  initVars: =>
    @modal_link = $('a#support-modal-link')
    @modal = $('#support-modal')
    @modal_template = $('#support-modal-template')

  initBinds: =>
    @modal_link.click (e) =>
      @modal.foundation 'reveal', 'open'
      @modal.html @modal_template.html()
      @initInstanceVars()

  initInstanceVars: =>
    @modal.find('.confirm').click (e) =>
      @modal.foundation 'reveal', 'close'
