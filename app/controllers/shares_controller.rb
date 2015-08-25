class SharesController < ApplicationController
  def index
    shares = current_user.shares

    render :json => shares, :each_serializer => ShareSerializer
  end

  def create
    share = Share.new(share_params)
    ownership_check = Folder.where('id = ? AND user_id = ?', share.folder_id, current_user.id)

    if ownership_check.count > 0
      recip_user = User.where('email = ?', share.recipient_email).first
      if !recip_user
        render :json => {:success => false, :error => "No user exists for that email address."}, :status => :bad_request
      else
        dup_check = current_user.shares.where('recipient_id = ? AND folder_id = ?', recip_user.id, share.folder_id)
        
        if dup_check.count > 0
          render :json => {:success => false, :error => "You are already sharing this folder with #{share.recipient_email}."}, :status => :bad_request
        else
          share.recipient_id = recip_user.id
          share.owner_id = current_user.id

          if share.save
            render :json => {:success => true, :share => ShareSerializer.new(share, :root => false)}
          else
            render :json => {:success => false, :error => "There was an error while sharing. Please contact us if this issue persists."}, :status => :bad_request
          end
        end
      end
    else
      render :json => {:success => false, :error => "You can only share folders you've created."}, :status => :bad_request
    end

  end

  def update
    share = current_user.shares.find(params[:id])

    if share.update(share_params)
      if params[:specific_topics].nil?
        share.specific_topics = nil
        share.save
      end

      render :json => {:success => true, :share => ShareSerializer.new(share, :root => false)}

    else
      render :json => {:success => false}, :status => :bad_request
    end
  end

  def destroy
    share = Share.find(params[:id])

    if share.owner_id == current_user.id || share.recipient_id == current_user.id
      if share.destroy
        render :json => {:success => true, :message => "Folder has been unshared with you."}
      else
        render :json => {:success => false}, :status => :bad_request
      end
    else
      render :json => {:success => false, :error => "You cannot modify this share."}, :status => :bad_request
    end
  end

  protected

    def share_params
      params.permit(:id, :folder_id, :recipient_email, :is_all_topics, :specific_topics => [])
    end
end
