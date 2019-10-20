module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  
  LgSmartTvButtonsDevice = require('./lg-smart-tv-buttons-device')(env)
  webos = Promise.promisifyAll(require('webos'))
  Remote = webos.Remote
  
  class LgSmartTvChannelsDevice extends LgSmartTvButtonsDevice
    constructor: (@config, @plugin, lastState) ->
      super(@config, @plugin, lastState)
    
    buttonPressed: (buttonId) ->
      @_executeAction(buttonId)
      return Promise.resolve()
    
    _action: (button, key) =>
      promise = null
      remote = @plugin.getRemote()
      
      return remote.connectAsync({ address: @config.tvIp, key: key }).then( (res) =>
        remote.setChannelAsync(button.webosId)
      
      ).then( (res) =>
        @_base.debug __("TV changed to channel %s", button.text)
        promise = Promise.resolve()
      
      ).catch( (error) =>
        @_base.logErrorWithLevel( "warn", __("Could not change to channel %s", button.text))
        promise = Promise.reject()
      
      ).finally( () =>
        remote.disconnectAsync()
        return promise
      )
    
    destroy: () ->
      super()