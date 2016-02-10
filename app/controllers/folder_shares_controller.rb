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

    if fshare.update(fshare_params)
      specific_topics = params[:specific_topics] || []

      # topics_to_add will be updated as we validate
      topics_to_add = specific_topics

      # We have a list of specific_topics shared with a user in a given folder.
      # The FolderShare does not actually store the specific_topics. We maintain
      # a TopicShare for every topic referenced in specific_topics.
      # The way to do that is to go through each TopicShare and seeing if it is not
      # inside of specific_topics. If it is not, then we delete that TopicShare.
      # Then whichever topic ids are left in the array must be added as new TopicShares.

      # Check for deletes (must loop through all topics in folder)
      topics = Topic.where('folder_id = ? AND user_id = ?', fshare.folder_id, current_user.id)
      topics.each do |topic|
        tshare_found = TopicShare.where('topic_id = ? AND recipient_email = ?', topic.id, fshare.recipient_email)

        if !tshare_found.empty? && !(specific_topics.include? topic.id.to_s)
          # This topic is no longer included in specific_topics, destroy the TopicShare found.
          tshare_found.first.destroy
        end
      end

      specific_topics.each do |topic_id|
        topic = Topic.where('id = ? AND user_id = ?', topic_id, current_user.id)

        # Validate existence of topic
        if topic.empty?
          # Doesn't exist
          topics_to_add -= [topic_id.to_s]
          next
        end
        topic = topic.first

        tshare_exists = !TopicShare.where('topic_id = ? AND recipient_email = ?', topic.id, fshare.recipient_email).empty?
        if tshare_exists
          # TopicShare already exists, let's remove it from specific_topics and consider it OK
          topics_to_add -= [topic_id.to_s]
          next
        end
      end

      topics_to_add.each do |topic_id|
        topic = Topic.where('id = ? AND user_id = ?', topic_id, current_user.id).first
        TopicShare.add_new(fshare, topic, current_user)
      end

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
