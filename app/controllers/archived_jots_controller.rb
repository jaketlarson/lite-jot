class ArchivedJotsController < ApplicationController
  # This controller is used for jot recovery.
  # The `paranoia` gem doesn't actually delete records,
  # it just hides it from the regular database queries,
  # perfect for the jot recovery implementation.
  # ArchivedJotsController uses the Jot model, but is
  # kept out of JotsController.rb to keep the logic
  # separate.

  def index
    jots = Jot.unscoped.where('user_id = ?', current_user.id).only_deleted.order('deleted_at DESC')
    serialized_jots = ActiveModel::ArraySerializer.new(jots, :each_serializer => ArchivedJotSerializer, :scope => current_user)
    render :json => {:archived_jots => serialized_jots}
  end

  def destroy
    ids = archived_jot_params[:ids]
    jots = Jot.only_deleted.where(:id => ids)

    # Init arrays of topic/folder ids, to be checked for emptiness
    # after jots are deleted.
    check_topics = []
    check_folders = []

    jots.each do |jot|
      # Make sure the associated topic and folder is added to
      # the list of topics/folders to be checked for emptiness
      if !check_topics.include? jot.topic_id
        check_topics << jot.topic_id

        if !check_folders.include? jot.folder_id
          check_folders << jot.folder_id
        end
      end

      jot.really_destroy!
    end

    # Loop through topics, perma-delete what's archived and completely empty
    check_topics.each do |id|
      topic = Topic.only_deleted.where("id = ?", id)
      if topic.count == 1
        jots = Jot.with_deleted.where("topic_id = ?", id)
        if jots.count == 0
          # Then delete topic
          topic[0].really_destroy!
        end
      end
    end

    # Loop through folders, perma-delete what's archived and completely empty
    check_folders.each do |id|
      folder = Folder.only_deleted.where("id = ?", id)
      if folder.count == 1
        jots = Jot.with_deleted.where("folder_id = ?", id)
        if jots.count == 0
          # Then delete folder and its remaining topics
          folder[0].topics.each do |topic|
            topic.really_destroy!
          end

          folder[0].really_destroy!
        end
      end
    end

    render :status => 200, :nothing => true
  end

  def restore
    ids_requested = archived_jot_params[:ids]
    ids_actually_restored = []

    # Restore any topics or folders that were also archived
    ids_requested.each do |id|
      jot = Jot.only_deleted.where("id = ?", id)

      if !jot.empty?
        jot = jot[0]
        # Check if folder and topic even exist. Also check if shared folder
        # (vs owned folder)
        topic_check = Topic.with_deleted.where('id = ?', jot.topic_id)
        folder_check = Folder.with_deleted.where('id = ?', jot.folder_id)

        # Check if folder is shared with user
        if !folder_check.empty? && !topic_check.empty? && folder_check[0].user_id != current_user.id
          # It is shared with them.. so let's make sure they
          # still have access to this folder
          share = Share.where('recipient_id = ? AND folder_id = ?', current_user.id, folder_check[0].id)
          if share.empty?
            # They are not shared with this folder any longer..
            # We can't restore this jot.
            next
          end
        elsif folder_check.empty? || topic_check.empty?
          # Folder or topic doesn't exist.
          next
        end

        # While restoring jot, make sure folder and topic are also active.
        deleted_topic = Topic.only_deleted.where("id = ?", jot.topic_id)
        deleted_folder = Folder.only_deleted.where("id = ?", jot.folder_id)
        if !deleted_topic.empty?
          Topic.restore(deleted_topic[0].id)
        end
        if !deleted_folder.empty?
          Folder.restore(deleted_folder[0].id)
        end
      end

      # This jot will be restored
      ids_actually_restored << id
    end

    # Restore jots
    Jot.restore(ids_actually_restored)

    if ids_actually_restored.count == ids_requested.count
      # All the jots requested were successfully deleted.
      render :status => 200, :json => {:all_jots_restored => true, :ids => ids_actually_restored}
    else
      # More than one jot not restored, probably due to no-longer-shared-with
      # -folder situation.
      render :status => 207, :json => {:all_jots_restored => false, :ids => ids_actually_restored}
    end
  end

  protected

    def archived_jot_params
      params.permit(:ids => [])
    end
end