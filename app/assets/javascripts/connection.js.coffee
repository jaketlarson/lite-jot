#= require litejot

class window.Connection extends LiteJot
  constructor: (@lj) ->
    @initVars()
    @initBinds()

  initVars: =>
    @connection_test_timer = null
    @connection_test_timing = 2000
    @connection_test_url = '/connection-test'

    # If the connection test fails, and there are allowed
    # retrials, this timer will be used to more quickly
    # retest the connection.
    # Also used in reattempt to reconnect
    @connection_retest_timing = 500

    # Number of times the connect test fails
    # before entering airplane mode. If set to one,
    # the connection test may only fail once consecutively
    @failures_before_airplane_mode = 1
    @consecutive_failures = 0

    # @data_load_xhr is checked on every ajax request.
    # If it's in progress, it is aborted to avoid complications
    # when cross-checking data.
    @data_load_xhr = null
    @data_load_timer = null
    @data_load_timing = 3000

    # Used in the case that ajax is aborted but we don't want to
    # restart the timer (i.e., some other function is in control).
    @aborted = true

  initBinds: =>
    document.addEventListener "visibilitychange", @handleVisibilityChange, false

  handleVisibilityChange: =>
    if document.hidden
      @abortPossibleDataLoadXHR()

    else if @lj.init_data_loaded
      @loadUpdates()
      @lj.jots.determineFocusForNewJot()

  loadDataFromServer: =>
    # Include timezone in request to be set on user
    timezone = jstz.determine().name()

    @data_load_xhr = $.ajax(
      type: 'GET'
      url: "/load-data-init?timezone=#{timezone}"
      success: (data) =>
        @lj.app.folders = data.folders
        @lj.app.topics = data.topics
        @lj.app.jots = data.jots
        @lj.app.folder_shares = data.folder_shares
        @lj.app.user = data.user
        @lj.app.last_update_check = data.last_update_check
        @lj.buildUI()
        @lj.aside.showToggle()
        @lj.setPageHeading()
        @lj.initKeyControls()
        @lj.sizeUI()
        @lj.initCalendar()
        @lj.initEmailTagger()
        @lj.initPushUI()
        @lj.checkIfIntroduction()
        #@lj.user_settings.applyPreferences()
        @lj.hideLoader()
        @lj.init_data_loaded = true

        @startDataLoadTimer()
        @data_load_xhr = null

      error: (data) =>
        # Just restart it, as the connection test (separate routine
        # XHR request) will catch network issues.
        setTimeout () ->
          @loadDataFromServer()
        , 500
        @data_load_xhr = null
        # more error handling, maybe?
    )

  loadUpdates: =>
    # Avoid extra timers
    if @data_loader_timer
      clearTimeout @data_load_timer()

    @aborted = false

    @data_load_xhr = $.ajax(
      type: 'GET'
      url: "/load-updates?last_update_check_time=#{@lj.app.last_update_check}"
      success: (data) =>
          # @lj.temp.folders = data.folders
          # @lj.temp.topics = data.topics
          # @lj.temp.jots = data.jots
          # @lj.temp.shares = data.shares
          # @lj.temp.user = data.user
          # @lj.pushUI.mergeData()
        #console.log data
        @lj.app.last_update_check = data.last_update_check
        @lj.temp.new_or_updated_folders = data.new_or_updated.folders
        @lj.temp.new_or_updated_topics = data.new_or_updated.topics
        @lj.temp.new_or_updated_jots = data.new_or_updated.jots
        @lj.temp.deleted_folders = data.deleted.folders
        @lj.temp.deleted_topics = data.deleted.topics
        @lj.temp.deleted_jots = data.deleted.jots
        @lj.temp.user = data.user
        @lj.pushUI.mergeData()
        @data_load_xhr = null

        @lj.connection.startDataLoadTimer()

      error: (data) =>
        # Just restart it, as the connection test (separate routine
        # XHR request) will catch network issues.
        console.log 'error retrieving updates'
        @data_load_xhr = null
        # more error handling, maybe?

        if @aborted
          @aborted = false
        else
          @lj.connection.startDataLoadTimer()
    )

  abortPossibleDataLoadXHR: =>
    # This function is called on any ajax request
    # to stop any possible data load request in progress.
    # This way, the client's UI doesn't get messed up
    # when merging data from server to client.
    # We only care if it's not on init data load.
    if @data_load_xhr && @lj.init_data_loaded
      @data_load_xhr.abort()
      @data_load_xhr = null

    if @data_load_timer
      clearTimeout @data_load_timer

    @aborted = true

  startDataLoadTimer: =>
    console.log 'started'
    if @data_load_timer
      clearTimeout @data_load_timer

    @data_load_timer = setTimeout(() =>
      @loadUpdates()
    , @data_load_timing)

  startConnectionTestTimer: =>
    @connection_test_timer = setTimeout @testConnection, @connection_test_timing
    return

  testConnection: =>
    is_connected = =>
      $.get(@connection_test_url)

    is_connected().done(() =>
      @consecutive_failures = 0
      @startConnectionTestTimer()
      return true

    ).fail((jqXHR, error_textStatus, errorThrown) =>
      @consecutive_failures++
      if @consecutive_failures > @failures_before_airplane_mode 
        @lj.airplane_mode.activate()
        @attemptReconnect()
      else
        # try again, but quicker this time
        setTimeout @testConnection, @connection_retest_timing
    )

  # used when trying to get back in touch with server
  # while in airplane mode
  attemptReconnect: =>
    is_connected = =>
      $.get(@connection_test_url)

    is_connected().done(() =>
      @consecutive_failures = 0
      @startConnectionTestTimer()
      # airplane_mode.deactivate will eventually
      # restart live sync.
      @lj.airplane_mode.deactivate()
      return true

    ).fail((jqXHR, error_textStatus, errorThrown) =>
      setTimeout @attemptReconnect, @connection_retest_timing
    )
