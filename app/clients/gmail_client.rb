require 'google/api_client'

class GmailClient
  API_NAME = 'gmail'
  API_VERSION = 'v1'

  def initialize
    @client = Google::APIClient.new(
      :application_name => 'Lite Jot',
      :application_version => '1.0'
    )

    @client.authorization.client_id = Rails.application.secrets.google_client_id
    @client.authorization.client_secret = Rails.application.secrets.google_client_secret
    @gmail = @client.discovered_api(API_NAME, API_VERSION)
  end

  def fetch_threads(user, max_results, page_token)
    # Check if the Google access token is expired; update if necessary
    if user.auth_token_expiration.nil? || user.auth_token_expiration < DateTime.now
      refresh_token(user)
    end

    @client.authorization.access_token = user.auth_token
    @gmail_threads = @client.execute(:api_method => @gmail.users.threads.list,
                        :parameters => {
                          'userId' => user.email,
                          'maxResults' => max_results,
                          'pageToken' => page_token,
                          'includeSpamTrash' => false
                          },
                        :headers => {'Content-Type' => 'application/json'})

    data = []

    @gmail_threads.data.threads.each do |thread|
      # Since subjects don't come through, we need to poll the thread (get) for the
      # subject header. This also gives us the chance to remove Google Hangout
      # chat transcripts by ignoring threads with messages that lack subjects.
      get_thread = @client.execute(:api_method => @gmail.users.threads.get,
                        :parameters => {
                          'userId' => user.email,
                          'id' => thread.id,
                          'fields' => 'messages/payload'
                          },
                        :headers => {'Content-Type' => 'application/json'})

      thread_data = get_thread.data
      headers = thread_data['messages'][0]['payload']['headers']
      find_subject = headers.detect {|header| header['name'] == 'Subject'}
      if !find_subject
        next
      end
      subject = find_subject['value']

      data << {
        :id => thread.id,
        :subject => subject
      }
    end

    return { :threads => data, :nextPageToken => @gmail_threads.data.nextPageToken }
  end

  def fetch_thread(user, thread_id)
    # Check if the Google access token is expired; update if necessary
    if user.auth_token_expiration.nil? || user.auth_token_expiration < DateTime.now
      refresh_token(user)
    end

    @client.authorization.access_token = user.auth_token
    @gmail_thread = @client.execute(:api_method => @gmail.users.threads.get,
                        :parameters => {
                          'userId' => user.email,
                          'id' => thread_id,
                          'fields' => 'messages/payload'
                          },
                        :headers => {'Content-Type' => 'application/json'})

    data = []
    @gmail_thread.data.messages.each do |message|
      headers = message['payload']['headers']
      from = headers.detect {|header| header['name'] == 'From'}
      to = headers.detect {|header| header['name'] == 'To'}
      subject = headers.detect {|header| header['name'] == 'Subject'}
      date = headers.detect {|header| header['name'] == 'Date'}

      body = message['payload']['body']

      has_parts = false
      if !body || !body['data']
        body = message['payload']['parts'][message['payload']['parts'].length-1]['body']
        has_parts = true
      end

      # Check again, sometimes the array gets a little ridiculous
      # This has proven to get calendar even updates.
      if (!body || !body['data']) && message['payload']['parts'][0]['parts']
        body = message['payload']['parts'][0]['parts'][1]['body']
      end

      if body['data']
        body['data'].gsub!("\n\r", "_breakhere_")
        body['data'].gsub!("\n", "_breakhere_")
        body['data'].gsub!("\r", "_breakhere_")
        # Sometimes multple breaklines should just be one breakilne
        body['data'].gsub!("_breakhere__breakline_", "_breakhere_")
      end

      if to['value']
        to['value'].gsub!("<", "&lt;")
        to['value'].gsub!(">", "&gt;")
      end

      if from['value']
        from['value'].to_s.gsub!("<", "&lt;")
        from['value'].to_s.gsub!(">", "&gt;")
      end

      data << {
        :from => from['value'],
        :to => to['value'],
        :subject => subject['value'],
        :date => date['value'],
        :body => body,
        :has_parts => has_parts
      }
    end

    return data.to_json
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
