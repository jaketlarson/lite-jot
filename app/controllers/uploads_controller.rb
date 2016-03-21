class UploadsController < ApplicationController
  before_filter :auth_user
  before_action :set_document, only: [:download]

  def create
    # add validation to topic_id being an int and existing in database
    ap 'create start'
    ap upload_params
    @upload = current_user.uploads.new(upload_params)
    if @upload.valid?
      @upload.save
      jot = Jot.create_jot_from_upload(current_user.id, @upload.id, params[:topic_id].to_i)
      ser_jot = JotSerializer.new(jot, :root => false, :scope => current_user)
      render :json => {:success => true, :jot => ser_jot} 
      ap 'create done'
    else
      render :json => {:success => false, :errors => @upload.errors}, :status => :unprocessable_entity
      ap "uh no"
    end

  end

  def download
    redirect_to @upload.upload.expiring_url(30.seconds, :original)
  end

  private

  def set_document
    @upload = current_user.find(params[:id])
  end

  def upload_params
    params.require(:upload).permit(:direct_upload_url)
  end
end