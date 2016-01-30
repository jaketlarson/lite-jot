$ ->
  blog_subscribe = new window.BlogSubscribe()

class window.BlogSubscribe
  constructor: ->
    @initVars()

    if @formExists()
      @initSubmitListener()

  initVars: =>
    @wrap = $('#blog-subscribe-form')
    @form = @wrap.find('form')
    @email = @form.find('input.recipient-email')
    @button_wrap = @form.find('.subscribe-button-wrap')
    @button = @button_wrap.find('button')

  formExists: =>
    @form.length == 1

  initSubmitListener: =>
    @form.submit (e) =>
      e.preventDefault()
      @showSubmitLoading()
      @subscribe()

  subscribe: =>
    $.ajax(
      type: 'POST'
      url: "/blog_subscriptions"
      data: "email=#{encodeURIComponent(@email.val())}"

      success: (data) =>
        @showSuccessful()
        console.log data

      error: (data) =>
        console.log data
        unless !data.responseJSON || typeof data.responseJSON.error == 'undefined'
          @showError data.responseJSON.error
        else
          @showError "Error while connecting to server"
    )

  showSubmitLoading: =>
    @email.attr('disabled', true)
    @button.attr('disabled', true)
    @button.find('.submit-text').hide()
    @button.find('.loading-icon').show()

  hideSubmitLoading: =>
    @email.attr('disabled', false)
    @button.attr('disabled', false)
    @button.find('.loading-icon').hide()
    @button.find('.submit-text').show()

  showError: (error) =>
    @wrap.find('.subscribe-error').show().find('.error-text').html(error)
    @hideSubmitLoading()

  showSuccessful: () =>
    @wrap.find('.subscribe-error').hide()
    console.log 'yer good'

    top = @button_wrap.offset().top - @button_wrap.parent().offset().top
    current_left = @button_wrap.offset().left - @button_wrap.parent().offset().left
    new_left = @email.offset().left - @email.parent().offset().left

    @email.css({
      'width': 0
      'paddingLeft': 0
      'paddingRight': 0
      'border': 0
    })

    @button_wrap.css({
      'position': 'absolute'
      'top': top
      'left': current_left
      })

    @button.addClass('success')
    @button.find('.loading-icon').hide()

    setTimeout(() =>
      @button_wrap.css('left', new_left)
    , 250)

    setTimeout(() =>
      console.log '2'
      @wrap.find('.subscribe-email-wrap').css({
        'display': 'none'
      })
      @wrap.find('.success-message-wrap').css({
        'display': 'table-cell'
        'width': '100%'
      })
    , 500)

    setTimeout(() =>
      console.log '3'
      @wrap.find('.success-message-wrap').css({
        'opacity': 1.0
      })
    , 750)

