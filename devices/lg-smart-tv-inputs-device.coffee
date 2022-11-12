module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  
  LgSmartTvButtonsDevice = require('./lg-smart-tv-buttons-device')(env)
  
  class LgSmartTvInputsDevice extends LgSmartTvButtonsDevice
    
    constructor: (@config, @plugin, lastState) ->
      super(@config, @plugin, lastState)
      @plugin.on('currentInput', @_updateButton)

    _action: (button, key) =>
      return @plugin.getRemote(@_tv.tvIp, @_tv.key).launchApp(button.id).then( (res) =>
        @_base.debug __("TV changed to input %s", button.text)
        return Promise.resolve()
      
      ).catch( (error) =>
        @_base.logErrorWithLevel( "warn", __("Could not change to input %s", button.text))
        return Promise.reject()
      
      )
    
    _updateButton: (ip, input) =>
      @_base.debug(__("input.id: %s", input.appId))
      
      return Promise.resolve() if ip isnt @config.tvIp
      
      if input?.appId isnt @_button.id
        @buttonPressed(input.id)
      return Promise.resolve()
    
    destroy: () ->
      @plugin.removeListener("currentInput", @_updateButton)
      super()