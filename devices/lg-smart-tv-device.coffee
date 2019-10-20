module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)

  wol = require('wol')

  webos = Promise.promisifyAll(require('webos'))
  Remote = webos.Remote
  
  # Device class representing the LG Smart TV
  class LgSmartTvDevice extends env.devices.PowerSwitch

    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @_state = lastState? || false
      @_interval = 5
      @id = @config.id
      @name = @config.name
      @debug = @plugin.debug || false
      @tvIp = @config.tvIp
      @tvMac = @config.tvMac
      @key = @config.key
      @_tvStarting = false
      @_remote = null
      
      super()
      
      process.nextTick () =>
        @_checkStatus()

    _checkStatus: () ->
      state = false
      
      @_base.cancelUpdate()
      @emit('tvReady', {ip: @tvIp, key: @key })
      remote = @plugin.getRemote()
      remote.connectAsync({
        address: @tvIp, 
        key: @key
      }).then( () =>
        state = true
        @_tvStarting = false
        @_base.debug __("Connected to: %s", @tvIp)
      ).catch( (error) =>
        @_base.debug __("Could not connect: %s", error.code)
        state = false
        @_tvStarting = false
      )
      .finally( () =>
        @_setState state if ! @_tvStarting
        @_base.debug "LG TV Power status: ", state
        remote.disconnectAsync()
        remote = null
        @_base.scheduleUpdate @_checkStatus, @_interval * 1000
        
      )
    
    _getRemote: () =>
      return new Remote({
        debug: @debug, 
        reconnect: false, 
        connectTimeout: false
      })
    
    showMessage: (message) =>
      remote = @_getRemote()
      remote.connectAsync({ address: @tvIp, key: @key }).then( (res) =>
        remote.showFloatAsync( message )
      
      ).then( (res) =>
        @_base.debug __("Message %s displayed on %s", message, @name)
        Promise.resolve()
      
      ).catch( (error) =>
        @_base.logErrorWithLevel( "warn", __("Message not displayed on %s", @name))
        Promise.reject()
      
      ).finally( () =>
        remote.disconnectAsync()
      )
    
    destroy: () ->
      @_base.cancelUpdate()
      super()
 
    changeStateTo: (newState) ->
      if newState is @_state
        return Promise.resolve()
      
      unless newState
        remote = @_getRemote()
        remote.connectAsync( { address: @tvIp, key: @key } ).then( (res) =>
          remote.turnOffAsync()
          @_setState newState
          @_base.debug "LG TV State changed to: ", newState
          Promise.resolve()
        
        ).catch( (error) =>
          @_base.logErrorWithLevel( "warn", error)
          Promise.reject()
        
        ).finally( () =>
          remote.disconnectAsync()
        )
      
      else
        wol.wake( @tvMac).then( (res) =>
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
