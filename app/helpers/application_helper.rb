module ApplicationHelper
  def body_id
    controller_name = controller.controller_path.gsub('/','_')
    action_name = controller.action_name
    body_id = "#{controller_name}-#{action_name}"
    return body_id
  end

  def page_title(custom='')
    if !custom.blank?
      title =  "#{custom} - #{I18n.t('meta.site_title')}"
    else
      title = I18n.t('meta.site_title')
    end
    title
  end
  
  def sortable(column, title = nil, mode = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, {:sort => column, :direction => direction, :mode => mode}, {:class => css_class}
  end

  def is_on_app
    controller_name == "pages" && action_name == "dashboard"
  end

  def concise_date(date_stamp)
    if date_stamp.nil?
      return "<span>Never</span>".html_safe
    end

    date_as_float = date_stamp.to_f
    now = Time.now.to_i
    full_day = 86400
    full_week = full_day*7
    full_year = full_day*365 # should add leap year check?

    if now - date_as_float < full_day
      display_date = I18n.l(date_stamp, :format => :concise_today)

    elsif now - date_as_float < full_week
      display_date = I18n.l(date_stamp, :format => :concise_this_week)

    elsif now - date_as_float < full_year
      display_date = I18n.l(date_stamp, :format => :concise_this_year)

    else
      display_date = I18n.l(date_stamp, :format => :concise_default)
    end

    "<span title='#{I18n.l(date_stamp)}'>#{display_date}</span>".html_safe
  end
end
