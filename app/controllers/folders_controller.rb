class FoldersController < ApplicationController

  def create
    folder = current_user.folders.new(folder_params)

    if folder.save
      ser_folder = FolderSerializer.new(folder, :root => false, :scope => current_user)
      render :json => {:success => true, :folder => ser_folder}
    else
      render :json => {:success => false}, :status => :bad_request
    end
  end

  def update
    folder = Folder.find(params[:id])

    # temporarily turn off since updated_at controls order of folders in UI
    Folder.record_timestamps = false
    
    if folder.user_id == current_user.id
      if folder.update(folder_params)
        ser_folder = FolderSerializer.new(folder, :root => false, :scope => current_user)
        render :json => {:success => true, :folder => ser_folder}
      else
        render :json => {:success => false}, :status => :bad_request
      end
    else
      render :json => {:success => false, :error => "You do not have permission to modify this folder."}, :status => :bad_request
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
