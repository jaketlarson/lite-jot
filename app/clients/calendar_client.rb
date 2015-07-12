require 'google/api_client'

class CalendarClient
  API_NAME = 'calendar'
  API_VERSION = 'v3'

  def initialize
    @client = Google::APIClient.new(
      :application_name => 'Lite Jot',
      :application_version => '1.0'
    )
    @client.authorization.client_id = Rails.application.secrets.google_key
    @client.authorization.client_secret = Rails.application.secrets.google_secret
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
    now = Time.now
    two_days_from_now = Time.now + 2*24*60*60

    # Iterate through calendar items
    if items
      items.each do |item|
        if item.start
          # Choose events between now and two days later
          if item.start.dateTime > now && item.start.dateTime < two_days_from_now
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
