#= require litejot

class window.PushUI extends LiteJot
  constructor: (@lj) ->


  mergeData: =>
    # Merge folders, topics, then jots.
    # This order is necessary, because when, during a merge,
    # a folder is flagged as deleted, it calls the vanish function.
    # The vanish function for folders deletes topics, and then jots.
    # The functionality is similar for topics.
    # This way, the merging and vanishing process doesn't clash.
    # It would clash if you were deleting a folder with topics/jots,
    # and the jots were being merged and the keys were being
    # checked against that weren't actually there anymore.
    # It also makes more sense to start from the root.




    @mergeJots($.extend([], @lj.temp.new_or_updated_jots), $.extend([], @lj.temp.deleted_jots))
    @mergeTopics($.extend([], @lj.temp.new_or_updated_topics), $.extend([], @lj.temp.deleted_topics))
    @mergeFolders($.extend([], @lj.temp.new_or_updated_folders), $.extend([], @lj.temp.deleted_folders))
    # @mergeTopics $.extend([], @lj.temp.topics)
    # @mergeJots $.extend([], @lj.temp.jots)
    #@mergeShares $.extend([], @lj.temp.shares)
    @mergeUser @lj.temp.user

    # Destroy temp data
    @lj.resetTempData()

  mergeJots: (new_or_updated, deleted) =>
    # v_client represents client version of data
    v_client = @lj.app.jots

    # Delete jots from client
    $.each deleted, (index, jot) =>
      # If this is on the current topic, then remove from DOM
      # @lj.jots.vanish will take care of the data removal.
      if @lj.app.current_topic == jot.topic_id
        @lj.jots.vanish jot.id
      else
        @lj.jots.removeJotFromDataById jot.id

    any_new = false
    $.each new_or_updated, (s_jot_key, s_jot) =>
      # c_jot => client side jot data
      # s_jot => server side jot data

      # Not sure if this is necessary
      # if !s_jot # Check in the case of s_jot being null
      #   return

      c_jot = v_client.filter((jot_check) => jot_check.id == s_jot.id)
      s_jot_copy = $.extend({}, s_jot)

      if c_jot.length == 0
        # This is a new jot
        any_jots_added_or_edited = true
        v_client.push s_jot_copy
        console.log 'added:'
        console.log s_jot

        if @lj.app.current_topic == s_jot.topic_id && !@isSearching()
          # Check to see that this jot is the newest, or if
          # it should be inserted before the correct jot
          older_jots = @lj.app.jots.filter((jot) =>
            jot.created_at_unix > s_jot.created_at_unix && jot.topic_id == s_jot.topic_id
          )

          if older_jots.length > 0
            succeeding_jot = older_jots[0]
            elem = @lj.jots.jots_list.find("li[data-jot='#{succeeding_jot.id}']")
            if elem.length == 1
              @lj.jots.insertJotElem s_jot_copy, method='before', before_id=succeeding_jot.id, flash=true

            # Data stored to client is not in order.. resort
            @lj.jots.sortJotData()
          else
            @lj.jots.insertJotElem s_jot_copy, method='append', before_id=null, flash=true

      else
        # This is an updated jot
        # Remove the old version, insert the old version, and update the jot elem
        @lj.jots.removeJotFromDataById c_jot[0].id
        v_client.push s_jot_copy
        if @lj.app.current_topic == s_jot_copy.topic_id && !@isSearching()
          @lj.jots.updateJotElem s_jot_copy


    if any_new
      @lj.jots.scrollJotsToBottom()

      # Check if jots empty.. this function handles the empty message, etc.
      @lj.jots.checkIfJotsEmpty()

  mergeTopics: (new_or_updated, deleted) =>
    # v_client represents client version of data
    v_client = @lj.app.topics

    any_topics_added_or_edited = false
    any_topics_deleted = false

    # Delete topics from client
    $.each deleted, (index, topic) =>
      any_topics_deleted = true
      @lj.topics.vanish topic.id

    $.each new_or_updated, (s_topic_key, s_topic) =>
      # Not sure if this is necessary
      # if !s_topic # Check in the case of s_topic being null
      #   return

      c_topic = v_client.filter((topic_check) => topic_check.id == s_topic.id)
      s_topic_copy = $.extend({}, s_topic)

      if c_topic.length == 0
        # This is a new topic
        any_topics_added_or_edited = true
        v_client.push s_topic_copy
        console.log 'added:'
        console.log s_topic

        if @lj.app.current_folder == s_topic.folder_id && !@isSearching()
          @lj.topics.insertTopicElem s_topic_copy
          @lj.topics.initTopicBinds s_topic_copy.id

      else
        # This is an updated topic
        # Find current version in data, remove it, and add new version
        topic_key = null
        $.each @lj.app.topics, (index, topic) =>
          if topic.id == c_topic.id
            topic_key = index
            return false

        @lj.app.topics.remove topic_key
        v_client.push s_topic_copy

        if @lj.app.current_folder == s_topic_copy.folder_id
          @lj.topics.updateTopicElem s_topic_copy

    if (any_topics_added_or_edited || any_topics_deleted) && !@isSearching()
      # Make sure topic data is sorted by date
      @lj.topics.sortTopicsList true, true

  mergeFolders: (new_or_updated, deleted) =>
    # v_client represents client version of data
    v_client = @lj.app.folders

    any_folders_added_or_edited = false
    any_folders_deleted = false

    # Delete folders from client
    $.each deleted, (index, folder) =>
      console.log "deleting folder #{folder.title}"
      any_folders_deleted = true
      @lj.folders.vanish folder.id

    $.each new_or_updated, (s_folder_key, s_folder) =>
      # Not sure if this is necessary
      # if !s_folder # Check in the case of s_folder being null
      #   return

      c_folder = v_client.filter((folder_check) => folder_check.id == s_folder.id)
      s_folder_copy = $.extend({}, s_folder)

      if c_folder.length == 0
        # This is a new folder
        any_folders_added_or_edited = true
        v_client.push s_folder_copy
        console.log 'added:'
        console.log s_folder

        if !@isSearching()
          @lj.folders.insertFolderElem s_folder_copy
          @lj.folders.initFolderBinds s_folder_copy.id

      else
        # This is an updated folder
        # Find current version in data, remove it, and add new version
        folder_key = null
        $.each @lj.app.folders, (index, folder) =>
          if folder.id == c_folder.id
            folder_key = index
            return false

        @lj.app.folders.remove folder_key
        v_client.push s_folder_copy
        @lj.folders.updateFolderElem s_folder_copy


    if (any_folders_added_or_edited || any_folders_deleted) && !@isSearching()
      # Make sure folder data is sorted by date
      @lj.folders.sortFoldersList true, true

  mergeShares: (v_server) =>
    @lj.app.shares = $.extend([], v_server)

  mergeUser: (v_server) =>
    if v_server.display_name != @lj.app.user.display_name
      update_display_name = true
      
    @lj.app.user = v_server
    if update_display_name
      @lj.user_settings.updateHeaderDisplayName()

  isSearching: =>
    @lj.search.current_terms.length > 0
