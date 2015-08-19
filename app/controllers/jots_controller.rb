class JotsController < ApplicationController

  def create
    # Because the Emergency Mode feature allows users to jot while without internet, those jots need to be
    # sent back to the server eventually, and the most logical way would be as a collection, instead of x
    # number of jots#create requests for x number of jots.
    # This method will take into account the possibility of many jots, and if so, the way the responses
    # render out will be different.
    # In case of errors and many_jots, the jots (content) and it's errors will be compiled for the user.
    # Even if it is a single jot submission (and it typically is), this jot is put into a one-item collection
    # and iterated through in a for loop to keep the code DRY and less complicated.

    jot_collection = params[:jots]
    jots = []

    if jot_collection
      many_jots = true
      error_list = []
      jot_collection = jot_collection.values
      jot_collection.each do |jot|
        jots << current_user.jots.new(jot.symbolize_keys)
      end
    else
      many_jots = false
      jots << current_user.jots.new(jot_params)
    end

    new_folder = nil # only if autogenerated
    new_topic = nil # only if autogenerated
    ser_folder = nil
    ser_topic = nil
    ser_jots = [] # notice plural, used in case of many_jots


    jots.each do |jot|
      # check if typing a jot for a shared folder
      # this is to prevent users from typing a jot to auto-create
      # a topic in a folder that is shared with them
      folder_is_owned = true
      folder_empty = false
      if !jot.folder_id.nil? && jot.folder_id.to_i > 0
        folder_check = Folder.where('id = ?', jot.folder_id)
        if !folder_check.empty?
          if folder_check[0].user_id != current_user.id
            folder_is_owned = false
            folder_is_empty = folder_check[0].topics.count == 0 ? true : false
          end
        end
      end

      if !folder_is_owned && folder_is_empty
        error_text = "Jots cannot be created an empty folder shared with you."
        unless many_jots
          render :json => {:success => false, :error => error_text}, :status => :bad_request
          return
        else
          error_list << {:content => jot.content, :error => error_text}
          next
        end
      end
      # end check

      if jot.folder_id.nil? || jot.folder_id.to_i <= 0 || Folder.where('id = ?', jot.folder_id).empty?
        if new_folder # was already generated from another jot in the collection
          folder_id = new_folder.id
        else
          time = Time.new
          folder = current_user.folders.new
          folder.title = "New #{time.strftime('%b %d')}"
          folder.save

          new_folder = folder
          folder_id = folder.id
        end
      else
        folder_id = jot.folder_id
      end

      if jot.topic_id.nil? || jot.topic_id.to_i <= 0 || Topic.where('id = ?', jot.topic_id).empty?
        if new_topic # was already generated from another jot in the collection
          topic_id = new_topic.id
        else
          time = Time.new
          topic = current_user.topics.new
          topic.title = "New #{time.strftime('%b %d')}"
          topic.save

          new_topic = topic
          topic_id = topic.id
        end
      else
        topic_id = jot.topic_id
      end

      folder = Folder.find(folder_id)
      if !new_folder
        folder.touch
      end

      topic = Topic.find(topic_id)
      topic.folder_id = folder_id
      topic.save
      if !new_topic
        topic.touch
      end

      jot.folder_id = folder_id
      jot.topic_id = topic_id

      if jot.save
        if new_topic && new_folder
          ser_jot = JotSerializer.new(jot, :root => false, :scope => current_user)
          ser_topic = TopicSerializer.new(topic, :root => false, :scope => current_user)
          ser_folder = FolderSerializer.new(folder, :root => false, :scope => current_user)

          unless many_jots
            render :json => {:success => true, :jot => ser_jot, :auto_folder => ser_folder, :auto_topic => ser_topic}
          else
            ser_jots << ser_jot
          end
        
        elsif !new_topic && new_folder
          ser_jot = JotSerializer.new(jot, :root => false, :scope => current_user)
          ser_folder = FolderSerializer.new(folder, :root => false, :scope => current_user)

          unless many_jots
            render :json => {:success => true, :jot => ser_jot, :auto_folder => ser_folder}
          else
            ser_jots << ser_jot
          end
        
        elsif new_topic && !new_folder
          ser_jot = JotSerializer.new(jot, :root => false, :scope => current_user)
          ser_topic = TopicSerializer.new(topic, :root => false, :scope => current_user)

          unless many_jots
            render :json => {:success => true, :jot => ser_jot, :auto_topic => ser_topic}
          else
            ser_jots << ser_jot
          end
        
        else
          ser_jot = JotSerializer.new(jot, :root => false, :scope => current_user)
          unless many_jots
            render :json => {:success => true, :jot => ser_jot}
          else
            ser_jots << ser_jot
          end
        end
      else
        error_text = "Could not save jot."
        unless many_jots
          render :json => {:success => false, :error => error_text}, :status => :bad_request
        else
          error_list << {:content => jot.content, :jot_type => jot.jot_type, :break_from_top => jot.break_from_top, :error => error_text}
        end
      end
    end

    if many_jots
      render :json => {:success => true, :error_list => error_list, :jots => ser_jots, :folder => ser_folder, :topic => ser_topic}
      ap error_list
      ap ser_topic
      ap ser_folder
      ap ser_jots
    end
  end

  def update
    jot = Jot.find(params[:id])

    topic = Topic.find(jot.topic_id)
    folder = Folder.find(topic.folder_id)

    # check permissions
    can_modify = false
    if jot.user_id == current_user.id
      # they are the jot owner
      can_modify = true
    elsif folder.user_id == current_user.id
      # they are the folder owner, so they can modify what shared users contribute
      can_modify = true
    end

    if can_modify
      if jot.update(jot_params)
        if topic
          topic.touch
        end
        if folder
          folder.touch
        end
        ser_jot = JotSerializer.new(jot, :root => false, :scope => current_user)
        render :json => {:success => true, :jot => ser_jot}

      else
        render :json => {:success => false}, :status => :bad_request
      end
    else
      render :json => {:success => false, :error => "You do not have permission to modify this jot."}, :status => :bad_request
    end
  end

  def destroy
    jot = Jot.find(params[:id])

    can_delete = false
    if jot.user_id == current_user.id
      can_delete = true
    else
      # check if they are the owner of the folder this jot is in
      folder = Folder.find(jot.folder_id)
      if folder.user_id == current_user.id
        can_delete = true
      end
    end

    if can_delete
      if jot.destroy
        render :json => {:success => true, :message => "Jot moved to trash."}
      else
        render :json => {:success => false, :error => "Could not delete jot."}, :status => :bad_request
      end
    else
      render :json => {:success => false, :error => "You do not have permission to delete this jot."}, :status => :bad_request
    end

  end

  protected

    def jot_params
      params.permit(:id, :content, :topic_id, :folder_id, :is_flagged, :jot_type, :break_from_top, :jots => [:id, :content, :topic_id, :folder_id, :jot_type, :break_from_top, :temp_key])
    end
end
