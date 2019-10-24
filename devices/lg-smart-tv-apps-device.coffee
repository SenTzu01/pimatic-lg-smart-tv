module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  
  LgSmartTvButtonsDevice = require('./lg-smart-tv-buttons-device')(env)
  webos = Promise.promisifyAll(require('webos'))
  Remote = webos.Remote
  
  class LgSmartTvAppsDevice extends LgSmartTvButtonsDevice
    
    constructor: (@config, @plugin, lastState) ->
      super(@config, @plugin, lastState)
      @_tv.on('currentApp', @_updateButton)
    
    buttonPressed: (buttonId) ->
      @_executeAction(buttonId)
      return Promise.resolve()

    _action: (button, key) =>
      promise = null
      remote = @plugin.getRemote()
      
      return remote.connectAsync({ address: @config.tvIp, key: key }).then( (res) =>
        remote.openAppAsync(button.id, {})
      
      ).then( (res) =>
        @_base.debug __("Application %s started on TV", button.text)
        promise = Promise.resolve()
      
      ).catch( (error) =>
        @_base.logErrorWithLevel( "warn", __("Could not start application %s", button.text))
        promise = Promise.reject()
      
      ).finally( () =>
        remote.disconnectAsync()
        return promise
      )
    
    _updateButton: (ip, app) =>
      @_base.debug(__("app.id: %s", app.id))
      
      return Promise.resolve() if ip isnt @config.tvIp
      
      if @_button.id isnt app?.id
        @buttonPressed(app.id)
      return Promise.resolve()
    
    destroy: () ->
      @_tv.removeListener("currentApp", @_updateButton)
      super()