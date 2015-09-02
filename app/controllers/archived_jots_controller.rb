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
    ids = archived_jot_params[:ids]

    # Restore any topics or folders that were also archived
    ids.each do |id|
      jot = Jot.only_deleted.where("id = ?", id)

      if !jot.empty?
        jot = jot[0]
        topic = Topic.only_deleted.where("id = ?", jot.topic_id)
        folder = Folder.only_deleted.where("id = ?", jot.folder_id)

        if !topic.empty?
          Topic.restore(topic[0].id)
        end

        if !folder.empty?
          Folder.restore(folder[0].id)
        end
      end
    end

    # Restore all jots in id list.
    Jot.restore(ids)

    render :status => 200, :nothing => true
  end

  protected

    def archived_jot_params
      params.permit(:ids => [])
    end
end