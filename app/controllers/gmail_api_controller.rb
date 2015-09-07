class GmailApiController < ApplicationController
  def index
    gmail_client = GmailClient.new
    gmail_threads = gmail_client.fetch_threads(current_user, max_results=10, page_token=params[:next_page_token])

    render :json => {:threads => gmail_threads[:threads], :next_page_token => gmail_threads[:nextPageToken]}
  end

  def show
    gmail_client = GmailClient.new
    @gmail_thread = JSON.parse(gmail_client.fetch_thread(current_user, params[:id]))

    render :template => 'gmail_api/show', :layout => 'email_viewer'
  end
end
