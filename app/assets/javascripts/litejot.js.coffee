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

$ ->
  if $('body#pages-dashboard').length > 0
    window.lj = {
      litejot: new window.LiteJot()
    }

class window.LiteJot
  constructor: ->
    @fullscreen = new Fullscreen(@)
    @folders = new Folders(@)
    @topics = new Topics(@)
    @jots = new Jots(@)
    @key_controls = new KeyControls(@)
    @user_settings = new UserSettings(@)
    @status_bar = new StatusBar(@)
    @initVars()
    @sizeUI()
    @setUIInterval()
    @loadDataFromServer()
    @initAppInfoModalBind()
    @initModalFocusBind()

  initVars: =>
    @app = {} # all loaded app data goes here

    @key_codes =
      enter: 13

    @setViewport()

  setViewport: =>
    @viewport =
      width: window.innerWidth
      height: window.innerHeight

  sizeUI: =>
    folders_height = window.innerHeight - $('header').outerHeight() - $('#folders-heading').outerHeight(true)
    @folders.folders_wrapper.css 'height', folders_height

    topics_height = window.innerHeight - $('header').outerHeight() - $('#topics-heading').outerHeight(true)
    @topics.topics_wrapper.css 'height', topics_height

    jots_height = window.innerHeight - $('header').outerHeight() - $('#jots-heading').outerHeight(true) - @jots.new_jot_content.outerHeight(true)
    @jots.jots_wrapper.css 'height', jots_height

    @jots.positionEmptyMessage()

  setUIInterval: =>
    @UIInterval = setInterval(() =>
      if @viewport.width != window.innerWidth || @viewport.height != window.innerHeight
        @setViewport()
        @sizeUI()

    , 500)

  loadDataFromServer: =>
    folders_loaded = false
    topics_loaded = false
    jots_loaded = false

    # $.ajax(
    #   type: 'GET'
    #   url: '/load-data'
    #   success: (data) =>
    #     console.log data
    #     @app.folders = data.folders
    #     @app.topics = data.topics
    #     @app.jots = data.jots

    #     @buildUI()

    #   error: (data) =>
    #     console.log data
    # )

    loadFolders = =>
      $.ajax(
        type: 'GET'
        url: '/folders'
        success: (data) =>
          console.log data
          @app.folders = data.folders
          folders_loaded = true
          checkLoadStatus()

        error: (data) =>
          console.log data
      )

    loadTopics = =>
      $.ajax(
        type: 'GET'
        url: '/topics'
        success: (data) =>
          console.log data
          @app.topics = data.topics
          topics_loaded = true
          checkLoadStatus()

        error: (data) =>
          console.log data
      )

    loadJots = =>
      $.ajax(
        type: 'GET'
        url: '/jots'
        success: (data) =>
          console.log data
          @app.jots = data.jots
          jots_loaded = true
          checkLoadStatus()

        error: (data) =>
          console.log data
      )

    checkLoadStatus = =>
      if folders_loaded && topics_loaded && jots_loaded
        console.log 'done'
        @buildUI()
        @initNotifications()

    loadFolders()
    loadTopics()
    loadJots()

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

  initNotifications: =>
    @notifications = new Notifications(@)
