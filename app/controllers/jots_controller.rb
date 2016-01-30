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

      # MOVE INTO SEPARATE MODEL METHOD
      # If checklist, append random IDs.
      if jot.jot_type == 'checklist'
        checklist = JSON.parse(jot.content)
        checklist.each do |item|
          # Using a random ID generator for now..
          # Move this into a separate method. Same for #update (same line)
          rid = 16.times.map { [*'0'..'9', *'a'..'z', *'A'..'Z'].sample }.join
          item['id'] = rid
        end
        jot.content = checklist.to_json
      end

      jot.content = ActionView::Base.full_sanitizer.sanitize(jot.content)

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
    end
  end

  def update
    params = jot_params
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

      # Checklists need special attention as items have IDs
      # We don't want to override an entire jot checklist's meta (such as the
      # toggled-by information)
      if params['jot_type'] == 'checklist'
        begin
          old_version = JSON.parse(jot['content'])
        rescue # Could be converted to a checklist from a different type
          old_version = jot['content']
        end
        new_version = JSON.parse(params['content'])
        new_version.each do |new_item|
          # This item is new! Let's give it an ID
          if new_item['id'].length == 0
            new_item['id'] = 16.times.map { [*'0'..'9', *'a'..'z', *'A'..'Z'].sample }.join
          else
            get_old = old_version.select {|old_item| old_item['id'] == new_item['id'] }[0]
            # Carry over or update checkbox-toggled info
            if new_item['checked'] != get_old['checked']
              new_item['toggled_by'] = current_user.id
              new_item['toggled_at'] = DateTime.now
            else
              new_item['toggled_by'] = get_old['toggled_by']
              new_item['toggled_at'] = get_old['toggled_at']
            end
          end

        end
       params['content'] = new_version.to_json
      end

      jot.content = ActionView::Base.full_sanitizer.sanitize(jot.content)
      if jot.update(params)
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

  def flag
    # This method is an form of #update, but for flagging.
    # This allows flagging permissions to be extended shared users
    jot = Jot.find(params[:id])
    folder = Folder.find(jot.folder_id)

    # Future update: move this into model.. it pretty much mirrors #check_box
    can_flag = false
    if jot.user_id == current_user.id || folder.user_id == current_user.id
      can_flag = true
    else
      share_check = Share.where("recipient_id = ? AND folder_id = ?", current_user.id, jot.folder_id)
      if share_check.length == 1
        # This user is shared with the containing folder, so they can flag.
        can_flag = true
      end
    end

    if can_flag
      jot.is_flagged = !jot.is_flagged
      if jot.save
        ser_jot = JotSerializer.new(jot, :root => false, :scope => current_user)
        render :json => {:success => true, :jot => ser_jot}

      else
        render :json => {:success => false}, :status => :bad_request
      end
    else
      render :json => {:success => false, :error => "You do not have permission to flag this jot."}, :status => :bad_request
    end
  end

  def check_box
    # This method is an form of #update, but for checkboxes only.
    # This allows checkbox-checking permissions to be extended shared users
    jot = Jot.find(params[:id])
    folder = Folder.find(jot.folder_id)

    # Future update: move this into model.. it pretty much mirrors #flag
    can_check = false
    if jot.user_id == current_user.id || folder.user_id == current_user.id
      can_check = true
    else
      share_check = Share.where("recipient_id = ? AND folder_id = ?", current_user.id, jot.folder_id)
      if share_check.length == 1
        # This user is shared with the containing folder, so they can check boxes.
        can_check = true
      end
    end

    if can_check
      checklist = JSON.parse(jot.content)
      item = checklist.find {|item| item['id'] == jot_params['checklist_item_id'] }
      item['checked'] = !item['checked']
      item['toggled_by'] = current_user.id
      item['toggled_at'] = DateTime.now
      jot.content = checklist.to_json

      if jot.save
        ser_jot = JotSerializer.new(jot, :root => false, :scope => current_user)
        render :json => {:success => true, :jot => ser_jot}

      else
        render :json => {:success => false}, :status => :bad_request
      end
    else
      render :json => {:success => false, :error => "You do not have permission to check this checkbox."}, :status => :bad_request
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
        Folder.where("id = ?", jot.folder_id)[0].touch
        Topic.where("id = ?", jot.topic_id)[0].touch
        render :json => {:success => true, :message => "Jot moved to trash."}
      else
        render :json => {:success => false, :error => "Could not delete jot."}, :status => :bad_request
      end
    else
      render :json => {:success => false, :error => "You do not have permission to delete this jot."}, :status => :bad_request
    end
  end

  def create_email_tag
    email_id = params[:email_id]
    subject = ActionView::Base.full_sanitizer.sanitize("#{params[:subject]}")
    topic_id = params[:topic_id]
    folder_id = Topic.find(topic_id).folder_id

    jot = current_user.jots.new(
      :content => subject,
      :tagged_email_id => email_id,
      :topic_id => topic_id,
      :folder_id => folder_id,
      :jot_type => 'email_tag'
    )

    if jot.save
      ser_jot = JotSerializer.new(jot, :root => false, :scope => current_user)
      render :json => {:success => true, :jot => ser_jot}
    else
      render :json => {:success => false, :error => "Could not tag email."}, :status => :bad_request
    end
  end

  protected

    def jot_params
      params.permit(:id, :content, :topic_id, :folder_id, :is_flagged, :jot_type, :break_from_top, :color, :checklist_item_id, :jots => [:id, :content, :topic_id, :folder_id, :jot_type, :break_from_top, :temp_key, :color])
    end
end
