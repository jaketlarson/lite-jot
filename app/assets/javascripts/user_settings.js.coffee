#= require litejot

class window.UserSettings extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @initUserSettingsModalBind()

  initVars: =>
    @modal = $('#user-settings-modal')
    @modal_link = $('nav a#user-settings-modal-link')
    @modal_template = $('#user-settings-modal-template')
    @waiting = false
    @success_text_time = 2000

  initModalInstanceVars: =>
    @form = @modal.find('form.edit_user')
    @submit_button = @modal.find('button.confirm')
    @submit_text = @submit_button.find('.default-text')
    @loading_text = @submit_button.find('.loading-text')
    @success_text = @submit_button.find('.success-text')
    @error_wrap = @modal.find('.alert-error')
    @error_text = @modal.find('.error-text')

  initUserSettingsModalBind: =>
    @modal_link.click (e) =>
      e.preventDefault()

      if @lj.emergency_mode.active
        @lj.emergency_mode.feature_unavailable_notice()
        return 

      @modal.foundation 'reveal', 'open'
      @modal.html(@modal_template.html())
      @initModalInstanceVars()

      @modal.find('.cancel').click =>
        @modal.foundation 'reveal', 'close'

      @modal.find('.confirm').click (e) =>
        @saveSettings()

  saveSettings: =>
    @submit_text.hide()
    @success_text.hide()
    @loading_text.show()
    clearTimeout(@success_text_timeout)

    $.ajax(
      type: 'PATCH'
      url: @form.attr('action')
      data: @form.serialize()

      success: (data) =>
        @handleSuccess(data)

      error: (data) =>
        @handleError(data)
    )

  handleSuccess: (data) =>
    #data.user
    @success_text.show()
    @loading_text.hide()
    @submit_button.addClass 'success'

    @success_text_timeout = setTimeout(() =>
      @success_text.hide()
      @submit_text.show()
      @submit_button.removeClass 'success'
    , @success_text_time)

  handleError: (data) =>
    @error_text.html(data.responseJSON.user.errors)
    @error_wrap.show()
    @submit_text.show()
    @loading_text.hide()
