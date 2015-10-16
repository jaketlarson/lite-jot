module ApplicationHelper
  def body_id
    controller_name = controller.controller_path.gsub('/','_')
    action_name = controller.action_name
    body_id = "#{controller_name}-#{action_name}"
    return body_id
  end

  def page_title(custom='')
    title = I18n.t('meta.site_title')
    if !custom.blank?
      title += " - #{custom}"
    end
    title
  end
end
