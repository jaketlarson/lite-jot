#= require litejot

class window.UserSettings extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @initUserSettingsModalBind()

  initVars: =>
    @user_settings_modal = $('#user-settings-modal')
    @user_settings_modal_link = $('nav a#user-settings-modal-link')
    @user_settings_modal_template = $('#user-settings-modal-template')

  initUserSettingsModalBind: =>
    @user_settings_modal_link.click (e) =>
      e.preventDefault()

      @user_settings_modal.foundation 'reveal', 'open'
      @user_settings_modal.html(@user_settings_modal_template.html())

      @user_settings_modal.find('.cancel').click =>
        @user_settings_modal.foundation 'reveal', 'close'

      @user_settings_modal.find('.confirm').click =>
        @saveSettings()

  saveSettings: =>
    @user_settings_form = @user_settings_modal.find('form.edit_user')

    $.ajax(
      type: 'PATCH'
      url: @user_settings_form.attr('action')
      data: @user_settings_form.serialize()

      success: (data) =>
        console.log data

      error: (data) =>
        console.log data
    )