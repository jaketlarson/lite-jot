module SupportTicketMessagesHelper
  def by_support_rep?(message)
    message.message_type == 'support_answer'
  end

  def is_answered_notice?(message)
    message.message_type == 'notice_answered'
  end

  def is_requires_more_details_notice?(message)
    message.message_type == 'notice_requires_more_details'
  end
end
