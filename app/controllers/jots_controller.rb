class JotsController < ApplicationController
  def create
    if params[:topic_id].nil? || params[:topic_id].to_i <= 0 || current_user.topics.find(params[:topic_id]).nil?
      time = Time.new
      topic = current_user.topics.new
      topic.title = "Untitled on #{time.strftime('%b %d')}"
      topic.save
      puts 'cool'
    else
      topic = current_user.topics.find(params[:topic_id])
      topic.touch
    end

    jot = current_user.jots.new(jot_params)
    jot.topic_id = topic.id

    if jot.save
      render :json => {:jot => jot}

    else
      render :text => 'not okay', :status => 409
    end
  end

  protected

    def jot_params
      params.permit(:content, :topic_id, :folder_id)
    end
end
