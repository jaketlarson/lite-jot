class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  around_filter :set_time_zone

  include ActionController::Serialization

  def load_data
    # Check if timezone was passed through
    # If so, update it on current_user
    if !params[:timezone].nil? && !params[:timezone].blank?
      current_user.timezone = params[:timezone]
      current_user.save!
    end

    folders = current_user.owned_and_shared_folders
    topics = []
    jots = []

    #topics = current_user.topics.order('updated_at desc')
    # collect topics & jots
    folders.each do |folder|
      folder.topics.each do |topic|
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
      :shares => ActiveModel::ArraySerializer.new(shares, :each_serializer => ShareSerializer, :scope => current_user),
      :user => UserSerializer.new(current_user, :root => false)
    }

    render :json => data.to_json
  end

  def connection_test
    render :text => 'OK'
  end

  def raw_data
    render :json => {:folders => current_user.folders, :topics => current_user.topics, :jots => current_user.jots}
  end

  def transfer_data
    ap params[:passcode]
    ap params[:folders]
    ap params[:topics]
    ap params[:jots]
    folders = JSON.parse(params[:folders])
    topics = JSON.parse(params[:topics])
    jots = JSON.parse(params[:jots])

    folder_key_map = {}
    topic_key_map = {}

    folders.each do |folder|
      new_folder = Folder.new
      ap folder
      new_folder.title = folder['title']
      new_folder.created_at = folder['created_at']
      new_folder.updated_at = folder['updated_at']
      new_folder.user_id = current_user.id
      new_folder.save
      folder_key_map[folder['id']] = new_folder.id
      ap new_folder
    end

    topics.each do |topic|
      new_topic = Topic.new
      ap topic
      new_topic.title = topic['title']
      new_topic.created_at = topic['created_at']
      new_topic.updated_at = topic['updated_at']
      new_topic.user_id = current_user.id
      new_topic.folder_id = folder_key_map[topic['folder_id']]
      new_topic.save
      topic_key_map[topic['id']] = new_topic.id
      ap new_topic
    end

    jots.each do |jot|
      new_jot = Jot.new
      ap jot
      new_jot.is_flagged = jot['is_flagged']
      new_jot.content = jot['content']
      new_jot.created_at = jot['created_at']
      new_jot.updated_at = jot['updated_at']
      new_jot.break_from_top = jot['break_from_top']
      new_jot.jot_type = jot['jot_type']
      new_jot.folder_id = folder_key_map[jot['folder_id']]
      new_jot.topic_id = topic_key_map[jot['topic_id']]
      new_jot.user_id = current_user.id
      new_jot.save
      ap new_jot
    end

    # topics.each do |topic|
    #   ap topic
    # end

    # jots.each do |jot|
    #   ap jot
    # end

    render :nothing => true
  end

  protected

  def set_time_zone(&block)
    time_zone = current_user.try(:timezone) || 'UTC'
    Time.use_zone(time_zone, &block)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :display_name

    devise_parameter_sanitizer.for(:account_update) << :current_password
    devise_parameter_sanitizer.for(:account_update) << :display_name
    devise_parameter_sanitizer.for(:account_update) << :is_viewing_key_controls
    devise_parameter_sanitizer.for(:account_update) << :receives_email
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
