module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  
  LgSmartTvButtonsDevice = require('./lg-smart-tv-buttons-device')(env)
  webos = Promise.promisifyAll(require('webos'))
  Remote = webos.Remote
  
  class LgSmartTvAppsDevice extends LgSmartTvButtonsDevice
    
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
    
    _updateButton: (tv) =>
      return Promise.resolve() if tv.ip isnt @config.tvIp
      
      remote = @plugin.getRemote()
      remote.connectAsync({ address: tv.ip, key: tv.key }).then( () =>
        remote.getAppAsync()
      
      ).then( (app) =>
        @_base.debug(__("app.id: %s", app.id))
        env.logger.info(@_button)
        env.logger.info(@_button.id isnt app.id)
        if @_button.id isnt app.id
          @buttonPressed(app.id)
        else
          Promise.resolve()
      
      ).catch( (error) =>
        @_base.debug("No TV app active")
      
      ).finally( () =>
        remote.disconnectAsync()
      )
      
    destroy: () ->
      super()