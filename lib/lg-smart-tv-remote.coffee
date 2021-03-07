module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  
  webos = Promise.promisifyAll(require('webos'))
  Remote = webos.Remote
  
  class LgSmartTVRemote
    
    constructor: (opts) ->
      return error("IP and key must be suppied!") if ! (opts.ip or opts.key)
      
      opts.debug ?= false
      opts.reconnect ?= false
      opts.connectTimeout ?= false
      @_opts = opts
      
      @_remote = new Remote({
        debug: @_opts.debug, 
        reconnect: @_opts.reconnect, 
        connectTimeout: @_opts.connectTimeout
      }
      @_connect()
    
    _connect: () =>
      @_remote.connectAsync(@_opts.ip, @_opts.key).then( () =>
        @_connected = true
      ).catch( (error) =>
        env.logger.error("Unable to connect")
      )
    
    setInput: (input) =>
      @_remote.setInputAsync(input)
      ).then( () =>
        @_disconnect()
      )
      
    setChannel: (channel) =>
      @_remote.setChannelAsync(channel)
      ).then( () =>
        @_disconnect()
      )
    
    startApp: (opts) =>
      opts ?= {}
      @_remote.openApp(app, opts)
      ).then( () =>
        @_disconnect()
      )
    
    _disconnect: () =>
      @_remote.disconnectAsync()
    
    destroy: () ->
      super()