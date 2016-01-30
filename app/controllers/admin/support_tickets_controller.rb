class Admin::SupportTicketsController < ApplicationController
  before_filter :verify_admin
  layout 'admin/application'
  helper_method :sort_column, :sort_direction
  add_breadcrumb "Admin", :admin_path

  def index
    @mode = params[:mode] == 'answered' ? 'answered' : 'unanswered'

    if @mode == 'unanswered'
      @unanswered_tickets = SupportTicket.where('status = ? OR status = ?', 'new', 'in_progress')
                                          .order(sort_column + " " + sort_direction)
                                          .paginate(:page => params[:page])
    else
      @answered_tickets = SupportTicket.where('status = ? OR status = ?', 'answered', 'requires_more_details')
                                      .order(sort_column + " " + sort_direction)
                                      .paginate(:page => params[:page])
    end

    add_breadcrumb "Support Tickets"
  end

  def show
    @ticket = SupportTicket.friendly.find(params[:id])
    add_breadcrumb "Support Tickets", :admin_support_tickets_path
    add_breadcrumb "Ticket #{@ticket.unique_id}"
  end

  private

    def sort_column
      SupportTicket.column_names.include?(params[:sort]) ? params[:sort] : "last_answered_at"
    end
    
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
end
