uploadcare.whenReady ->
  {
    namespace,
    utils,
    jQuery: $
  } = uploadcare

  namespace 'uploadcare.widget.tabs', (ns) ->
    ns.RemoteTabFor = (service) ->
      class RemoteTab
        constructor: (@dialog, @settings, @callback) ->

        setContent: (@content) ->

          @dialog.progress (tab) =>
            if tab == service
              @createIframe()


        createIframe: ->
          unless @iframe
            @windowId = utils.uuid()
            @createWatcher()

            src = "#{@settings.socialBase}/window/#{@windowId}/#{service}"
            @iframe = $('<iframe>')
              .attr('src', src)
              .css
                width: '100%'
                height: '100%'
                border: 0
              .appendTo(@content)

        createWatcher: ->
          unless @watcher
            @watcher = new utils.pubsub.PubSub @settings, 'window', @windowId
            $(@watcher).on('done', (e, state) =>
              @cleanup()
              @callback('url', state.url)
            )
            @watcher.watch()

        cleanup: ->
          @watcher.stop()
          @watcher = null
          @iframe.remove()
          @iframe = null