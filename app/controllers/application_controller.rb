class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include ActionController::Serialization

  def load_data
    folders = current_user.owned_and_shared_folders
    topics = []
    jots = []

    #topics = current_user.topics.order('updated_at desc')
    # collect topics & jots
    folders.each do |folder|
      folder.topics.order('updated_at asc').each do |topic|
        if current_user.id != topic.user_id
          share = Share.where("folder_id = ? AND recipient_id = ?", topic.folder_id, current_user.id).first
          if !share.is_all_topics
            if share.specific_topics
              if !share.specific_topics.include?(topic.id.to_s)
                next
              end
            end
          end
        end

        topics << topic
      end
    end

    # collect jots
    topics.each do |topic|
      topic.jots.each do |jot|
        jots << jot
      end

    end

    shares = current_user.shares

    data = {
      :folders => ActiveModel::ArraySerializer.new(folders, :each_serializer => FolderSerializer, :scope => current_user),
      :topics => ActiveModel::ArraySerializer.new(topics, :each_serializer => TopicSerializer, :scope => current_user),
      :jots => ActiveModel::ArraySerializer.new(jots, :each_serializer => JotSerializer, :scope => current_user),
      :shares => ActiveModel::ArraySerializer.new(shares, :each_serializer => ShareSerializer, :scope => current_user)
    }

    render :json => data.to_json
  end

  def connection_test
    render :text => 'OK'
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :display_name

    devise_parameter_sanitizer.for(:account_update) << :display_name
    devise_parameter_sanitizer.for(:account_update) << :is_viewing_key_controls
  end

  def sign_up_params
    devise_parameter_sanitizer.sanitize(:sign_up)
  end

  def sign_in_params
    devise_parameter_sanitizer.sanitize(:sign_in)
  end

  def account_update_params
    devise_parameter_sanitizer.sanitize(:account_update)
  end
end
