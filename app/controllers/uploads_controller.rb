class UploadsController < ApplicationController
  before_filter :auth_user
  # before_action :set_upload, only: [:download]

  def create
    # add validation to topic_id being an int and existing in database
    @upload = current_user.uploads.new(upload_params)

    # Set upload_file_size so the upload validator for monthly upload limits can take it into
    # consideration when saving the file. Perhaps there are better methods?
    @upload.upload_file_size = params[:filesize].to_i

    if @upload.valid?
      @upload.save
      jot = Jot.create_jot_from_upload(current_user.id, @upload.id, params[:topic_id].to_i)
      ser_jot = JotSerializer.new(jot, :root => false, :scope => current_user)
      render :json => {:success => true, :jot => ser_jot} 
      ap 'create done'
    else
      render :json => {:success => false, :errors => @upload.errors}, :status => :unprocessable_entity
    end

  end

  def download
    @upload = Upload.find(params[:id])

    # Check permissions... should REALLY be in its own method
    can_download = false
    jot = Jot.find(@upload.jot_id)
    folder = Folder.find(jot.folder_id)
    topic = Topic.find(jot.topic_id)

    if jot.user_id == current_user.id || folder.user_id == current_user.id
      can_download = true
    else
      share_check = TopicShare.where("recipient_id = ? AND topic_id = ?", current_user.id, jot.topic_id)
      if share_check.length == 1
        # This user is shared with the containing folder, so they can flag.
        can_download = true
      end
    end

    if !can_download
      redirect_to '/'
      return
    end

    # Grab image from web
    url = @upload.upload.url
    image = HTTParty.get(url).body

    # Save file to temporary directory
    prefix = "download"
    suffix = '.jpg'

    # Create directory if necessary
    if !File.directory?(Rails.root.join('tmp', 'downloads'))
      %x(mkdir tmp/downloads)
    end

    puts "Saving image"
    tempfile = Tempfile.new([prefix, suffix], Rails.root.join('tmp', 'downloads'))
    tempfile.binmode
    tempfile.write image
    tempfile.close
    save_path = tempfile.path
    ap "save_path="
    ap save_path
    

    # Send file to user for download
    send_file(
      save_path,
      filename: "#{@upload.upload.original_filename}"
      # type: ""
    )
  end

  private

  # def set_upload
  #   @upload = current_user.uploads.find(params[:id])
  # end

  def upload_params
    params.require(:upload).permit(:direct_upload_url)
  end
end