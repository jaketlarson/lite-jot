class NotificationsController < ApplicationController
  def index
    # @event = {
    #   'summary' => 'Lite Jot Test',
    #   'description' => 'How awesome would it be if this worked',
    #   'location' => 'bigcrib',
    #   'start' => { 'dateTime' => '2015-04-05T17:06:02.000Z' },
    #   'end' => { 'dateTime' => '2015-04-05T17:07:02.000Z' }
    # }

    client = Google::APIClient.new
    client.authorization.access_token = current_user.google_token
    service = client.discovered_api('calendar', 'v3')

    #@set_event = client.execute(:api_method => service.events.insert,
                            # :parameters => {'calendarId' => current_user.email, 'sendNotifications' => true},
                            # :body => JSON.dump(@event),
                            # :headers => {'Content-Type' => 'application/json'})
    @get_events_json = client.execute(:api_method => service.events.list,
                        :parameters => {'calendarId' => current_user.email},
                        :headers => {'Content-Type' => 'application/json'})

    
    items = @get_events_json.data.items
    upcoming_events = []
    now = Time.now

    if items
      items.each do |item|
        if item.start
          if item.start.dateTime
            if item.start.dateTime > now
              upcoming_events << item
            end
          end
        end
      end
    end

    ap upcoming_events.to_json

    render :json => {:notifications => upcoming_events.to_json, :user_email => current_user.email}
  end
end
