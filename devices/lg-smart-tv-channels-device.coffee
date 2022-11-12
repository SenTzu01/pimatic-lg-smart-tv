module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  
  LgSmartTvButtonsDevice = require('./lg-smart-tv-buttons-device')(env)
  
  class LgSmartTvChannelsDevice extends LgSmartTvButtonsDevice
    constructor: (@config, @plugin, lastState) ->
      super(@config, @plugin, lastState)
      @plugin.on('currentChannel', @_updateButton)
    
    _action: (button, key) =>
      return @plugin.getRemote(@_tv.tvIp, @_tv.key).setChannel(button.webosId).then( (res) =>
        @_base.debug __("TV changed to channel %s", button.text)
        Promise.resolve()
      
      ).catch( (error) =>
        @_base.logErrorWithLevel( "warn", error)
        @_base.logErrorWithLevel( "warn", __("Could not change to channel %s", button.text))
        Promise.reject()
      
      )
    
    _updateButton: (ip, channel) =>
      return Promise.resolve() unless channel?.id?
      @_base.debug(__("channel.id: %s, channel.name: %s", channel.id, channel.name))
      
      return Promise.resolve() if ip isnt @config.tvIp
      
      if channel?.id isnt @_button.webosId
        buttonId = channel.name.toLowerCase().replace(/[\s\/%!&]/g,'-')
        @buttonPressed(buttonId)
      return Promise.resolve()
    
    destroy: () ->
      @plugin.removeListener("currentChannel", @_updateButton)
      super()