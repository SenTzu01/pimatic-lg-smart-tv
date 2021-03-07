module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)


  class LgSmartTvPresenceSensor extends env.devices.PresenceSensor

    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @id = @config.id
      @name = @config.name
      @tvIp = @config.tvIp
      
      @_interval = @_base.normalize @config.interval, 2
      
      @volumeDecibel = @config.volumeDecibel
      @debug = @plugin.debug || false
      
      @attributes = _.cloneDeep(@attributes)
      
      @attributes.input = {
        description: "Input Source"
        type: "string"
        acronym: 'INPUT'
      }
      
      @_presence = lastState?.presence?.value
      @_input = ""
      super()
      
      process.nextTick () =>
        #@_checkStatus()
    
    _checkStatus: () ->
      state = false
      
      @_base.cancelUpdate()
      
      remote = @plugin.getRemote()
      remote.connectAsync({ address: @tvIp, key: @config.key }).then( () =>
        @_base.debug __("Connected to: %s", @tvIp)
        state = true
        @_tvStarting = false
        
        @emit('tvReady', {ip: @tvIp, key: @key })
        
        remote.getAppAsync().then( (app) =>
        
          @emit('currentApp', @config.tvIp, app) if app?
          remote.getChannelAsync()
        
        ).then( (channel) =>
          
          @emit('currentChannel', @tvIp, channel) if channel?
          remote.getInputAsync()
        
        ).then( (input) =>
          
          @emit('currentInput', @tvIp, input) if input?
          Promise.resolve()
        
        ).catch( (error) =>
          @_base.debug(error)
          Promise.resolve()
        )
      ).catch( (error) =>
        @_base.debug __("Could not connect: %s", error.code)
        state = false
      
      ).finally( () =>
        @_setPresence state if ! @_tvStarting
        @_base.debug "LG TV Presence status: ", state
        remote.disconnectAsync()
        remote = null
        @_base.scheduleUpdate @_checkStatus, @_interval * 1000
      
      )
    
    destroy: () ->
      @_base.cancelUpdate()
      super()

    getPresence: () ->
      return new Promise.resolve @_presence

    getInput: () ->
      return new Promise.resolve @_input