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

    return @gmail_threads.data.threads
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
                          'id' => thread_id
                          },
                        :headers => {'Content-Type' => 'application/json'})

    ap @gmail_thread


    return @gmail_thread.data.to_json
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
