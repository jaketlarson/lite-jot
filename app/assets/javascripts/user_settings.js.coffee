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
    @header_display_name = $('nav #header-display-name')

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
      @updateFormWithClientSideData()

      @modal.find('.cancel').click =>
        @modal.foundation 'reveal', 'close'

      @modal.find('.confirm').click (e) =>
        @saveSettings()

  saveSettings: =>
    @submit_text.hide()
    @success_text.hide()
    @loading_text.show()
    clearTimeout(@success_text_timeout)

    @lj.connection.abortPossibleDataLoadXHR()
    $.ajax(
      type: 'PATCH'
      url: @form.attr('action')
      data: @form.serialize()

      success: (data) =>
        @lj.connection.startDataLoadTimer()
        @updateClientSideUserData data
        @handleSuccess data

      error: (data) =>
        @lj.connection.startDataLoadTimer()
        @handleError(data)
    )

  handleSuccess: (data) =>
    @error_wrap.hide()
    @clearPasswordFields()
    @success_text.show()
    @loading_text.hide()
    @submit_button.addClass 'success'

    @success_text_timeout = setTimeout(() =>
      @success_text.hide()
      @submit_text.show()
      @submit_button.removeClass 'success'
    , @success_text_time)

  handleError: (data) =>
    @error_text.html data.responseJSON.errors
    @error_wrap.show()
    @submit_text.show()
    @loading_text.hide()

  updateClientSideUserData: (user) =>
    @lj.app.user = user
    @updateHeaderDisplayName()

  updateHeaderDisplayName: =>
    @header_display_name.html @lj.app.user.display_name

  updateFormWithClientSideData: =>
    if @lj.app.user
      user = @lj.app.user
      @form.find('#user_display_name').val user.display_name
      @form.find('#user_email').val user.email
      @form.find('#user_receives_email').prop 'checked', user.receives_email

  clearPasswordFields: =>
    @form.find('#user_current_password').val ''
    @form.find('#user_password').val ''
    @form.find('#user_password_confirmation').val ''

  sawIntro: =>
    $.get("/user/saw-intro")
