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

    # Do a check to see if there are no jots (including archived)
    # existing in folder. If not, really_destroy! (paranoia gem) the topic
    folder_empty = Jot.with_deleted.where('folder_id = ?', folder.id).empty? ? true : false

    if folder.user_id == current_user.id
      if folder.destroy

        if folder_empty
          folder.topics.each do |topic|
            topic.really_destroy!
          end
          folder.really_destroy!
        end

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
