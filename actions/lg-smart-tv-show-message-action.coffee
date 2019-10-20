module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  commons = require('pimatic-plugin-commons')(env)
  #
  _ = env.require 'lodash'
  M = env.matcher
  
  class LgSmartTvShowMessageActionProvider extends env.actions.ActionProvider
    constructor: (@framework) ->
      super()

    parseAction: (input, context) =>
      
      selectorDevices = _(@framework.deviceManager.devices).values().filter(
        (device) => device.config.class is 'LgSmartTvDevice'
      ).value()
      
      device = null
      match = null
      valueTokens = null

      
      # Try to match the input string with: set ->
      m = M(input, context).match(['show message '])
      m.matchStringWithVars( (m, ts) =>
        valueTokens = ts
        
        m.match(' on ', (m) ->
          m.matchDevice( selectorDevices, (m, d) ->
            # Already had a match with another device?
            if device? and device.id isnt d.id
              context?.addError(""""#{input.trim()}" is ambiguous.""")
              return
            device = d
            match = m.getFullMatch()
          )
        )
      )
      
      if match?
        assert device?
        assert valueTokens?
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new LgSmartTvShowMessageActionHandler(@framework, device, valueTokens)
        }
      else
        return null
  
  class LgSmartTvShowMessageActionHandler extends env.actions.ActionHandler
    constructor: (@framework, @device, @valueTokens) ->
      @_base = commons.base @
      @_variableManager = @framework.variableManager
      super()

    setup: ->
      @dependOnDevice(@device)
      super()

    executeAction: (simulate) =>
      @_variableManager.evaluateStringExpression(@valueTokens)
      .then (value) =>
        @showMessage "" + value, simulate

    showMessage: (message, simulate) =>
      if simulate
        return Promise.resolve(__("Would send: '%s' to %s"), message, @device.name)
      else
        res = ""
        @device.showMessage( message )
        return Promise.resolve(__("Message sent to %s", @device.name))
        
  
  return LgSmartTvShowMessageActionProvider
