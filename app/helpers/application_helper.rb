module ApplicationHelper
  def body_id
    controller_name = controller.controller_path.gsub('/','_')
    action_name = controller.action_name
    body_id = "#{controller_name}-#{action_name}"
    return body_id
  end
end
