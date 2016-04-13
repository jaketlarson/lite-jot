class window.LiteJot
  constructor: ->
    @init_data_loaded = false
    @initVars()

    @news_flash = new NewsFlash(@)
    @clock = new Clock(@)
    @fullscreen = new Fullscreen(@)
    @airplane_mode = new AirplaneMode(@)
    @jot_uploader = new JotUploader(@)
    @folders = new Folders(@)
    @topics = new Topics(@)
    @jots = new Jots(@)
    @search = new Search(@)
    @user_settings = new UserSettings(@)
    @aside = new Aside(@)
    @connection = new Connection(@)
    @setUIInterval()
    @connection.loadDataFromServer()
    @initModalFocusBind()
    @connection.startConnectionTestTimer()
    @jots.new_jot_content.focus()
    @airplane_mode.checkLocalStorageContents()
    @initTips()
    @jot_recovery = new JotRecovery(@)
    @initUnloadListener()

    $(document).foundation()

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

    # Keep track of any currently opened photo gallery so
    # we can resize that when it's opened and the window
    # is resized.
    @current_photo_gallery = null

  setViewport: =>
    @viewport =
      width: window.innerWidth
      height: window.innerHeight

  sizeUI: =>
    keyboard_shortcuts_height = if $('#keyboard-shortcuts').is(':visible') then $('#keyboard-shortcuts').height() else 0
    airplane_notice_height = if @airplane_mode.header_notice.is(':visible') then @airplane_mode.header_notice.height() else 0
    nav_height = parseInt($('body').css('paddingTop'))

    folders_height = window.innerHeight - nav_height - keyboard_shortcuts_height - airplane_notice_height - $('#folders-heading').outerHeight(true)
    @folders.folders_wrapper.css 'height', folders_height

    topics_height = window.innerHeight - nav_height - keyboard_shortcuts_height - airplane_notice_height - $('#topics-heading').outerHeight(true)
    @topics.topics_wrapper.css 'height', topics_height

    jots_height = window.innerHeight - nav_height - keyboard_shortcuts_height - airplane_notice_height - 0*@jots.new_jot_wrap.outerHeight(true)
    @jots.jots_wrapper.css 'height', jots_height

    # If a photo gallery is currently opened, call it's size-settier
    if @current_photo_gallery
      @current_photo_gallery.setSize()

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
    @temp.user = null
    @temp.new_or_updated_folders = null
    @temp.new_or_updated_topics = null
    @temp.new_or_updated_jots = null
    @temp.deleted_folders = null
    @temp.deleted_topics = null
    @temp.deleted_jots = null

  checkIfIntroduction: =>
    if !@app.user.saw_intro && Foundation.utils.is_large_up()
      $(document).foundation 'joyride', 'start'
      @user_settings.sawIntro()

  hideLoader: =>
    setTimeout(() =>
      @dash_loading_overlay.fadeOut(500).css { marginLeft: -1*$('body').width() }
    , 500)

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
    window.document.title = "#{folder_name} / #{topic_name} | Lite Jot"

  closeAllDropdowns: =>
    $(document).foundation('dropdown', 'closeall')
