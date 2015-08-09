#= require litejot

class window.Connection extends LiteJot
  constructor: (@lj) ->
    @initVars()

  initVars: =>
    @connection_test_timer = null
    @connection_test_timing = 2000
    @conntection_test_url = '/connection-test'
    @connection_test_url = "https://qrng.anu.edu.au/API/jsonI.php?length=1&type=uint8"

    # if the connection test fails, and there are allowed
    # retrials, this timer will be used to more quickly
    # retest the connection.
    # also used in reattempt to reconnect
    @connection_retest_timing = 500

    # Number of times the connect test fails
    # before entering emergency mode. If set to one,
    # the connection test may only fail once consecutively
    @failures_before_emergency_mode = 1
    @consecutive_failures = 0

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

    ).fail(() =>
      @consecutive_failures++
      if @consecutive_failures > @failures_before_emergency_mode 
        @lj.emergency_mode.activate()
        @attemptReconnect()
      else
        # try again, but quicker this time
        setTimeout @testConnection, @connection_retest_timing
    )

  # used when trying to get back in touch with server
  # while in emergency mode
  attemptReconnect: =>
    is_connected = =>
      $.get(@connection_test_url)

    is_connected().done(() =>
      @consecutive_failures = 0
      @startConnectionTestTimer()
      @lj.emergency_mode.deactivate()
      return true

    ).fail(() =>
      setTimeout @attemptReconnect, @connection_retest_timing
    )
