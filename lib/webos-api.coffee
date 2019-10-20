module.exports = (env) =>
  
  Promise = env.require 'bluebird'
  commons = require('pimatic-plugin-commons')(env)
  webos = Promise.promisifyAll(require('webos'))
  wol = require('wol')
  
  class WebOSApi
    constructor: (conn) ->
      
      @_ip = conn.ip
      @_key = conn.key
      @_debug = conn.debug
      
    changeChannel: (channel) =>
    
    changeInput: (input) =>
    
    changeApp: (app) =>
    
    
    
    destruct: () ->