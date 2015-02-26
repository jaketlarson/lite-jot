class TopicsController < ApplicationController
  def index
    topics = current_user.topics.order('updated_at desc')
    render :json => [:topics => topics]
  end
end
