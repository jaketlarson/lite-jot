# Array Remove - By John Resig (MIT Licensed)
Array::remove = (from, to) ->
  rest = @slice((to or from) + 1 or @length)
  @length = if from < 0 then @length + from else from
  @push.apply this, rest

window.randomKey = =>
  build_key = ""
  possibilities = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890"

  for i in [0..50]
    build_key += possibilities.charAt(Math.floor(Math.random() * possibilities.length))

  return build_key;

# escapeHtml/unescapeHtml: http://shebang.brandonmintern.com/foolproof-html-escaping-in-javascript/
window.escapeHtml = (str) ->
  div = document.createElement('div')
  div.appendChild document.createTextNode(str)
  div.innerHTML
window.unescapeHtml = (escapedStr) ->
  div = document.createElement('div')
  div.innerHTML = escapedStr
  child = div.childNodes[0]
  if child then child.nodeValue else ''

$ ->
  # hasScrollBar: http://stackoverflow.com/questions/4814398/how-can-i-check-if-a-scrollbar-is-visible
  $.fn.hasScrollBar = ->
    @get(0).scrollHeight > @height()
  
  if $('body#pages-dashboard').length > 0
    window.lj = {
      litejot: new window.LiteJot()
    }
    $(document).foundation()
  else
    $(document).foundation(
      "magellan-expedition": {
        destination_threshold: 250
    })

    # This event listener is an override on Foundation's Magellan module
    # The module buffers the anchor with the destination_threshold
    # property, which makes the click-to-scroll functionality useless,
    # since the section it scrolls to is only partly scrolled to.
    $("[data-magellan-arrival]").click (e) ->
      name = $(e.currentTarget).find('a').attr('href').replace(/#/, '')
      buffer = 50
      e.stopPropagation()
      $('html,body').animate({scrollTop: $("a[name='#{name}']").offset().top - buffer},'slow')

class window.LiteJot
  constructor: ->
    @init_data_loaded = false

    @clock = new Clock(@)
    @fullscreen = new Fullscreen(@)
    @emergency_mode = new EmergencyMode(@)
    @folders = new Folders(@)
    @topics = new Topics(@)
    @jots = new Jots(@)
    @search = new Search(@)
    @key_controls = new KeyControls(@)
    @user_settings = new UserSettings(@)
    @connection = new Connection(@)
    @initVars()
    @sizeUI()
    @setUIInterval()
    @connection.loadDataFromServer()
    @initAppInfoModalBind()
    @initModalFocusBind()
    @connection.startConnectionTestTimer()
    @jots.new_jot_content.focus()
    @emergency_mode.checkLocalStorageContents()
    @initTips()
    @support = new Support(@)
    @support = new JotRecovery(@)

  initVars: =>
    @app = {} # all loaded app data goes here
    @temp = {} # used for merging server data with clientside (@app) data

    @setViewport()

    # scroll_padding_factor is used for moving elements
    # into view, and using the wrapper-height times
    # scroll_padding_factor as a buffer. This is also
    # used when determining when to load a new page of
    # jots.
    @scroll_padding_factor = .15

  setViewport: =>
    @viewport =
      width: window.innerWidth
      height: window.innerHeight

  sizeUI: =>
    keyboard_shortcuts_height = if $('#keyboard-shortcuts').is(':visible') then $('#keyboard-shortcuts').height() else 0
    emergency_notice_height = if @emergency_mode.header_notice.is(':visible') then @emergency_mode.header_notice.height() else 0
    folders_height = window.innerHeight - $('nav').outerHeight() - keyboard_shortcuts_height - emergency_notice_height - $('#folders-heading').outerHeight(true)
    @folders.folders_wrapper.css 'height', folders_height

    topics_height = window.innerHeight - $('nav').outerHeight() - keyboard_shortcuts_height - emergency_notice_height - $('#topics-heading').outerHeight(true)
    @topics.topics_wrapper.css 'height', topics_height

    jots_height = window.innerHeight - $('nav').outerHeight() - keyboard_shortcuts_height - emergency_notice_height - $('#jots-heading').outerHeight(true) - @jots.new_jot_wrap.outerHeight(true)
    @jots.jots_wrapper.css 'height', jots_height

    @jots.positionEmptyMessage()

  setUIInterval: =>
    @UIInterval = setInterval(() =>
      if @viewport.width != window.innerWidth || @viewport.height != window.innerHeight
        @setViewport()
        @sizeUI()

    , 500)

  buildUI: (organize_dom=true) =>
    @folders.buildFoldersList()
    @topics.buildTopicsList organize_dom

  initAppInfoModalBind: =>
    $('nav a#app-info-modal-link').click (e) =>
      $('#app-info-modal').foundation 'reveal', 'open'
      $('#app-info-modal').html($('#app-info-modal-template').html())

      $('#app-info-modal .confirm').click (e2) =>
        $('#app-info-modal').foundation 'reveal', 'close'

  initModalFocusBind: =>
    $(document).on('opened.fndtn.reveal', '[data-reveal]', () ->
      $(this).focus()
    )

  moveElemIntoView: (elem, wrap) =>
    if elem.length == 1 && wrap.length == 1
      wrap.stop()
      wrap_height = wrap.height()
      elem_height  = elem.height()
      from_top_of_wrap = elem.offset().top - wrap.offset().top
      padding = @scroll_padding_factor*wrap_height
      if elem_height > wrap_height then padding = 0

      if from_top_of_wrap - padding < 0 # need to scroll up
        scroll_to = wrap.scrollTop() + elem.offset().top - wrap.offset().top - padding

      else if from_top_of_wrap + padding > wrap.innerHeight() # scroll down

        if from_top_of_wrap + elem_height > wrap_height # big elem
          scroll_to = wrap.scrollTop() + (from_top_of_wrap + elem_height - wrap_height) + padding

        else
          scroll_to = wrap.scrollTop() + elem_height

      if scroll_to != wrap.scrollTop()
        wrap.scrollTop(scroll_to)

  initTips: =>
    $('button.new-folder-button, button.new-topic-button').cooltip {direction: 'bottom'}
    $('#app-info-modal-link, #calendar-link, #keyboard-shortcuts-link, #fullscreen-request, #support-modal-link, #jot-recovery-modal-link').cooltip {
      direction: 'bottom'
      align: 'left'
    }

  initCalendar: =>
    @calendar = new Calendar(@)

  initPushUI: =>
    @pushUI = new PushUI(@)

  resetTempData: =>
    @temp.folders = null
    @temp.topics = null
    @temp.jots = null
    @temp.shares = null
    @temp.user = null

  dataTransfer: =>
    overlay = $("<div><div style='position: fixed;top: 0;right: 0;bottom: 0;left: 0;z-index: 2000;background-color: rgba(20, 20, 20, 0.8);'></div>")
    prompt = $("<div><div style='position: absolute;top: 50;left: calc(50% - 20%);width: 40%;margin: 0 auto;z-index: 2001;padding: 2rem;background-color: white'>
        <h2 style='margin-top: 0'>Upload data</h2>
        <textarea id='data-transfer-box' placeholder='Enter JSON data here'></textarea>
        <input id='data-transfer-password' placeholder='Passcode'>
        <button id='data-transfer-button'>Upload</button>
      </div></div>")

    $('body').append overlay.html()
    $('body').append prompt.html()

    $.ajax(
      type: 'GET'
      url: '/raw-data'
      success: (data) ->
        $('#data-transfer-box').val(JSON.stringify(data))
    )

    $('button#data-transfer-button').click ->
      passcode = $('#data-trasnfer-password').val()
      transfer_data = JSON.parse($('#data-transfer-box').val())
      folders = transfer_data.folders
      topics = transfer_data.topics
      jots = transfer_data.jots
      console.log folders
      console.log topics
      console.log jots
      $.ajax(
        type: 'POST'
        url: "/transfer-data"
        data: "passcode=#{passcode}&folders=#{encodeURIComponent(JSON.stringify(folders))}&topics=#{encodeURIComponent(JSON.stringify(topics))}&jots=#{encodeURIComponent(JSON.stringify(jots))}"
        success: (data) ->
          console.log 'wow!'
        error: (data) ->
          console.log 'no, sorry.'

      )
