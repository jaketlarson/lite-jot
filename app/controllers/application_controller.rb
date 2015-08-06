class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include ActionController::Serialization

  def load_data
    folders = current_user.folders.order('updated_at desc')
    topics = current_user.topics.order('updated_at desc')
    jots = current_user.jots
    shares = current_user.shares

    data = {
      :folders => ActiveModel::ArraySerializer.new(folders, each_serializer: FolderSerializer),
      :topics => ActiveModel::ArraySerializer.new(topics, each_serializer: TopicSerializer),
      :jots => ActiveModel::ArraySerializer.new(jots, each_serializer: JotSerializer),
      :shares => ActiveModel::ArraySerializer.new(shares, each_serializer: ShareSerializer)

    }


    render :json => data.to_json
    # render :json => topics, :each_serializer => TopicSerializer

    # render :json => folders, :each_serializer => FolderSerializer
    
    # render :json => jots, :each_serializer => JotSerializer

    # render :json => shares, :each_serializer => ShareSerializer
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
