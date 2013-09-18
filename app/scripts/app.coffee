define [
  "underscore"
  "jquery"
  "backbone"
  "handlebars"
  "lib/extension"
  "text!../templates/root.hbs"
  "text!../templates/container.hbs"
], (
  _
  $
  Backbone
  Handlebars
  Extension
  rootTemplate
  containerTemplate
) ->
  class App
    open: false
    loading: false
    commands: []
    env: if chrome.runtime then "extension" else "development"

    constructor: ->
      _.extend this, Backbone.Events

      @on "open", @setOpen.bind(this)
      @on "close", @setClosed.bind(this)

    start: (storage) ->
      @appendContainer()
      @trigger "loadConsole.action"

      @on "load.commands", @setOpen.bind(this)
      @on "load.commands sync.commands", (commands) =>
        if storage?.importedCommands
          @commands = commands.concat storage?.importedCommands
        else
          @commands = commands

      @on "execute.commands", @setLoading.bind(this)
      @on "executed.commands executionError.commands", @setLoaded.bind(this)

      Extension.trigger "ready.app"

      @on "toggle.app", ->
        if @open
          @trigger "close"
        else
          @trigger "open"

    setOpen: ->
      @open = true
      window._BACKTICK_OPEN = true

    setClosed: ->
      @open = false
      window._BACKTICK_OPEN = false

    setLoading: ->
      @loading = true
      @$console.addClass "loading"

    setLoaded: ->
      @loading = false
      @$console.removeClass "loading"

    appendContainer: ->
      @$el = $(Handlebars.compile(rootTemplate)()).appendTo "body"

      if @env is "extension"
        createShadowRoot = \
          @$el[0].createShadowRoot or @$el[0].webkitCreateShadowRoot

        shadow = createShadowRoot.apply @$el[0]

        cssPath = "styles/style.css"
        cssPath = chrome.extension.getURL(cssPath) if chrome.extension
        shadow.innerHTML = Handlebars.compile(containerTemplate)(cssPath: cssPath)

        @$console = $ shadow.querySelector("#console")
        @$results = $ shadow.querySelector("#results")
        @$settings = $ shadow.querySelector("#settings")
      else
        @$el.append Handlebars.compile(containerTemplate)(cssPath: null)

        @$console = @$el.find "#console"
        @$results = @$el.find "#results"
        @$settings = @$el.find "#settings"

  new App