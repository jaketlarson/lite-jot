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
    $('navNO').attr('data-magellan-expedition', 'fixed')
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
    @initVars()

    @clock = new Clock(@)
    @fullscreen = new Fullscreen(@)
    @airplane_mode = new AirplaneMode(@)
    @folders = new Folders(@)
    @topics = new Topics(@)
    @jots = new Jots(@)
    @search = new Search(@)
    @user_settings = new UserSettings(@)
    @connection = new Connection(@)
    @setUIInterval()
    @connection.loadDataFromServer()
    @initModalFocusBind()
    @connection.startConnectionTestTimer()
    @jots.new_jot_content.focus()
    @airplane_mode.checkLocalStorageContents()
    @initTips()
    @jot_recovery = new JotRecovery(@)
    @initAsideToggleListener()
    @initUnloadListener()

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

    # Color name to hex mapping
    @colors =
      'default': '#333333'
      'gray': '#7f8c8d'
      'red': '#e74c3c'
      'orange': '#e67e22'
      'yellow': '#f1c40f'
      'green': '#27ae60'
      'blue': '#2980b9'
      'purple': '#8e44ad'

    @dash_loading_overlay = $('#dash-loading-overlay')
    @show_aside_trigger = $('#show-aside')

  setViewport: =>
    @viewport =
      width: window.innerWidth
      height: window.innerHeight

  sizeUI: =>
    keyboard_shortcuts_height = if $('#keyboard-shortcuts').is(':visible') then $('#keyboard-shortcuts').height() else 0
    airplane_notice_height = if @airplane_mode.header_notice.is(':visible') then @airplane_mode.header_notice.height() else 0
    nav_height = parseInt($('body').css('paddingTop'))
    console.log nav_height
    folders_height = window.innerHeight - nav_height - keyboard_shortcuts_height - airplane_notice_height - $('#folders-heading').outerHeight(true)
    @folders.folders_wrapper.css 'height', folders_height

    topics_height = window.innerHeight - nav_height - keyboard_shortcuts_height - airplane_notice_height - $('#topics-heading').outerHeight(true)
    @topics.topics_wrapper.css 'height', topics_height

    jots_height = window.innerHeight - nav_height - keyboard_shortcuts_height - airplane_notice_height - 0*@jots.new_jot_wrap.outerHeight(true)
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
    $('#keyboard-shortcuts-link, #jot-options-link').cooltip {
      direction: 'bottom'
      align: 'left'
      zIndex: 2
    }

    $('#calendar-link, #fullscreen-request, #support-center-link, #jot-recovery-modal-link, #sign-out-link, #blog-link, #admin-dashboard-link, #profile-details-link').cooltip {
      direction: 'right'
      zIndex: 2
    }

  initKeyControls: =>
    # To avoid the shortcuts area showing a blank gutter while loading screen is up..
    if $('#keyboard-shortcuts').attr('data-active-on-init') == 'true'
      $('#keyboard-shortcuts').addClass('active')

    @key_controls = new KeyControls(@)
    @key_controls.curr_pos = 'new_jot_content'
    @key_controls.switchKeyboardShortcutsPane()

  initCalendar: =>
    @calendar = new Calendar(@)

  initEmailTagger: =>
    @email_tagger = new EmailTagger(@)

  initPushUI: =>
    @pushUI = new PushUI(@)

  resetTempData: =>
    # @temp.folders = null
    # @temp.topics = null
    # @temp.jots = null
    # @temp.shares = null
    @temp.user = null
    @temp.new_or_updated_folders = null
    @temp.new_or_updated_topics = null
    @temp.new_or_updated_jots = null
    @temp.deleted_folders = null
    @temp.deleted_topics = null
    @temp.deleted_jots = null

  checkIfIntroduction: =>
    if !@app.user.saw_intro
      $(document).foundation 'joyride', 'start'
      @user_settings.sawIntro()

  hideLoader: =>
    setTimeout(() =>
      @dash_loading_overlay.fadeOut(500).css { marginLeft: -1*$('body').width() }
    , 500)

  initAsideToggleListener: =>
    @show_aside_trigger.click =>
      @toggleAside()

  toggleAside: =>
    # This could be way cleaner.. like making body have class 'showing-aside' and then bringing all
    # of that CSS into it's own stylesheet

    if $('nav').hasClass('showing-aside')
      @folders.folders_column.removeClass('showing-aside')
      @topics.topics_column.removeClass('showing-aside')
      $('nav').removeClass('showing-aside')

    else
      @folders.folders_column.addClass('showing-aside')
      @topics.topics_column.addClass('showing-aside')
      $('nav').addClass('showing-aside')

  initUnloadListener: =>
    window.onbeforeunload = (e) =>
      if !@jots.jotContentEmpty()
        e = e || window.event
        if e
          e.returnValue = "You haven't saved your jot yet!"

        return "You haven't saved your jot yet!"

  setPageHeading: =>
    folder_name = "No folder selected"
    topic_name = "No topic selected"

    if @app.current_folder
      folder_name = @app.folders.filter((folder) => folder.id == @app.current_folder)[0].title

    if @app.current_topic
      topic_name = @app.topics.filter((topic) => topic.id == @app.current_topic)[0].title

    $('nav h2').html "#{folder_name} &nbsp; / &nbsp; #{topic_name}"
