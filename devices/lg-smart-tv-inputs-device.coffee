module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  
  LgSmartTvButtonsDevice = require('./lg-smart-tv-buttons-device')(env)
  webos = Promise.promisifyAll(require('webos'))
  Remote = webos.Remote
  
  class LgSmartTvInputsDevice extends LgSmartTvButtonsDevice
    
    constructor: (@config, @plugin, lastState) ->
      super(@config, @plugin, lastState)
      @_tv.on('currentInput', @_updateButton)
    
    buttonPressed: (buttonId) ->
      @_executeAction(buttonId)
      return Promise.resolve()

    _action: (button, key) =>
      promise = null
      remote = @plugin.getRemote()
      
      return remote.connectAsync({ address: @config.tvIp, key: key }).then( (res) =>
        remote.setInputAsync(button.id)
      
      ).then( (res) =>
        @_base.debug __("TV changed to input %s", button.text)
        promise = Promise.resolve()
      
      ).catch( (error) =>
        @_base.logErrorWithLevel( "warn", __("Could not change to input %s", button.text))
        promise = Promise.reject()
      
      ).finally( () =>
        remote.disconnectAsync()
        return promise
      )
    
    _updateButton: (ip, input) =>
      @_base.debug(__("input.id: %s, input.name: %s", input.id, input.name))
      
      return Promise.resolve() if ip isnt @config.tvIp
      
      if input?.id isnt @_button.id
        @buttonPressed(input.id)
      return Promise.resolve()
    
    destroy: () ->
      @_tv.removeListener("currentInput", @_updateButton)
      super()