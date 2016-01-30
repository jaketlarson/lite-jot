class FeedbackController < ApplicationController
  add_breadcrumb "Lite Jot", '/'
  add_breadcrumb "Support Center", :support_path

  def new
    @feedback = Feedback.new
    add_breadcrumb "Email Inquiry"
  end

  def create
    @feedback = Feedback.new(feedback_params)

    if @feedback.valid?
      @feedback.send_admin_notification_email
      @feedback.send_confirmation_email

      render :success
    else
      add_breadcrumb "Email Inquiry"
      render :new
    end
  end

  protected

    def feedback_params
      params.require(:feedback).permit(:name, :email, :message)
    end
end
