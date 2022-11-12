module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  wol = require('wol')
  
  # Device class representing the LG Smart TV
  class LgSmartTvDevice extends env.devices.PowerSwitch

    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @_state = lastState? || false
      @_interval = 5000
      @id = @config.id
      @name = @config.name
      @debug = @plugin.debug || false
      @tvIp = @config.tvIp
      @tvMac = @config.tvMac
      @key = @config.key
      @_tvStarting = false
      @_remote = null
      @_powerStates = {
        'Active':         true,
        'Active Standby': false
      }
      super()
      
      process.nextTick () =>
        @_checkStatus()

    _checkStatus: () ->
      state = false
      
      @_base.cancelUpdate()
      
      remote = @plugin.getRemote(@tvIp, @key)
      return remote.getPowerState().then( (power) =>
        @_setState @_powerStates[power.state]
        
        remote.getActiveApp()
      ).then( (application) =>
        if application?
          #@_setState true
          @plugin.emit('tvReady', {ip: @tvIp, key: @key })
          @plugin.emit('currentInput', @tvIp, application)
          
          @_base.debug __("Connected to: %s", @tvIp)
          @_base.debug __("Current App: %s", application.appId)
        
      ).then( () =>
        remote.getActiveChannel().then( (channel) =>
          @plugin.emit('currentChannel', @tvIp, channel) if channel?
        
        ).catch( (error) =>
          @plugin.emit('currentChannel', @tvIp, {})
        )
      
      ).catch( (error) =>
        console.log(error)
        @_base.debug __("Could not connect: %s", error.code)
        #@_setState false
      
      ).finally( () =>
        @_base.scheduleUpdate @_checkStatus, @_interval
      
      )
    
    showMessage: (message) =>
      return @plugin.getRemote(@tvIp, @key).createToast( message ).then( (res) =>
        @_base.debug __("Message %s displayed on %s", message, @name)
        Promise.resolve()
      
      ).catch( (error) =>
        @_base.logErrorWithLevel( "warn", __("Message not displayed on %s", @name))
        Promise.reject()
      
      )
    
    destroy: () ->
      @_base.cancelUpdate()
      super()
 
    changeStateTo: (newState) ->
      if newState is @_state
        return Promise.resolve()
      
      unless newState
        return @plugin.getRemote(@tvIp, @key).turnOff().then( (res) =>
          @_setState newState
          @_base.debug "State changed to: ", newState
          Promise.resolve()
        
        ).catch( (error) =>
          @_base.logErrorWithLevel( "warn", error)
          Promise.reject()
        
        )
      
      else
        return wol.wake( @tvMac).then( (res) =>
          @_setState newState
          @_base.debug "LG TV State changed to: ", newState
          @_tvStarting = true
          Promise.resolve()
        
        )
        .catch( (error) => 
          @_base.logErrorWithLevel( "warn", __("Error turning on TV: %s", error))
          Promise.reject()
        )
     
    getState: () ->
      return Promise.resolve @_state
