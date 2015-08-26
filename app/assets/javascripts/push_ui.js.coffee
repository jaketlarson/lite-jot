#= require litejot

class window.PushUI extends LiteJot
  constructor: (@lj) ->
    @initVars()

  initVars: =>
    console.log 'load'

  mergeData: =>
    console.log 'merge'
    @mergeJots $.extend([], @lj.temp.jots)
    @mergeTopics $.extend([], @lj.temp.topics)
    @mergeFolders $.extend([], @lj.temp.folders)
    @mergeShares $.extend([], @lj.temp.shares)

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

        # If this is on the current topic, then remove from DOM
        # @lj.jots.vanish will take care of the data removal.
        if @lj.app.current_topic == c_jot.topic_id
          @lj.jots.vanish c_jot.id
        else
          # @lj.jots.vanish won't help here, add to delete queue
          keys_to_delete.push c_jot_key

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
      # a property 'checked' is added. This is less expensive
      # than going through, finding it, and deleting it, for each jot.
      # This way it can be ignored on the final loop through
      # for brand new jots.
      s_jot.checked = true

    if keys_to_delete.length > 0
      $.each keys_to_delete, (index, key) =>
        v_client.remove key
        console.log key

    # Any jots without the property 'checked' in v_server means they are new
    # Append remaining jots to actual client-side @app data.
    $.each v_server, (key, s_jot) =>
      any_new = false
      if !s_jot.checked
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

  mergeTopics: (v_server) =>
    # v_server represents server version of data
    # v_client represents client version of data
    v_client = $.extend [], @lj.app.topics
    v_client = @lj.app.topics
    keys_to_delete = []
    topics_deleted = 0

    # Check for modifications & deletes
    # If found, update client-side @app data.
    $.each v_client, (c_topic_key, c_topic) =>
      # c_topic => client side topic data
      # s_topic => server side topic data
      topic_updated = false
      s_topic = v_server.filter((topic_check) => topic_check.id == c_topic.id)

      if s_topic.length == 0
        # If this is on the current folder, then remove from DOM
        # @lj.topics.vanish will take care of the data removal.
        topics_deleted++
        if @lj.app.current_folder == c_topic.folder_id
          @lj.topics.vanish c_topic.id
        else
          # @lj.topics.vanish won't help here, add to delete queue
          keys_to_delete.push c_topic_key

        return

      s_topic = s_topic[0]
      $.each c_topic, (key, value) =>
        if c_topic[key] != s_topic[key]
          console.log "um #{key}=#{c_topic[key]} != #{key}=#{s_topic[key]}"
          c_topic[key] = s_topic[key]
          topic_updated = true

      if topic_updated && @lj.app.current_folder == c_topic.folder_id
        # 'touched' means the topic was updated
        s_topic.touched = true
        @lj.topics.updateTopicElem c_topic

      # Since this server-side topic (s_topic) was scanned over,
      # a property 'checked' is added. This is less expensive
      # than going through, finding it, and deleting it, for each topic.
      # This way it can be ignored on the final loop through
      # for brand new topics.
      s_topic.checked = true

    if keys_to_delete.length > 0
      $.each keys_to_delete, (index, key) =>
        v_client.remove key
        console.log key

    # Any topics without the property 'checked' in v_server means they are new
    # Append remaining topics to actual client-side @app data.
    $.each v_server, (key, s_topic) =>
      any_new = false
      if !s_topic.checked
        any_new = true
        v_client.push s_topic
        if @lj.app.current_folder == s_topic.folder_id
          @lj.topics.insertTopicElem s_topic

    # Check if sortTopicList is necessary..
    any_topics_added_or_edited = v_server.filter((s_topic) => !s_topic.checked || s_topic.touched).length > 0
    any_topics_deleted = topics_deleted > 0
    if any_topics_added_or_edited || any_topics_deleted
      # Make sure topic data is sorted by date
      @lj.topics.sortTopicsList true, true

  mergeFolders: (v_server) =>
    # v_server represents server version of data
    # v_client represents client version of data
    v_client = $.extend [], @lj.app.folders
    v_client = @lj.app.folders
    folders_deleted = 0

    # Check for modifications & deletes
    # If found, update client-side @app data.
    $.each v_client, (c_folder_key, c_folder) =>
      # c_folder => client side folder data
      # s_folder => server side folder data
      folder_updated = false
      s_folder = v_server.filter((folder_check) => folder_check.id == c_folder.id)

      if s_folder.length == 0
        folders_deleted++
        @lj.folders.vanish c_folder.id
        return

      s_folder = s_folder[0]
      $.each c_folder, (key, value) =>
        if c_folder[key] != s_folder[key]
          console.log "um #{key}=#{c_folder[key]} != #{key}=#{s_folder[key]}"
          c_folder[key] = s_folder[key]
          folder_updated = true

      @lj.folders.updateFolderElem c_folder

      # Since this server-side folder (s_folder) was scanned over,
      # a property 'checked' is added. This is less expensive
      # than going through, finding it, and deleting it, for each folder.
      # This way it can be ignored on the final loop through
      # for brand new folders.
      s_folder.checked = true

    # Any folders without the property 'checked' in v_server means they are new
    # Append remaining folders to actual client-side @app data.
    $.each v_server, (key, s_folder) =>
      any_new = false
      if !s_folder.checked
        any_new = true
        v_client.push s_folder
        @lj.folders.insertFolderElem s_folder

    # Check if sortFolderList is necessary..
    any_folders_added_or_edited = v_server.filter((s_folder) => !s_folder.checked || s_folder.touched).length > 0
    any_folders_deleted = folders_deleted > 0
    if any_folders_added_or_edited || any_folders_deleted
      # Make sure folder data is sorted by date
      @lj.folders.sortFoldersList true, true

  mergeShares: (v_server) =>
    @lj.app.shares = $.extend([], v_server)
