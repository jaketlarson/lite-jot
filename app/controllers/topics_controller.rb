class TopicsController < ApplicationController
  def index
    topics = current_user.topics.order('updated_at desc')
    render :json => [:topics => topics]
  end

  def update
    topic = Topic.find(params[:id])

    # temporarily turn off since updated_at controls order of topics in UI
    Topic.record_timestamps = false
    
    if topic.update(topic_params)
      render :text => 'success'
    else
      render :text => 'error', :status => 409
    end

    Topic.record_timestamps = true
  end


  protected

    def topic_params
      params.permit(:title)
    end
end
