class JotSerializer < ActiveModel::Serializer
  attributes(
    :id,
    :content,
    :topic_id,
    :created_at_short,
    :created_at_long,
    :created_at_unix,
    :updated_at,
    :is_flagged,
    :has_manage_permissions,
    :folder_id,
    :jot_type,
    :break_from_top,
    :color,
    :temp_key,
    :author_display_name,
    :deleted_at,
    :deleted_at_unix,
    :tagged_email_id
  )

  delegate :current_user, to: :scope

  def content
    if object.jot_type != 'checklist'
      return object.content
    end

    # Since checklists insert dates and user id's into the checklist meta,
    # the content needs to be up to date.
    # This means localizing datetime and pulling current user display_name

    checklist = JSON.parse(object.content)
    checklist.each do |item|
    item['toggled_text'] = "Click to toggle checkbox.<br />"
      if item['toggled_by'] && !item['toggled_by'].blank?
        if item['toggled_by'] == scope.id
          display_name = scope.display_name
        else
          user = User.where('id = ?', item['toggled_by'])
          display_name = !user.empty? ? user[0].display_name : "Unknown"
        end
        item['toggled_text'] += "Last toggled by #{display_name} on #{I18n.l(item['toggled_at'].to_datetime.in_time_zone(scope.timezone))}."
      end
    end
    return checklist.to_json
  end

  def created_at_short
    return nil if object.created_at.nil?

    jot_time = object.created_at.to_f
    now = Time.now.to_i
    full_day = 86400
    full_week = full_day*7
    full_year = full_day*365 # should add leap year check?

    if now - jot_time < full_day
      I18n.l(object.created_at, :format => :short_today)

    elsif now - jot_time < full_week
      I18n.l(object.created_at, :format => :short_this_week)

    elsif now - jot_time < full_year
      I18n.l(object.created_at, :format => :short_this_year)

    else
      I18n.l(object.created_at, :format => :short_default)
    end
  end

  def created_at_long
    return nil if object.created_at.nil? else I18n.l(object.created_at)
  end

  def updated_at
    return nil if object.updated_at.nil? else I18n.l(object.updated_at)
  end

  def has_manage_permissions
    if object.user_id == scope.id
      return true
    else
      folder = Folder.where('id = ?', object.folder_id)[0]
      if !folder.nil?
        if folder.user_id == scope.id
          return true
        else
          return false
        end
      end
    end
  end

  def folder_id
    if !object.folder_id.nil?
      return object.folder_id.to_i
    end
  end

  def author_display_name
    return User.find(object.user_id).display_name
  end

  def created_at_unix
    object.created_at.to_f
  end

  def deleted_at
    return nil if object.deleted_at.nil? else I18n.l(object.deleted_at)
  end

  def deleted_at_unix
    return nil if object.deleted_at.nil? else object.deleted_at.to_f
  end
end
