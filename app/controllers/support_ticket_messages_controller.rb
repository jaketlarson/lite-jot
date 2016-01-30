class SupportTicketMessagesController < ApplicationController
  before_filter :auth_user

  # This action is called upon new ticket messages created besides the initial ticket message
  def create
    if SupportTicketMessage.belongs_to_user?(support_ticket_message_params[:support_ticket_id], current_user.id)
      @ticket = SupportTicket.find(support_ticket_message_params[:support_ticket_id])
      @ticket_message = SupportTicketMessage.new(:message => support_ticket_message_params[:message])
      @ticket_message.support_ticket_id = support_ticket_message_params[:support_ticket_id]
      @ticket_message.user_id = current_user.id
      @ticket_message.message_type = "author_response"

      if @ticket_message.save
        @ticket.touch

        if !['new', 'in_progress'].include? @ticket.status
          @ticket.change_status 'in_progress'
        end

        # Notify admin email of new response
        @ticket.send_response_admin_notification_email

        flash[:notice] = "Your response has been added to the ticket."
        redirect_to support_ticket_path(@ticket.unique_id)

      else
        flash[:alert] = "Please enter a message to respond."
        redirect_to support_ticket_path(@ticket.unique_id)
      end
    else
      flash[:alert] = "Invalid ticket ID."
      redirect_to support_tickets_path
    end
  end

  protected

    def support_ticket_message_params
      params.require(:support_ticket_message).permit(:support_ticket_id, :message)
    end
end
