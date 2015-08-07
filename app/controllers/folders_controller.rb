class FoldersController < ApplicationController
  def index
    folders = current_user.folders.order('updated_at desc')

    render :json => folders, :each_serializer => FolderSerializer
  end

  def create
    folder = current_user.folders.new(folder_params)

    if folder.save
      render :json => {:folder => folder}
    else
      render :text => 'error', :status => 409
    end
  end

  def update
    folder = current_user.folders.find(params[:id])

    # temporarily turn off since updated_at controls order of folders in UI
    Folder.record_timestamps = false
    
    if folder.update(folder_params)
      render :text => 'success'
    else
      render :text => 'error', :status => 409
    end

    Folder.record_timestamps = true
  end

  def destroy
    folder = Folder.find(params[:id])

    if folder.user_id == current_user.id
      if folder.destroy
        render :json => {:success => true, :message => "Folder and it's contents moved to trash."}
      else
        render :json => {:success => false, :error => "Could not delete jot."}, :status => :bad_request
      end
    else
      render :json => {:success => false, :error => "You do not have permission to delete this folder."}, :status => :bad_request
    end
  end

  protected

    def folder_params
      params.permit(:title)
    end
end
