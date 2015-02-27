# Array Remove - By John Resig (MIT Licensed)
Array::remove = (from, to) ->
  rest = @slice((to or from) + 1 or @length)
  @length = if from < 0 then @length + from else from
  @push.apply this, rest

$ ->
  window.lj = {
    lightjot: new window.LightJot()
  }

class window.LightJot
  constructor: ->
    @fullscreen = new LightJot.Fullscreen()
    @jots = new Jots(@)
    @topics = new Topics(@)
    @initVars()
    @sizeUI()
    @loadDataFromServer()

  initVars: =>
    @app = {} # all loaded app data goes here

    @key_codes =
      enter: 13

  sizeUI: =>
    jots_height = window.innerHeight - $('header').outerHeight() - $('#jots-heading').outerHeight(true) - @jots.new_jot_content.outerHeight(true)
    @jots.jots_wrapper.css 'height', jots_height

    topics_height = window.innerHeight - $('header').outerHeight() - $('#topics-heading').outerHeight(true)
    @topics.topics_wrapper.css 'height', topics_height

  loadDataFromServer: =>
    $.ajax(
      type: 'GET'
      url: '/load-data'
      success: (data) =>
        console.log data
        @app.folders = data.folders
        @app.topics = data.topics
        @app.jots = data.jots

        @topics.buildTopicsList()
        $.each @app.topics, (index, topic) =>
          @topics.initTopicBinds(topic.id)

        @topics.initNewtopicListeners()
        @jots.buildJotsList()

      error: (data) =>
        console.log data
    )
