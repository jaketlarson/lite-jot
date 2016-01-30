class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  around_filter :set_time_zone

  include ActionController::Serialization

  def after_sign_in_path_for(resource)
    session['user_return_to'] || '/'
  end

  def set_return_to_session
    session['user_return_to'] = request.original_url
  end

  def load_data_init
    # Check if timezone was passed through
    # If so, update it on current_user
    if !params[:timezone].nil? && !params[:timezone].blank?
      if current_user
        current_user.timezone = params[:timezone]
        current_user.save!
      end
    end

    folders = current_user.owned_and_shared_folders
    topics = []
    jots = []

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
        # email tags are private, don't show them to other users.
        if jot.jot_type == 'email_tag' && jot.user_id != current_user.id
          next
        else
          jots << jot
        end
      end
    end

    shares = current_user.shares

    data = {
      :folders => ActiveModel::ArraySerializer.new(folders, :each_serializer => FolderSerializer, :scope => current_user),
      :topics => ActiveModel::ArraySerializer.new(topics, :each_serializer => TopicSerializer, :scope => current_user),
      :jots => ActiveModel::ArraySerializer.new(jots, :each_serializer => JotSerializer, :scope => current_user),
      :shares => ActiveModel::ArraySerializer.new(shares, :each_serializer => ShareSerializer, :scope => current_user),
      :user => UserSerializer.new(current_user, :root => false),
      :last_update_check => Time.now.to_f
    }

    render :json => data.to_json
  end

  def load_updates
    last_time = Time.at(params[:last_update_check_time].to_i)


    folders = current_user.owned_and_shared_folders_with_deleted_after_time(last_time)
    topics = []
    jots = []

    ap "so here it is:"
    ap folders

    # collect topics & jots
    folders.each do |folder|
      folder.topics.with_deleted.where("created_at > ? OR updated_at > ? OR deleted_at > ?", last_time, last_time, last_time).each do |topic|
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
      topic.jots.with_deleted.where("created_at > ? OR updated_at > ? OR deleted_at > ?", last_time, last_time, last_time).each do |jot|
        # email tags are private, don't show them to other users.
        if jot.jot_type == 'email_tag' && jot.user_id != current_user.id
          next
        else
          jots << jot
        end
      end
    end

    # Add shares handling to this.

    # Get deleted items
    del_folders = folders.select { |folder| !folder.deleted_at.nil? && folder.deleted_at > last_time }
    del_topics = topics.select { |topic| !topic.deleted_at.nil? && topic.deleted_at > last_time }
    del_jots = jots.select { |jot| !jot.deleted_at.nil? && jot.deleted_at > last_time }


    # Now remove all the deleted items from the main items collection.
    # This way we can classify them as the "new or updated" items.
    ap jots
    folders = folders.select { |folder| folder.deleted_at.nil? }
    topics = topics.select { |topic| topic.deleted_at.nil? }
    jots = jots.select { |jot| jot.deleted_at.nil? }

    data = {
      :new_or_updated => {
        :folders => ActiveModel::ArraySerializer.new(folders, :each_serializer => FolderSerializer, :scope => current_user),
        :topics => ActiveModel::ArraySerializer.new(topics, :each_serializer => TopicSerializer, :scope => current_user),
        :jots => ActiveModel::ArraySerializer.new(jots, :each_serializer => JotSerializer, :scope => current_user)
      },
      :deleted => {
        :folders => del_folders,
        :topics => del_topics,
        :jots => del_jots
      },
      :user => UserSerializer.new(current_user, :root => false),
      :last_update_check => Time.now.to_f
    }
    render :json => data.to_json
  end

  def connection_test
    render :text => 'OK'
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

  def verify_admin
    if !current_user.try(:admin?)
      redirect_to '/'
    end
  end

  def auth_user
    redirect_to getting_started_url unless user_signed_in?
  end

end
