require 'google/api_client'

class CalendarClient
  API_NAME = 'calendar'
  API_VERSION = 'v3'

  def initialize
    @client = Google::APIClient.new(
      :application_name => 'Lite Jot',
      :application_version => '1.0'
    )

    @client.authorization.client_id = Rails.application.secrets.GOOGLE_CLIENT_ID
    @client.authorization.client_secret = Rails.application.secrets.GOOGLE_CLIENT_SECRET
    @calendar = @client.discovered_api(API_NAME, API_VERSION)
  end

  def fetch_calendar_items(user, notif_display_buffer_minutes=0)
    # Check if the Google access token is expired; update if necessary
    if user.auth_token_expiration.nil? || user.auth_token_expiration < DateTime.now
      refresh_token(user)
    end

    @client.authorization.access_token = user.auth_token
    @calendar_events = @client.execute(:api_method => @calendar.events.list,
                        :parameters => {'calendarId' => user.email},
                        :headers => {'Content-Type' => 'application/json'})
    items = @calendar_events.data.items
    upcoming_events = []


    one_day = 24*60*60
    now = DateTime.now.in_time_zone(user.timezone)
    today_begins_at = DateTime.now.in_time_zone(user.timezone).beginning_of_day.to_i
    two_days_later_begins_at = today_begins_at + one_day*2
    min_start_time = DateTime.strptime(today_begins_at.to_s, '%s')
    max_start_time = DateTime.strptime(two_days_later_begins_at.to_s, '%s')

    # Iterate through calendar items
    if items
      items.each do |item|

        # Note that all day events don't have timezone offsets.. so there are
        # some workarounds. Take the UTC offset and subtract it from a new
        # DateTime object (based only off the current date, no time info).
        timezone_utc_offset = ActiveSupport::TimeZone.new(user.timezone).now.utc_offset

        if item.start
          if item.start.date
            # All day event
            start_segments = item.start.date.split('-')
            start_year = start_segments[0].to_i
            start_month = start_segments[1].to_i
            start_day = start_segments[2].to_i
            start_time = (DateTime.new(start_year, start_month, start_day).to_time - timezone_utc_offset).to_datetime
          else
            start_time = item.start.dateTime.in_time_zone(user.timezone)
          end
          if item.end.date
            # All day event
            end_segments = item.end.date.split('-')
            end_year = end_segments[0].to_i
            end_month = end_segments[1].to_i
            end_day = end_segments[2].to_i
            end_time = (DateTime.new(end_year, end_month, end_day).to_time - timezone_utc_offset).to_datetime
          else
            end_time = item.end.dateTime.in_time_zone(user.timezone)
          end

          # Choose events between now and two days later
          # If start time is within the next two days, or the start time is before today but end time has not yet been approached.
          if (start_time >= min_start_time && start_time < max_start_time) || (start_time < min_start_time && end_time >= min_start_time)
            start_time_unix = start_time.to_i
            end_time_unix = end_time.to_i

            if start_time.today?
              day = 'Today'
            elsif start_time.to_date == Date.tomorrow
              day = 'Tomorrow'
            else
              day = start_time.strftime("%A")
            end

            attendees = []

            item.attendees.each do |attendee|
              email = attendee['email']
              unless attendee['displayName'].nil? || attendee['displayName'].length == 0
                displayName = attendee['displayName']
              else
                displayName = email
              end

              attendees << {
                :email => email,
                :displayName => displayName
              }
            end

            event_in_progress = start_time < Time.now && end_time > Time.now ? true : false
            event_finished = end_time < Time.now ? true : false

            # notif_time_span is used in event notifications
            # In future, move some of this into a locale.
            notif_time_span_start = "unset"
            notif_time_span_end = "unset"

            if start_time.today?
              notif_time_span_start = start_time.strftime("%l:%M%P")
            else
              notif_time_span_start = start_time.strftime("%b, %d @ %l:%M%P")
            end

            if end_time.today?
              notif_time_span_end = end_time.strftime("%l:%M%P")
            elsif end_time.to_date == Date.tomorrow
              notif_time_span_end = end_time.strftime("Tomorrow @ %l:%M%P")
            else
              notif_time_span_end = end_time.strftime("%b, %d @ %l:%M%P")
            end

            if end_time.to_i - start_time.to_i == 60*60*24
              notif_time_span = "All day"
            else
              notif_time_span = "#{notif_time_span_start} - #{notif_time_span_end}"
            end

            # Set (in milleseconds, for javascript timer) the time until notification
            # displays, and the time until notification hides.
            # Take into account variable passed `notif_display_buffer_minutes`
            # for notifications to show earlier.
            time_until_display = 1000*(start_time.to_i - now.to_i - notif_display_buffer_minutes*60)
            time_until_hide = 1000*(end_time.to_i - now.to_i)

            event = {
              :id => item.id,
              :summary => (item.summary || "(No title)"),
              :attendees => attendees,
              :location => item.location,
              :start => {
                :day => day,
                :datetime => start_time,
                :datetime_unix => start_time_unix,
                :timestamp => I18n.l(start_time, :format => :short_today),
              },
              :end => {
                :datetime => end_time,
                :datetime_unix => end_time_unix
              },
              :event_in_progress => event_in_progress,
              :event_finished => event_finished,
              :month_day_heading => I18n.l(start_time, :format => :short_this_year),
              :notification => {
                :time_span => notif_time_span,
                :time_until_display => time_until_display,
                :time_until_hide => time_until_hide
              }
            }
            upcoming_events << event

          end
        end
      end
    end

    upcoming_events.sort! { |a,b| a[:start][:datetime_unix] <=> b[:start][:datetime_unix] }
    return upcoming_events
  end

  private
    def refresh_token(user)
      @client.authorization.refresh_token = user.auth_refresh_token

      token_result = @client.authorization.fetch_access_token!

      user.save_google_token(
        token_result['access_token'],
        token_result['expires_in']
      )
    end
end
