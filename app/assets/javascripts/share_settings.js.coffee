#= require litejot

class window.ShareSettings extends LiteJot
  constructor: (@lj, @folder_id) ->
    @initVars()
    @initModal()
    @initNewShareBinds()
    @buildShares()
    @updateSharedWithCount()

  initVars: =>
    @modal = $('#share-modal')
    @modal_template = $('#share-modal-template')
    @share_template = $('#share-template')
    @share_topic_row_template = $('#share-topic-row-template')

  initModal: =>
    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return
      
    @modal.foundation 'reveal', 'open'
    @modal.focus()
    @modal.html(@modal_template.html())

    @initInstanceVars()

    $('#share-modal .cancel').click =>
      $('#share-modal').foundation 'reveal', 'close'

  initInstanceVars: =>
    @user_list = @modal.find('ul.user-list')
    @folder_shares = @lj.app.shares.filter((share) => share.folder_id == @folder_id)
    @XHR_update_waiting = false
    @XHR_update_request = null
    @error_wrap = @modal.find('.alert-error')

  initNewShareBinds: =>
    link = @modal.find('a.new-share-link')
    form = @modal.find('form.new-share-form')
    input = @modal.find('input.recipient-email')

    link.click =>
      if form.is(':visible')
        form.hide()
      else
        form.css('display', 'table')
        input.val('')
        input.focus()

    form.submit (e) =>
      e.preventDefault()
      @submitShare()

  buildShares: =>
    $.each @folder_shares, (share_index, share) =>
      @buildShareItem share.id

  buildShareItem: (share_id) =>
    share = @folder_shares.filter((share) => share.id == share_id)[0]

    new_elem = $(@share_template.html())
    new_elem.attr('data-share', share.id)
    new_elem.find('span.recipient-email').html("#{share.recipient_display_name} &lt;#{share.recipient_email}&gt;")
    new_elem.find('span.permissions-preview').html(share.permissions_preview)
    new_elem.find('input.share-all-checkbox').attr("id", "toggle-topics-#{share.id}")
    new_elem.find('label.share-all-label').attr("for", "toggle-topics-#{share.id}")
    if share.is_all_topics
      new_elem.find('input.share-all-checkbox').prop('checked', true)

    @user_list.prepend new_elem

    list_elem = $("li[data-share='#{share.id}']")

    if share.is_all_topics
      list_elem.find('.topics-wrap').hide()

    $("input[type='checkbox']#toggle-topics-#{share.id}").click =>
      share.is_all_topics = $("input[type='checkbox']#toggle-topics-#{share.id}").is(':checked')
      if share.is_all_topics
        list_elem.find('.topics-wrap').slideUp()
      else
        list_elem.find('.topics-wrap').slideDown()
      @updateShare share.id

    list_elem.find('.delete-link').click =>
      @unshare share.id

    $.each @lj.app.topics.filter((topic) => topic.folder_id == share.folder_id), (topic_index, topic) =>
      new_row = $(@share_topic_row_template.html())
      new_row.attr("data-share-topic", "#{share.id}-#{topic.id}")
             .attr("title", "#{topic.title}")
      new_row.find('.topic-check').attr("data-checked", "#{if $.inArray(String(topic.id), share.specific_topics) >= 0 then 'true' else 'false'}")
              .attr("id", "share-check-#{share.id}-#{topic.id}")
      new_row.find('span.topic-title').html(topic.title)

      list_elem.find('ul.topics').append new_row

      topic_elem = $("li[data-share-topic='#{share.id}-#{topic.id}']")
      topic_elem.click (e) =>
        check_elem = $(e.currentTarget).find('.topic-check')
        if check_elem.attr('data-checked') == 'true'
          check_elem.attr('data-checked', 'false')
          @removeTopicFromShareList share.id, topic.id
        else
          check_elem.attr('data-checked', 'true')
          @addTopicToShareList share.id, topic.id


    list_elem.find('h4').click (e) =>
      if list_elem.hasClass('active')
        list_elem.removeClass('active')
      else
        list_elem.addClass('active')

  updateSharedWithCount: =>
    if @folder_shares.length > 0
      @modal.find('.shared-with-count').html('')
    else
      @modal.find('.shared-with-count').html('no one')

  submitShare: =>
    form = @modal.find('form.new-share-form')
    email = form.find('input.recipient-email')

    if email.val().length > 0
      @showSubmitLoading()

      @lj.connection.abortPossibleDataLoadXHR()
      $.ajax(
        type: 'POST'
        url: '/shares'
        data: "recipient_email=#{encodeURIComponent(email.val())}&folder_id=#{@folder_id}"
        success: (data) =>
          @lj.connection.startDataLoadTimer()
          @error_wrap.hide()
          @hideSubmitLoading()
          @lj.app.shares.push data.share
          @folder_shares.push data.share
          @buildShareItem data.share.id
          $("li[data-share='#{data.share.id}']").addClass('active')
          @modal.find('form.new-share-form').hide()

        error: (data) =>
          @lj.connection.startDataLoadTimer()
          response = data.responseJSON
          @hideSubmitLoading()
          @error_wrap.show()

          if response
            @error_wrap.find('.error-text').html(response.error)
          else
            @error_wrap.find('.error-text').html("Error connecting to server. Please contact us if this issue perists.")
      )

    else
      @error_wrap.show()
      @error_wrap.find('.error-text').html("Please enter a valid email address.")

  showSubmitLoading: =>
    form = @modal.find('form.new-share-form')
    email = form.find('input.recipient-email')
    button = form.find('button')

    email.attr('disabled', true)
    button.attr('disabled', true)
    button.find('.submit-text').hide()
    button.find('.loading').show()

  hideSubmitLoading: =>
    form = @modal.find('form.new-share-form')
    email = form.find('input.recipient-email')
    button = form.find('button')

    email.attr('disabled', false)
    button.attr('disabled', false)
    button.find('.loading').hide()
    button.find('.submit-text').show()

  addTopicToShareList: (share_id, topic_id) =>
    share = @folder_shares.filter((share) => share.id == share_id)[0]
    if $.inArray(String(topic_id), share.specific_topics) == -1
      if !share.specific_topics
        share.specific_topics = [String(topic_id)]
      else
        share.specific_topics.push String(topic_id)
      @updateShare share_id

  removeTopicFromShareList: (share_id, topic_id) =>
    share = @folder_shares.filter((share) => share.id == share_id)[0]
    if $.inArray(String(topic_id), share.specific_topics) > -1
      share.specific_topics.splice(share.specific_topics.indexOf(String(topic_id)), 1)
      @updateShare share_id


  updateShare: (share_id) =>
    if @XHR_update_waiting
      @XHR_update_request.abort()

    share = @folder_shares.filter((share) => share.id == share_id)[0]

    @lj.connection.abortPossibleDataLoadXHR()
    @XHR_update_request = $.ajax(
      type: 'PATCH'
      url: "/shares/#{share_id}"
      data: share
      success: (data) =>
        @lj.connection.startDataLoadTimer()
        share.permissions_preview = data.share.permissions_preview
        share.is_all_topics = data.share.is_all_topics
        share.specific_topics = data.share.specific_topics

        @XHR_update_waiting = false
        @updatePermissionsPreviewText share

      error: (data) =>
        @lj.connection.startDataLoadTimer()
        @XHR_update_waiting = false
    )

  unshare: (share_id) =>
    @lj.connection.abortPossibleDataLoadXHR()
    $.ajax(
      type: 'DELETE'
      url: "/shares/#{share_id}"
      success: (data) =>
        @lj.connection.startDataLoadTimer()
        share_key = null
        $.each @lj.app.shares, (index, share) =>
          if share.id == share_id
            share_key = index
            return false

        @lj.app.shares.remove(share_key)
        $("li[data-share='#{share_id}']").remove()

      error: (data) =>
        @lj.connection.startDataLoadTimer()

    )

  updatePermissionsPreviewText: (share) =>
    elem = $("li[data-share='#{share.id}'] .permissions-preview")

    if elem.length == 1
      elem.html share.permissions_preview

