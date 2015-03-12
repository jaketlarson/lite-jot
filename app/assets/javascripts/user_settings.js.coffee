#= require lightjot

class window.UserSettings extends LightJot
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

      @user_settings_modal.find('.cancel').click (e2) =>
        @user_settings_modal.foundation 'reveal', 'close'