class FolderSharesController < ApplicationController
  def index
    fshares = current_user.folder_shares

    render :json => fshares, :each_serializer => FolderShareSerializer
  end

  def create
    fshare = FolderShare.new(fshare_params)
    ownership_check = Folder.where('id = ? AND user_id = ?', fshare.folder_id, current_user.id)


    if fshare.recipient_email != current_user.email
      if ownership_check.count > 0
        recip_user = User.where('email = ?', fshare.recipient_email).first
        dup_check = current_user.folder_shares.where('recipient_email = ? AND folder_id = ?', fshare.recipient_email, fshare.folder_id)
          
        if dup_check.count > 0
          render :json => {:success => false, :error => "You are already sharing this folder with #{fshare.recipient_email}."}, :status => :bad_request
        else
          if recip_user
            fshare.recipient_id = recip_user.id
          end

          fshare.sender_id = current_user.id

          if fshare.save
            render :json => {:success => true, :folder_share => FolderShareSerializer.new(fshare, :root => false)}
          else
            render :json => {:success => false, :error => "There was an error while sharing. Please contact us if this issue persists."}, :status => :bad_request
          end
        end
      else
        render :json => {:success => false, :error => "You can only share folders you've created."}, :status => :bad_request
      end
    else
      render :json => {:success => false, :error => "You cannot share a folder with yourself."}, :status => :bad_request
    end

  end

  def update
    fshare = current_user.folder_shares.find(params[:id])

    ap fshare

    if fshare.update(fshare_params)
      ap "updating!"
      ap fshare
      ap "specific topics:"
      ap params[:specific_topics]
      ap "is_all_topics:"
      ap params[:is_all_topics]

      if !params[:specific_topics].nil? && params[:is_all_topics] == 'false'
        ap 'specific topics not all topics'
        # Specific topics are selected
        topics = Topic.where('folder_id = ?', fshare.folder_id)

        # If this topic is in the specific_topics list, create the share if not already
        # created.
        topics.each do |topic|
          if params[:specific_topics].include? topic.id.to_s
            tshare_exists = !TopicShare.where('topic_id = ? AND recipient_email = ?', topic.id, fshare.recipient_email).empty?
            ap tshare_exists
            if !tshare_exists
              tshare = TopicShare.new(
                :recipient_email => fshare.recipient_email,
                :recipient_id => fshare.recipient_id,
                :topic_id => topic.id,
                :folder_id => fshare.folder_id,
                :sender_id => current_user.id
              )

              tshare.save

            end

          else
            ap "LET US DELETE THIS NOW OKAY COOL"
            # If a topic share exists right now, delete it
            tshare_check = TopicShare.where('topic_id = ? AND recipient_email = ?', topic.id, fshare.recipient_email)
            if tshare_check.count == 1
              tshare_check[0].destroy
            end
          end

        end

      elsif params[:is_all_topics] == 'true'
        ap 'all topics'
        # All topics are selected
        topics = Topic.where('folder_id = ?', fshare.folder_id)

        topics.each do |topic|
          tshare_exists = !TopicShare.where('topic_id = ? AND recipient_email = ?', topic.id, fshare.recipient_email).empty?

          if !tshare_exists
            tshare = TopicShare.new(
              :recipient_email => fshare.recipient_email,
              :recipient_id => fshare.recipient_id,
              :topic_id => topic.id,
              :folder_id => fshare.folder_id,
              :sender_id => current_user.id
            )

            tshare.save

          end
        end

      elsif params[:specific_topics].nil? && params[:is_all_topics] == 'false'
        ap 'destroy all!!!'
        # No topics selected, remove all topic_shares for this recipient in the folder,
        TopicShare.destroy_all "folder_id = '#{fshare.folder_id}' AND recipient_email='#{fshare.recipient_email}'"
      else
        # is_all_topics is not even set. Let's make it false
        fshare.is_all_topics = false
        fshare.save
      end

      # else
      #   #fshare.specific_topics = nil # REMOVE THIS OKAY YES DO REMOVE IT DEFS REMOVE THIS
      #   fshare.save
      # end

      render :json => {:success => true, :folder_share => FolderShareSerializer.new(fshare, :root => false)}

    else
      render :json => {:success => false}, :status => :bad_request
    end
  end

  def destroy
    fshare = FolderShare.find(params[:id])

    if fshare.sender_id == current_user.id || fshare.recipient_id == current_user.id
      if fshare.destroy
        TopicShare.destroy_all "folder_id = '#{fshare.folder_id}' AND recipient_email='#{fshare.recipient_email}'"
        render :json => {:success => true, :message => "Folder has been unshared with you."}
      else
        render :json => {:success => false}, :status => :bad_request
      end
    else
      render :json => {:success => false, :error => "You cannot modify this share."}, :status => :bad_request
    end
  end

  protected

    def fshare_params
      params.permit(:id, :folder_id, :recipient_email, :is_all_topics, :specific_topics => [])
    end
end
