module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  
  LgSmartTvButtonsDevice = require('./lg-smart-tv-buttons-device')(env)
  
  class LgSmartTvAppsDevice extends LgSmartTvButtonsDevice
    
    constructor: (@config, @plugin, lastState) ->
      super(@config, @plugin, lastState)
      @plugin.on('currentApp', @_updateButton)

    _action: (button, key) =>
      console.log(button.id)
      return @plugin.getRemote(@_tv.tvIp, @_tv.key).launchApp(button.id).then( (res) =>
        @_base.debug __("Application %s started on TV", button.text)
        return Promise.resolve()
      
      ).catch( (error) =>
        @_base.logErrorWithLevel( "warn", __("Could not start application %s", button.text))
        return Promise.reject()
      
      )
    
    _updateButton: (ip, app) =>
      @_base.debug(__("app.id: %s", app.appId))
      
      return Promise.resolve() if ip isnt @config.tvIp
      
      if @_button.id isnt app?.id
        @buttonPressed(app.id)
      return Promise.resolve()
    
    destroy: () ->
      @plugin.removeListener("currentApp", @_updateButton)
      super()