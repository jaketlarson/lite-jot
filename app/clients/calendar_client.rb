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
          # Choose events between now and two days later
          if item.start.dateTime >= min_start_time && item.start.dateTime < max_start_time
            dateTime_unix = item.start.dateTime.to_i
            if item.start.dateTime.today?
              day = 'Today'
            elsif item.start.dateTime.to_date == Date.tomorrow
              day = 'Tomorrow'
            else
              day = item.start.dateTime.strftime("%A")
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

            event = {
              :summary => item.summary,
              :attendees => attendees,
              :start => {
                :day => day,
                :dateTime => item.start.dateTime,
                :dateTime_unix => dateTime_unix
              }
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
