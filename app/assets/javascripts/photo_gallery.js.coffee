# A PhotoGallery is instantiated when a user clicks the option to view an image as a gallery, showing all photos
# from the topic within a modal.

#= require litejot

class window.PhotoGallery extends LiteJot
  constructor: (@lj, @topic_id, @jot) ->
    # @jot is the jot object containing the image that is clicked when the
    # gallery is instantiated.
    @initVars()
    @getRelevantJots()
    @initCloseBind()
    @initDirectionalBinds()
    @showOverlay()
    @focusOverlay()
    @initKeyboardShortcuts()
    #@populateThumbnails()
    @showImage @jot
    @determineDirectionalButtonStates()

  initVars: =>
    @overlay = $('#photo-gallery-overlay')
    @featured = $('img#photo-gallery-featured')
    @thumbnail_list = $('ul#photo-gallery-thumbnails')
    @options = $('ul#options')
    @close_link = $('a.close')
    @upload_jots = []
    @current_id = @jot.id
    @loader = @overlay.find('.loader')

  # Grabs all jots in topic that are of type 'upload'
  getRelevantJots: =>
    jots = @lj.app.jots.filter((jot) => jot.topic_id == @topic_id && jot.jot_type == 'upload')
    jots = $.map jots, (jot) =>
      return jot.id
    @upload_jots = jots
    console.log @upload_jots

  initCloseBind: =>
    @close_link.click (e) =>
      e.preventDefault()
      @close()

    # Clicking anywhere but the image or an action (i.e., the overlay) should close the gallery
    @overlay.click =>
      @close()

    @featured.click (e) =>
      e.stopPropagation()

    @options.click (e) =>
      e.stopPropagation()

  initDirectionalBinds: =>
    @options.find('a.previous').click =>
      @showPrevious()

    @options.find('a.next').click =>
      @showNext()

  showOverlay: =>
    @overlay.show()

  hideOverlay: =>
    @overlay.hide()

  focusOverlay: =>
    @overlay.focus()

  initKeyboardShortcuts: =>
    # Considered putting these in the KeyControls module..
    # but since PhotoGallery objects come and go, and there
    # aren't many controls, they can be here for now.
    @overlay.keyup (e) =>
      if e.keyCode == @lj.key_controls.key_codes.esc
        @close()
      else if e.keyCode == @lj.key_controls.key_codes.left
        @showPrevious()
      else if e.keyCode == @lj.key_controls.key_codes.right
        @showNext()

  unInitKeyboardShortcuts: =>
    @overlay.unbind 'keyup'

  # populateThumbnails: =>
  #   $.each @upload_jots, (index, jot) =>
  #     console.log jot
  #     $elem = $('<li />')
  #     info = JSON.parse(jot.content)
  #     $img = $("<img src='#{info.thumbnail}' />")
  #     $elem.append $img
  #     @thumbnail_list.append $elem

  setSize: =>
    @featured.css 'margin-top', ((@overlay.height() - @featured.height())/2)+'px'
    @featured.css 'margin-left', ((@overlay.width() - @featured.width())/2)+'px'

  showImage: (jot) =>
    console.log jot
    info = JSON.parse(jot.content)
    image = info.original

    @featured.attr('src', '').attr('data-jot-id', jot.id)
    $downloading_image = $("<img />").attr('src', image).attr('data-jot-id', jot.id)
    @loader.show()
    $downloading_image.load =>
      # If they're going quickly and queueing all of these load events, we'll want to 
      # make sure the image they're actually scrolled to.
      # Compare this $downloading_image element to the actual, featured image object
      # which is currently empty/unloaded.
      if @current_id == parseInt($downloading_image.attr('data-jot-id'))
        @featured.attr('src', image)
        @loader.hide()
        @setSize()

    @options.find('a.external-link').attr 'href', image
    @options.find('a.download-link').attr 'href', "uploads/#{info.upload_id}/download"

  showPrevious: =>
    index = @upload_jots.indexOf @current_id
    if index == 0
      # Cannot move further left
      return

    else
      @current_id = @upload_jots[index-1]
      new_jot = @lj.app.jots.filter((jot) => jot.id == @current_id)[0]
      @showImage(new_jot)

    @determineDirectionalButtonStates()

  showNext: =>
    index = @upload_jots.indexOf @current_id
    if index == @upload_jots.length - 1
      # Cannot move further right
      return

    else
      @current_id = @upload_jots[index+1]
      new_jot = @lj.app.jots.filter((jot) => jot.id == @current_id)[0]
      @showImage(new_jot)

    @determineDirectionalButtonStates()

  determineDirectionalButtonStates: =>
    index = @upload_jots.indexOf @current_id

    # Previous button
    if index == 0
      @options.find('a.previous').addClass('disabled')
    else
      @options.find('a.previous').removeClass('disabled')

    # Next button
    if index == @upload_jots.length - 1
      @options.find('a.next').addClass('disabled')
    else
      @options.find('a.next').removeClass('disabled')

  close: =>
    # Unbind resize function
    # Unbind options
    @hideOverlay()

    # Set lj.current_photo_gallery to null since one will no longer be opened.
    @lj.current_photo_gallery = null

    # Unbind keyboard shortcuts
    @unInitKeyboardShortcuts()


