class TopicsController < ApplicationController

  def create
    folder_autogenerated = false

    if params[:folder_id].nil? || params[:folder_id].to_i <= 0 || current_user.folders.find(params[:folder_id]).nil?
      time = Time.new
      folder = current_user.folders.new
      folder.title = "New #{time.strftime('%b %d')}"
      folder.save
      folder_id = folder.id

      folder_autogenerated = true
    else
      folder_id = params[:folder_id]
    end

    topic = current_user.topics.new(topic_params)
    topic.folder_id = folder_id
    
    if topic.save
      unless folder_autogenerated
        ser_topic = TopicSerializer.new(topic, :root => false, :scope => current_user)
        render :json => {:success => true, :topic => ser_topic}
      else
        ser_topic = TopicSerializer.new(topic, :root => false, :scope => current_user)
        ser_folder = FolderSerializer.new(folder, :root => false, :scope => current_user)
        render :json => {:success => true, :topic => ser_topic, :auto_folder => ser_folder}
      end
    else
      render :json => {:success => false}, :status => :bad_request
    end
  end

  def update
    topic = current_user.topics.find(params[:id])

    # temporarily turn off since updated_at controls order of topics in UI
    Topic.record_timestamps = false
    
    if topic.user_id == current_user.id
      if topic.update(topic_params)
        ser_topic = TopicSerializer.new(topic, :root => false, :scope => current_user)
        render :json => {:success => true, :topic => ser_topic}
      else
        render :json => {:success => false}, :status => :bad_request
      end
    else
      render :json => {:success => false, :error => "You do not have permission to modify this topic."}, :status => :bad_request
    end

    Topic.record_timestamps = true
  end

  def destroy
    topic = Topic.find(params[:id])

    # Do a check to see if there are no jots (including archived)
    # existing in topic. If not, really_destroy! (paranoia gem) the topic
    topic_empty = Jot.with_deleted.where('topic_id = ?', topic.id).empty? ? true : false

    if topic.user_id == current_user.id
      if topic.destroy
        if topic_empty
          topic.really_destroy!
        end

        render :json => {:success => true, :message => "Topic and it's contents moved to trash."}
      else
        render :json => {:success => false, :error => "Could not delete topic."}, :status => :bad_request
      end
    else
      render :json => {:success => false, :error => "You do not have permission to delete this topic."}, :status => :bad_request
    end
  end

  protected

    def topic_params
      params.permit(:title, :folder_id)
    end
end
