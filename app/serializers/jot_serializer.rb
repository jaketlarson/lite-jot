class JotSerializer < ActiveModel::Serializer
  attributes :id, :content, :topic_id, :created_at_short, :created_at_long, :updated_at

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
end
