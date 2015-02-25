class FoldersController < ApplicationController
  def index
    folders = current_user.folders
    topics = current_user.topics.order('updated_at desc')
    jots = current_user.jots

    json = {:folders => folders, :topics => topics, :jots => jots}

    render :json => json
  end
end
