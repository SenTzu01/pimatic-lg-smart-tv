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
      @_tv.on('currentChannel', @_updateButton)
    
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
    
    _updateButton: (ip, channel) =>
      @_base.debug(__("channel.id: %s, channel.name: %s", channel.id, channel.name))
      
      return Promise.resolve() if ip isnt @config.tvIp
      
      if channel?.id isnt @_button.webosId
        buttonId = channel.name.toLowerCase().replace(/[\s\/%!&]/g,'-')
        @buttonPressed(buttonId)
      return Promise.resolve()
    
    destroy: () ->
      @_tv.removeListener("currentChannel", @_updateButton)
      super()