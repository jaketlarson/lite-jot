class FoldersController < ApplicationController

  def create
    folder = current_user.folders.new(folder_params)
    folder.title = ActionView::Base.full_sanitizer.sanitize(folder.title)

    if folder.save
      ser_folder = FolderSerializer.new(folder, :root => false, :scope => current_user)
      render :json => {:success => true, :folder => ser_folder}
    else
      render :json => {:success => false}, :status => :bad_request
    end
  end

  def update
    folder = Folder.find(params[:id])
    folder.title = ActionView::Base.full_sanitizer.sanitize(folder.title)

    # # temporarily turn off since updated_at controls order of folders in UI
    # Folder.record_timestamps = false
    
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

    # Folder.record_timestamps = true
  end

  def destroy
    folder = Folder.find(params[:id])

    # Do a check to see if there are no jots (including archived)
    # existing in folder. If not, set the perm_deleted field instead of
    # really_destroy! (paranoia gem). Routine garbage collection can be
    # done later, but it is best not to completely delete items
    # immediately as this can mess with syncing.
    folder_empty = Jot.with_deleted.where('folder_id = ?', folder.id).empty? ? true : false

    if folder.user_id == current_user.id
      if folder.destroy

        if folder_empty
          folder.topics.each do |topic|
            topic.perm_deleted = true
            topic.save
            # topic.really_destroy!
          end
          folder.perm_deleted = true
          folder.save
          # folder.really_destroy!
        end

        render :json => {:success => true, :message => "Folder and its contents moved to trash."}
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
