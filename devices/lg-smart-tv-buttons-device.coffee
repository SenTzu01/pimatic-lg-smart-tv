module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  
  webos = Promise.promisifyAll(require('webos'))
  Remote = webos.Remote
  
  class LgSmartTvButtonsDevice extends env.devices.ButtonsDevice

    constructor: (@config, @plugin, lastState) ->
      for b in @config.buttons
        b.text = b.id unless b.text?
      
      @_base = commons.base @, @config.class
      @debug = @plugin.debug || false
      @id = @config.id
      @name = @config.name
      @_button = {}
      super(@config)
      
      @_tv = @_getDevice()
      #@_tv.on('tvReady', @_updateButton)
      
      @_lastPressedButton = lastState?.button?.value
      for button in @config.buttons
        @_button = button if button.id is @_lastPressedButton
      

    
    _executeAction: (buttonId) =>
      
      for button in @config.buttons
        if button.id is buttonId
          @_lastPressedButton = button.text
          @emit 'button', button.id
          @_button = button
          
          tv = @_getDevice()
          return Promise.reject() if ! tv?
          
          tv.getState().then( (state) =>
            # TV is ON
            return @_action(@_button, tv.key) if state
            
            #TV is OFF
            tv.changeStateTo(true).then( () =>
              return new Promise( (resolve, reject) =>
                # Wait until TV ready to accept requests
                tv.once('tvReady', () =>
                  @_action(@_button, tv.key)
                )
              )
            )
          )
    
    _getDevice: () =>
      return _(@plugin.framework.deviceManager.devices).values().filter(
        (device) => device.config.class is 'LgSmartTvDevice' and device.tvIp is @config.tvIp
      ).value()[0]
    
    _action: () =>
      throw new error("Method _executeAction() not implemented!")
      
    _updateButton: (tv) =>
      throw new error("Method _updateButton() not implemented!")
    
    destroy: () ->
      #@_tv.removeListener("tvReady", @_updateButton)
      super()