class JotsController < ApplicationController
  def create
    @jot = current_user.jots.new(jot_params)

    if @jot.save
      render :text => "okay"

    else
      render :text => 'not okay'
    end
  end

  protected

    def jot_params
      params.permit(:content)
    end
end
