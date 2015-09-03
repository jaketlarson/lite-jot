class NotificationsController < ApplicationController
  def index
  end

  def calendar
    calendar_client = CalendarClient.new
    calendar_events = calendar_client.fetch_calendar_items(current_user, notif_display_buffer_minutes=10)

    render :json => {:calendar_items => calendar_events.to_json}
  end

  # notifications#acknowledge will mark a specific id, such as Google
  # calendar item ID, as seen, so that notification
  # will not appear again. This is currently checked against
  # in the calendar module, called from the notification module
  # and stored in the user model.
  def acknowledge
    if current_user
      if current_user.notifications_seen.nil?
        current_user.notifications_seen = [params[:notif_id]]
      else
        current_user.notifications_seen << params[:notif_id]
      end
      current_user.save
    end
    head 200, content_type: "text/html"
  end
end
