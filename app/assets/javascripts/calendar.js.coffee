#= require litejot

class window.Calendar extends LiteJot
  constructor: (@lj) ->
    @initVars()

    if @cal_link.is(':visible')
      @initBinds()
      @loadCalItems()

  initVars: =>
    @cal_list_wrap = $('#cal-list-wrap')
    @cal_items_elem = $('#cal-items')
    @cal_link = $('a#calendar-link')
    @cal_loaded_data = null
    @cal_items = {}
    @month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    @cal_empty_message = $('#cal-empty-message')
    @cal_loading = $('#cal-loading')

  initBinds: =>
    @cal_link.click (event) =>
      event.stopPropagation()
      if @cal_list_wrap.is(':visible')
        @closeCal()
      else
        @openCal()

    @cal_list_wrap.click (event) =>
      event.stopPropagation()

    $('a#calendar-info-modal-link').click (e) =>
      $('#calendar-info-modal').foundation 'reveal', 'open'
      $('#calendar-info-modal').html($('#calendar-info-modal-template').html())

      $('#calendar-info-modal .confirm').click (e2) =>
        $('#calendar-info-modal').foundation 'reveal', 'close'

    $(document).bind 'click', () =>
      @closeCal()

  openCal: =>
    @cal_list_wrap.show()
    @cal_link.addClass('active')
    @positionCal()

  closeCal: =>
    @cal_list_wrap.hide()
    @cal_link.removeClass('active')
    @cal_link.removeClass('active')
    @cal_link.removeClass('active')

  showLoading: =>
    @cal_loading.show()

  hideLoading: =>
    @cal_loading.hide()

  positionCal: =>
    pos_top = @cal_link.offset().top + @cal_link.height()
    pos_right = $(document).width() - @cal_link.offset().left - @cal_link.outerWidth()
    @cal_list_wrap.css({
      top: pos_top
      right: pos_right
    })

  loadCalItems: =>
    @showLoading()

    $.ajax(
      type: 'GET'
      url: '/notifications/calendar'
      success: (data) =>
        console.log data
        @user_email = data.user_email
        @cal_loaded_data = $.parseJSON(data.calendar_items)
        @handleCalData()
        @hideLoading()

      error: (data) =>
        console.log data
    )

  handleCalData: =>
    console.log @cal_loaded_data

    $.each @cal_loaded_data, (index, cal_item) =>
      if !@cal_items[cal_item.start.day]
        @cal_items[cal_item.start.day] = []

      @cal_items[cal_item.start.day].push cal_item

    @updateCalView()

    console.log @cal_items

  updateCalView: =>
    if $.isEmptyObject @cal_items
      @cal_empty_message.show()
    else
      @cal_empty_message.hide()

      html = ""
      
      $.each @cal_items, (key, items) =>
        date = new Date(items[0].start.dateTime)
        date_heading = "#{@month_names[date.getMonth()]} #{date.getDate()}"

        html += "<article id='cal-items-of-#{key.toLowerCase()}'>"
        html += "<h3>"
        html += "#{key}"
        html += "<span class='date'>#{date_heading}</span>"
        html += "</h3>"
        html += "<ul>"

        $.each items, (index, cal_item) =>
          attendees_text = ''
          if cal_item.attendees
            $.each cal_item.attendees, (index, attendee) =>
              if attendee
                if attendee.email == @user_email
                  cal_item.attendees.remove(index)
                  return

            attendees_count = cal_item.attendees.length

            $.each cal_item.attendees, (index, attendee) =>
              if index == attendees_count - 1 && attendees_count > 1
                attendees_text += " and "

              attendees_text += "#{attendee.displayName}"

              if index < attendees_count - 2
                attendees_text += ", "

          day = cal_item.start.day
          date = new Date(cal_item.start.dateTime)
          am_pm = if date.getHours() >= 12 then "pm" else "am"
          hour = (date.getHours() % 12)
          hour = if hour == 0 then 12 else hour
          minutes = date.getMinutes()
          minutes = if minutes == 0 then "00" else minutes

          event_class = if cal_item.event_finished then 'event-finished' else ''

          html += "<li class='#{event_class}'>"
          html += "<section class='time'>#{hour}:#{minutes}#{am_pm}</section>"

          html += "<h4>#{cal_item.summary}</h4>"

          if attendees_count > 0
            html += "<p>"
            attendees_text = "<i class='fa fa-group' />with "+ attendees_text
            html += attendees_text
            html += "</p>"

          html += "</li>"

        html += "</ul>"
        html += "</article>"

      @cal_items_elem.html(html)
