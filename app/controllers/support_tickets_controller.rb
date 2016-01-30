class SupportTicketsController < ApplicationController
  before_filter :set_return_to_session, :auth_user
  helper_method :sort_column, :sort_direction
  add_breadcrumb "Lite Jot", '/'
  add_breadcrumb "Support Center", :support_path

  # Notes:
  # - Ticket statuses can be 'new', 'answered', 'in_progress', or 'requires_more_details'

  def index
    @tickets = current_user.support_tickets.order(sort_column + " " + sort_direction).paginate(:page => params[:page])
    add_breadcrumb "My Tickets"
  end

  def show
    @ticket = current_user.support_tickets.friendly.find(params[:id])
    @ticket.author_last_read_at = DateTime.now
    @ticket.save
    add_breadcrumb "My Tickets", :support_tickets_path
    add_breadcrumb "Ticket Status"
  end

  def new
    @ticket_message = SupportTicketMessage.new
    add_breadcrumb "New Ticket"
  end

  def create
    @ticket = SupportTicket.new(:subject => new_ticket_params[:subject])
    @ticket_message = SupportTicketMessage.new(:message => new_ticket_params[:message])

    # We use 'unique_id' to create an atomically increasing yet random identifier
    last_ticket = SupportTicket.order('unique_id DESC').first
    new_unique_id = last_ticket.nil? ? 1 : last_ticket.unique_id + rand(1_000)
    @ticket.unique_id = new_unique_id
    @ticket.user_id = @current_user.id

    # Incase of error, save submitted values so we don't upset the user
    @subject_value = new_ticket_params[:subject]
    @message_value = new_ticket_params[:message]

    if @ticket.valid?
      @ticket_message.message_type = "author_response"

      if @ticket_message.valid?
        # Ticket and the first ticket message are both valid, let's save them!
        @ticket.save
        @ticket_message.support_ticket_id = @ticket.id
        @ticket_message.user_id = current_user.id
        @ticket_message.save
        flash[:notice] = "Your ticket has been created! You will hear back soon."
        redirect_to support_ticket_path(@ticket)

        # Should we be doing "if @ticket.save"?
      else
        flash[:error] = "Please enter a subject and detailed description of the issue"
        add_breadcrumb "New Ticket"
        render 'new'
      end
    else
      flash[:error] = "Please enter a subject and detailed description of the issue"
      add_breadcrumb "New Ticket"
      render 'new'
    end
  end

  protected

    def new_ticket_params
      params.require(:support_ticket).permit(:subject, :message)
    end

  private

    def sort_column
      SupportTicket.column_names.include?(params[:sort]) ? params[:sort] : "updated_at"
    end
    
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
    end
end
