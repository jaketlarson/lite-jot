class JotsController < ApplicationController
  def create
    if params[:topic_id].nil? || params[:topic_id].to_i <= 0 || current_user.topics.find(params[:topic_id]).nil?
      time = Time.new
      topic = current_user.topics.new
      topic.title = "Untitled on #{time.strftime('%b %d')}"
      topic.save
    else
      folder = current_user.folders.find(params[:folder_id])
      folder.touch
      topic = current_user.topics.find(params[:topic_id])
      topic.touch
    end

    jot = current_user.jots.new(jot_params)

    if jot.save
      render :json => {:jot => jot}

    else
      render :text => 'not okay', :status => 409
    end
  end

  def update
    jot = Jot.find(params[:id])

    if jot.update(jot_params)
      topic = current_user.topics.find(jot.topic_id)
      topic.touch
      folder = current_user.folders.find(topic.folder_id)
      folder.touch

      render :text => 'success'

    else
      render :text => 'error', :status => 409
    end
  end

  def destroy
    jot = Jot.find(params[:id])

    if jot.destroy
      render :json => {:success => true}
    else
      render :json => {:success => false}, :status => :bad_request
    end
  end

  protected

    def jot_params
      params.permit(:id, :content, :topic_id, :folder_id, :is_highlighted)
    end
end
