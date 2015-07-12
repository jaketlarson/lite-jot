class NotificationsController < ApplicationController
  def index
  end

  def calendar
    calendar_client = CalendarClient.new
    calendar_events = calendar_client.fetch_calendar_items(current_user)

    render :json => {:notifications => calendar_events.to_json, :user_email => current_user.email}
  end
end
