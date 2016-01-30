class Admin::SupportTicketMessagesController < ApplicationController
  before_filter :auth_user
  add_breadcrumb "Admin", :admin_path
  add_breadcrumb "Support Tickets", :admin_support_tickets_path

  def create
    @ticket = SupportTicket.find(support_ticket_message_params[:support_ticket_id])

    # Validate new status. This could probably be cleaner.. like a validation in the model..
    if !['answered', 'in_progress', 'requires_more_details'].include? support_ticket_message_params[:new_status]
      flash[:notice] = "You've attempted to change the ticket to an invalid status."
      redirect_to admin_support_ticket_path(@ticket.unique_id)
      return
    end

    # If there is a message then we can create a new ticket message at the same time!
    # Otherwise, we're just changing the status.
    unless support_ticket_message_params[:message].empty?
      @ticket_message = SupportTicketMessage.new(:message => support_ticket_message_params[:message])
      @ticket_message.support_ticket_id = support_ticket_message_params[:support_ticket_id]
      @ticket_message.user_id = current_user.id
      @ticket_message.message_type = "support_answer"

      if @ticket_message.save
        # Updated ticket status
        @ticket.change_status(support_ticket_message_params[:new_status], current_user.id)
        @ticket.last_answered_at = DateTime.now
        @ticket.save

        # Send response notification to user's email
        @ticket.send_response_email
        
        flash[:notice] = "Your answer has been added to the ticket."
        redirect_to admin_support_ticket_path(@ticket.unique_id)

      else
        flash[:alert] = "Please enter a message to answer"
        redirect_to admin_support_ticket_path(@ticket.unique_id)
      end

    else # Just change status
      # Updated ticket status
      @ticket.change_status(support_ticket_message_params[:new_status], current_user.id)
      redirect_to admin_support_ticket_path(@ticket.unique_id)
    end
  end

  def edit
    @ticket_message = SupportTicketMessage.find(params[:id])
    @ticket = SupportTicket.find(@ticket_message.support_ticket_id)
    @author = User.find(@ticket_message.user_id)

    # Only allow admins to update ticket messages of admins.
    # I don't see a need in ever updating user ticket messages
    if @ticket_message.message_type == 'author_response'
      flash[:alert] = "You do not have permission to edit this ticket message."
      redirect_to admin_support_ticket_path(@ticket.unique_id)
    end

    add_breadcrumb "Ticket #{@ticket.unique_id}"
    add_breadcrumb "Edit Ticket Response"
  end

  def update
    @ticket_message = SupportTicketMessage.find(params[:id])
    @ticket = SupportTicket.find(@ticket_message.support_ticket_id)
    @author = User.find(@ticket_message.user_id)
 
    # Only allow admins to update ticket messages of admins.
    # I don't see a need in ever updating user ticket messages
    if @ticket_message.message_type == 'author_response'
      flash[:alert] = "You do not have permission to edit this ticket message."
      redirect_to admin_support_ticket_path(@ticket.unique_id)
      return
    end

    if @ticket_message.update(support_ticket_message_update_params)
      flash[:notice] = "Ticket message updated successfully!"
      redirect_to admin_support_ticket_path(@ticket.unique_id)
    else
      add_breadcrumb "Ticket #{@ticket.unique_id}"
      add_breadcrumb "Edit Ticket Response"
      render 'edit'
    end
  end

  def destroy
    ticket_message = SupportTicketMessage.find(params[:id])
    ticket = SupportTicket.find(ticket_message.support_ticket_id)

    # Only allow admins to destroy ticket messages of admins or notices
    # I don't see a need in ever updating user ticket messages
    if ticket_message.message_type == 'author_response'
      flash[:alert] = "You do not have permission to delete this ticket message."
    else
      ticket_message.destroy
      flash[:notice] = "Ticket message has been deleted successfully!"
    end
    
    redirect_to admin_support_ticket_path(ticket.unique_id)
  end

  protected

    def support_ticket_message_params
      params.require(:support_ticket_message).permit(:support_ticket_id, :message, :new_status)
    end

    def support_ticket_message_update_params
      params.require(:support_ticket_message).permit(:message)
    end
end
