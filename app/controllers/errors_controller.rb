class ErrorsController < ApplicationController
  def file_not_found
  end

  def unprocessable
  end

  def internal_server_error
    # Was getting issues with this view rendering a 200 OK status,
    # and confusing XHR response handling. Trick to remind XHR
    # that it's still an error.
    render :status => 500
  end
end
