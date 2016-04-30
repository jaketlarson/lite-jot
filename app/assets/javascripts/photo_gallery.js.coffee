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
    @initAnnotationsToggleBind()
    @showGallery()
    @focusContainer()
    @initKeyboardShortcuts()
    #@populateThumbnails()
    @showImage @jot
    @determineDirectionalButtonStates()
    @checkIfAnnotationsAlreadyActive()

  initVars: =>
    @overlay = $('#photo-gallery-overlay')
    @container = $('#photo-gallery-container')
    @featured = $('img#photo-gallery-featured')
    @featured_wrap = $('#photo-gallery-featured-wrap')
    @thumbnail_list = $('ul#photo-gallery-thumbnails')
    @options = $('ul#options')
    @close_link = $('a.close')
    @annotations_toggle_link = @container.find('a.annotations-toggle')
    @next_link = @options.find('a.next')
    @prev_link = @options.find('a.previous')
    @external_link = @options.find('a.external-link')
    @download_link = @options.find('a.download-link')
    @upload_jots = []
    @current_id = @jot.id
    @loader = @container.find('.loader')
    @annotations_active = false

  # Grabs all jots in topic that are of type 'upload'
  getRelevantJots: =>
    jots = @lj.app.jots.filter((jot) => jot.topic_id == @topic_id && jot.jot_type == 'upload')
    jots = $.map jots, (jot) =>
      return jot.id
    @upload_jots = jots

  initCloseBind: =>
    @close_link.click (e) =>
      e.preventDefault()
      @close()

    # Clicking anywhere but the image or an action (i.e., the conatiner) should close the gallery
    @container.click =>
      @close()
    @overlay.click =>
      @close()

    @featured.click (e) =>
      e.stopPropagation()

    @options.click (e) =>
      e.stopPropagation()

  initDirectionalBinds: =>
    @prev_link.click =>
      @showPrevious()

    @next_link.click =>
      @showNext()

  showGallery: =>
    @overlay.show()
    @container.show()

  hideGallery: =>
    @overlay.hide()
    @container.hide()

  focusContainer: =>
    @container.focus()

  initKeyboardShortcuts: =>
    # Considered putting these in the KeyControls module..
    # but since PhotoGallery objects come and go, and there
    # aren't many controls, they can be here for now.
    @container.keyup (e) =>
      if e.keyCode == @lj.key_controls.key_codes.esc
        @close()
      else if e.keyCode == @lj.key_controls.key_codes.left
        @showPrevious()
      else if e.keyCode == @lj.key_controls.key_codes.right
        @showNext()

  unInitKeyboardShortcuts: =>
    @container.unbind 'keyup'

  setSize: =>
    # Grab the allowed size vs. actual size ratio
    jot_id = parseInt(@featured.attr('data-jot-id'))
    jot = @lj.app.jots.filter((jot) => jot.id == jot_id)[0]
    info = JSON.parse(jot.content)

    if info.width / @container.innerWidth() > info.height / @container.innerHeight()
      size_ratio = Math.min(@container.innerWidth() / info.width, 1)
    else
      size_ratio = Math.min(@container.innerHeight() / info.height, 1)

    max_allowed_width = @container.innerWidth() - parseInt(@container.css('paddingLeft')) - parseInt(@container.css('paddingRight'))
    max_allowed_height = @container.innerHeight() - parseInt(@container.css('paddingTop')) - parseInt(@container.css('paddingBottom'))
    inner_width_minus_padding = @container.innerWidth() - parseInt(@container.css('paddingLeft')) - parseInt(@container.css('paddingRight'))
    inner_height_minus_padding = @container.innerHeight() - parseInt(@container.css('paddingTop')) - parseInt(@container.css('paddingBottom'))
    calc_width = Math.min(info.width*size_ratio, max_allowed_width)
    calc_height = Math.min(info.height*size_ratio, max_allowed_height)

    @featured_wrap.css 'width', calc_width+'px'
    @featured_wrap.css 'height', calc_height+'px'

  showImage: (jot) =>
    info = JSON.parse(jot.content)
    image = info.original

    if @annotations_active
      @lj.jots.removeAnnotations @featured_wrap

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

        if @annotations_active
          @lj.jots.showAnnotations jot, @featured_wrap

    @external_link.attr 'href', image
    @download_link.attr 'href', "uploads/#{info.upload_id}/download"

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
      @prev_link.addClass('disabled')
    else
      @prev_link.removeClass('disabled')

    # Next button
    if index == @upload_jots.length - 1
      @next_link.addClass('disabled')
    else
      @next_link.removeClass('disabled')

  initAnnotationsToggleBind: =>
    @annotations_toggle_link.click =>
      @toggleAnnotations()

  toggleAnnotations: =>
    @annotations_active = !@annotations_active

    if @annotations_active
      @annotations_toggle_link.addClass 'active'
      jot_id = parseInt @featured.attr('data-jot-id')
      jot = @lj.app.jots.filter((jot) => jot.id == jot_id)[0]

      # Since annotations can take a second to build and size correctly,
      # let's show the loading bar for a sec
      @loader.show()
      setTimeout(() =>
        @lj.jots.showAnnotations jot, @featured_wrap
        @loader.hide()
      , 0)

    else
      @annotations_toggle_link.removeClass('active')
      @lj.jots.removeAnnotations @featured_wrap

  checkIfAnnotationsAlreadyActive: =>
    # If the photo gallery is opened, annotations turned on, then closed, then reopened,
    # annotations icon may still be active, so we should show 
    if @annotations_toggle_link.hasClass 'active'
      @toggleAnnotations()

  close: =>
    # Unbind resize function
    # Unbind options
    @annotations_toggle_link.unbind 'click'
    @next_link.unbind 'click'
    @prev_link.unbind 'click'
    @external_link.unbind 'click'
    @download_link.unbind 'click'

    @hideGallery()

    # Set lj.current_photo_gallery to null since one will no longer be opened.
    @lj.current_photo_gallery = null

    # Unbind keyboard shortcuts
    @unInitKeyboardShortcuts()

    # Remove any possible annotations from the photo gallery
    if @annotations_active
      @lj.jots.removeAnnotations @featured_wrap


