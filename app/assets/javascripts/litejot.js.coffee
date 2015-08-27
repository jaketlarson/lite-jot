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
  window.autolinker = new Autolinker
  
  if $('body#pages-dashboard').length > 0
    window.lj = {
      litejot: new window.LiteJot()
    }

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
    @initFoundation()
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

  initFoundation: =>
    $(document).foundation()

  initVars: =>
    @app = {} # all loaded app data goes here
    @temp = {} # used for merging server data with clientside (@app) data

    @setViewport()

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
      padding = .15*wrap_height
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
    $('#app-info-modal-link, #calendar-link, #keyboard-shortcuts-link, #fullscreen-request').cooltip {
      direction: 'bottom'
      align: 'left'
    }

  initCalendar: =>
    @calendar = new Calendar(@)

  initPushUI: =>
    @pushUI = new PushUI(@)

  forceHideAllTooltips: =>
    $('.cooltip').hide()
