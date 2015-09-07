#= require litejot

class window.EmailTagger extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @initModalOpenBind()

  initVars: =>
    @modal = $('#email-tagger-modal')
    @modal_template = $('#email-tagger-modal-template')
    @email_thread_template = $('#email-thread-template')
    @topic = null # set upon @openModal()

  initInstanceVars: =>
    @modal_info = @modal.find '.modal-info'
    @loader = @modal.find '.loader'
    @threads_list = @modal.find 'ul.threads-list'
    @error = @modal.find 'p.error'
    @try_again = @modal.find 'a.try-again'
    @load_more = @modal.find '.load-more'
    @next_page_token = ""
    @already_tagged = []

  initModalOpenBind: =>
    $('#jot-toolbar-email-tag').click =>
      @openModal()
      return

  initOverlayPrompt: =>
    @email_tag_overlay = $("<div id='email-tag-overlay'>#{$('#email-tag-overlay-template').html()}</div>")
    $('body').append @email_tag_overlay
    @email_tag_prompt = @email_tag_overlay.find('.email-tag-prompt')
    @email_tag_prompt.find('.tag-title').focus()

    @email_tag_overlay.click (e) =>
      if $(e.target).attr('id') == @email_tag_overlay.attr('id')
        @closeOverlayPrompt()

  closeOverlayPrompt: =>
    @email_tag_overlay.remove()
    @email_tag_overlay = null
    @email_tag_prompt = null

  initInfoTooltip: =>
    @modal_info.cooltip({
      direction: 'right'
      align: 'bottom'
    })

  initTryAgainBind: =>
    @try_again.click =>
      @loadThreads()

  initLoadMoreBind: =>
    @load_more.click =>
      if !@load_more.attr('disabled')
        @loadThreads()

  initInstance: =>
    @initInstanceVars()
    @initInfoTooltip()
    @initTryAgainBind()
    @initLoadMoreBind()
    @loadThreads()
    @setTopicTitle()

  openModal: =>
    @topic = @lj.app.topics.filter((topic) => topic.id == @lj.app.current_topic)[0]

    if @lj.emergency_mode.active
      @lj.emergency_mode.feature_unavailable_notice()
      return

    if !@topic
      new HoverNotice(@lj, 'Please create or select a topic to tag emails.', 'error')
      return

    @modal.foundation 'reveal', 'open'
    @modal.focus()
    @modal.html(@modal_template.html())

    @initInstance()

    $('#email-tagger-modal .cancel').click =>
      $('#email-tagger-modal').foundation 'reveal', 'close'

  loadThreads: =>
    @load_more.attr 'disabled', true
    @loader.show()
    @error.hide()

    $.ajax(
      type: "GET"
      url: "/gmail_api?next_page_token=#{@next_page_token}"
      success: (data) =>
        @loader.hide()
        @buildThreads data.threads
        @checkAlreadyTaggedList()
        @next_page_token = data.next_page_token

        @load_more.detach()
        @modal.find('ul.threads-list').append @load_more
        @load_more.show().attr 'disabled', false

      error: (data) =>
        @loader.hide()
        @error.show()
    )

  buildThreads: (threads) =>
    $.each threads, (index, thread) =>
      new_elem = $(@email_thread_template.html())
      new_elem.attr('data-thread', thread.id)
      new_elem.find('span.subject').html("#{thread.subject}. . .")

      @threads_list.append new_elem
      @initThreadBind thread.id

  initThreadBind: (id) =>
    elem = @modal.find("[data-thread='#{id}']")
    elem.find('.view-thread').click =>
      new window.EmailViewer @lj, id
    .cooltip()

    elem.find('.tag').click (e) =>
      if !$(e.currentTarget).hasClass('loading')
        @openTagPrompt id, elem.find('.subject').html()
    .cooltip()

  setTopicTitle: =>
    @modal.find('h4 .topic-title').html @topic.title

  # getAlreadyTaggedList will get the IDs of emails already tagged in topic.
  # The point of this is to show icons indicated a thread has already been
  # tagged in this topic.
  checkAlreadyTaggedList: =>
    jots = @lj.app.jots.filter((jot) => jot.topic_id == @topic.id && jot.tagged_email_id)

    $.each jots, (key, jot) =>
      if @already_tagged.indexOf(jot.tagged_email_id) == -1
        @already_tagged.push jot.tagged_email_id

    $.each @already_tagged, (index, thread_id) =>
      @markTagged thread_id

  openTagPrompt: (id, subject) =>
    @initOverlayPrompt()
    @email_tag_prompt.find('.tag-title').val subject

    @email_tag_prompt.find('form').submit (e) =>
      e.preventDefault()
      new_subject = @email_tag_prompt.find('.tag-title').val()
      @tag id, new_subject

  tag: (id, subject) =>
    elem = @modal.find("[data-thread='#{id}']")
    tag_elem = elem.find('.tag')
    tag_elem.find('.tag-icon').hide()
    tag_elem.find('.load-icon').show()
    tag_elem.addClass('loading')

    $.ajax(
      type: 'POST'
      url: '/jots/create_email_tag'
      data: "email_id=#{id}&subject=#{subject}&topic_id=#{@topic.id}"
      success: (data) =>
        @lj.app.jots.push data.jot
        @lj.jots.insertJotElem data.jot
        @closeOverlayPrompt()
        @markTagged id
        new HoverNotice(@lj, 'Email tag added to topic.', 'success')

      error: (data) =>
        new HoverNotice(@lj, 'Could not save email tag.', 'error')
    )

  markTagged: (id) =>
    elem = @modal.find("[data-thread='#{id}']")
    elem.find('.tag').removeClass('loading').addClass('tagged').find('.load-icon').hide()
    elem.find('.tag').find('.tagged-icon').show()
    elem.find('.tag').attr('title', 'Already tagged in this topic').cooltip('update')




