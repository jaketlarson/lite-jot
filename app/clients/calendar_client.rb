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

  def fetch_calendar_items(user)
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
    now = DateTime.now
    today_begins_at = DateTime.now.beginning_of_day.to_i
    two_days_later_begins_at = today_begins_at + one_day*2
    min_start_time = DateTime.strptime(today_begins_at.to_s, '%s')
    max_start_time = DateTime.strptime(two_days_later_begins_at.to_s, '%s')

    # Iterate through calendar items
    if items
      items.each do |item|

        if item.start
          if item.start.date
            # All day event
            start_segments = item.start.date.split('-')
            start_year = start_segments[0].to_i
            start_month = start_segments[1].to_i
            start_day = start_segments[2].to_i
            start_time = DateTime.new(start_year, start_month, start_day)
          else
            start_time = item.start.dateTime
          end
          if item.end.date
            # All day event
            end_segments = item.end.date.split('-')
            end_year = end_segments[0].to_i
            end_month = end_segments[1].to_i
            end_day = end_segments[2].to_i
            end_time = DateTime.new(end_year, end_month, end_day)
          else
            end_time = item.end.dateTime
          end

          # # Choose events between now and two days later
          # if item.start.date
          #   # If item.start.date is there, that means item.start.dateTime
          #   # and item.end.DateTime will be absent because this is an
          #   # all-day event.
          #   # We can set the item.start.dateTime and item.end.dateTime
          #   # ourselves

          #   start_segments = item.start.date.split('-')
          #   start_year = start_segments[0].to_i
          #   start_month = start_segments[1].to_i
          #   start_day = start_segments[2].to_i

          #   end_segments = item.end.date.split('-')
          #   end_year = end_segments[0].to_i
          #   end_month = end_segments[1].to_i
          #   end_day = end_segments[2].to_i

          #   item.start.dateTime = DateTime.new(start_year, start_month, start_day)
          #   item.end.dateTime = DateTime.new(end_year, end_month, end_day)
          # end

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
            notif_time_span = "unset"
            if end_time.to_i - start_time.to_i == 60*60*24
              notif_time_span = "All day"
            elsif end_time.today?
              notif_time_span = "#{start_time.strftime("%l:%M%P")} - #{end_time.to_time.strftime("%l:%M%P")}"
            elsif end_time.to_date == Date.tomorrow
              notif_time_span = "#{start_time.strftime("%l:%M%P")} - Tomorrow @ #{end_time.to_time.strftime("%l:%M%P")}"
            else
              notif_time_span = "#{start_time.strftime("%l:%M%P")} - #{end_time.to_time.strftime("%b, %d @ %l:%M%P")}"
            end

            event = {
              :id => item.id,
              :summary => (item.summary || "(No title)"),
              :attendees => attendees,
              :location => item.location,
              :start => {
                :day => day,
                :dateTime => start_time,
                :dateTime_unix => start_time_unix,
                :timestamp => I18n.l(start_time, :format => :short_today)
              },
              :end => {
                :dateTime => end_time,
                :dateTime_unix => end_time_unix
              },
              :event_in_progress => event_in_progress,
              :event_finished => event_finished,
              :notif_time_span => notif_time_span
            }
            upcoming_events << event

          end
        end
      end
    end

    upcoming_events.sort! { |a,b| a[:start][:dateTime_unix] <=> b[:start][:dateTime_unix] }
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
