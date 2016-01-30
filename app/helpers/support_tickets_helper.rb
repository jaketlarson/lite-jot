module SupportTicketsHelper
  def translate_status(status)
    if status == 'new'
      "<span class='ticket-status new'>New</span>".html_safe
    elsif status == 'answered'
      "<span class='ticket-status answered'>Answered</span>".html_safe
    elsif status == 'in_progress'
      "<span class='ticket-status in-progress'>In Progress</span>".html_safe
    elsif status == 'requires_more_details'
      "<span class='ticket-status requires-more-details'>Requires More Details</span>".html_safe
    else
      "<span class='unknown'>Unknown</span>".html_safe
    end
  end
end
