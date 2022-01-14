module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  
  webos = Promise.promisifyAll(require('../lib/remote.js'))
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
      
      @_buttonPressPending = false
      
      @_lastPressedButton = lastState?.button?.value
      for button in @config.buttons
        @_button = button if button.id is @_lastPressedButton
      
    buttonPressed: (buttonId) ->
      return Promise.resolve() if buttonId is @_lastPressedButton || @_buttonPressPending
      
      @_executeAction(buttonId).then( () =>
        @_buttonPressPending = false
      
      ).finally( () =>
        return Promise.resolve()
      )
    
    _executeAction: (buttonId) =>
      
      return new Promise( (resolve, reject) =>
        @config.buttons.map( (button) =>
          if button.id is buttonId
            @_buttonPressPending = true
            @_lastPressedButton = button.id
            @emit 'button', button.id
            @_button = button
            
            tv = @_getDevice()
            return reject() if ! tv?
            
            tv.getState().then( (state) =>
              # TV is ON
              if state
                @_action(@_button, tv.key).then( () =>
                  @_buttonPressPending = false
                  return resolve()
                )
              
              #TV is OFF
              tv.changeStateTo(true).then( () =>
                
                # Wait until TV ready to accept requests
                @plugin.once('tvReady', () =>
                  @_action(@_button, tv.key).then( () =>
                    @_buttonPressPending = false
                    return resolve()
                  )
                )
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
      super()