#= require litejot

class window.PushUI extends LiteJot
  constructor: (@lj) ->
    @initVars()

  initVars: =>
    console.log 'load'

  mergeData: =>
    @mergeJots $.extend([], @lj.temp.jots)

  mergeJots: (v_server) =>
    # v_server represents server version of data
    # v_client represents client version of data
    v_client = $.extend [], @lj.app.jots
    v_client = @lj.app.jots
    keys_to_delete = []

    # Check for modifications & deletes
    # If found, update client-side @app data.
    $.each v_client, (c_jot_key, c_jot) =>
      # c_jot => client side jot data
      # s_jot => server side jot data
      jot_updated = false
      s_jot = v_server.filter((jot_check) => jot_check.id == c_jot.id)

      if s_jot.length == 0
        # No longer exists on server, add to delete queue
        keys_to_delete.push c_jot_key

        # If this is on the current topic, then remove from DOM
        if @lj.app.current_topic == c_jot.topic_id
          @lj.jots.vanish c_jot.id

        return

      s_jot = s_jot[0]
      $.each c_jot, (key, value) =>
        if c_jot[key] != s_jot[key]
          console.log "um #{key}=#{c_jot[key]} != #{key}=#{s_jot[key]}"
          c_jot[key] = s_jot[key]
          jot_updated = true

      if jot_updated && @lj.app.current_topic == c_jot.topic_id
        @lj.jots.updateJotElem c_jot

      # Since this server-side jot (s_jot) was scanned over,
      # a property 'touched' is added. This is less expensive
      # than going through, finding it, and deleting it, for each jot.
      # This way it can be ignored on the final loop through
      # for brand new jots.
      s_jot.touched = true

    # if keys_to_delete.length > 0
    #   $.each keys_to_delete, (index, key) =>
    #     v_client.remove key
    #     console.log key

    # Any jots without the property 'touched' in v_server means they are new
    # Append remaining jots to actual client-side @app data.
    $.each v_server, (key, s_jot) =>
      any_new = false
      if !s_jot.touched
        any_new = true
        v_client.push s_jot
        if @lj.app.current_topic == s_jot.topic_id
          console.log "inserting: "
          console.log s_jot
          @lj.jots.insertJotElem s_jot
          console.log key

      if any_new
        @lj.jots.scrollJotsToBottom()

        # Check if jots empty.. this function handles the empty message, etc.
        @lj.jots.checkIfJotsEmpty()
