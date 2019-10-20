module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  commons = require('pimatic-plugin-commons')(env)
  
  _ = env.require 'lodash'
  M = env.matcher
  
  class LgSmartTvStartAppActionProvider extends env.actions.ActionProvider
    constructor: (@framework) ->
      super()

    parseAction: (input, context) =>
      selectorDevices = _(@framework.deviceManager.devices).values().filter(
        (device) => device.config.class is 'LgSmartTvDevice'
      ).value()

      # Try to match the input string with: set ->
      m = M(input, context).match(['start app on '])

      device = null
      match = null
      valueTokens = null

      m.matchDevice selectorDevices, (m, d) ->
        # Already had a match with another device?
        if device? and device.id isnt d.id
          context?.addError(""""#{input.trim()}" is ambiguous.""")
          return

        device = d
        m.match(' with name ')
        .matchStringWithVars( (next, ts) =>
          valueTokens = ts
          match = next.getFullMatch()
        )

      if match?
      
        assert device?
        assert valueTokens?
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new LgSmartTvStartAppActionHandler(@framework, device, valueTokens)
        }
      else
        return null
  
  class LgSmartTvStartAppActionHandler extends env.actions.ActionHandler
    constructor: (@framework, @device, @input) ->
      @_variableManager = @framework.variableManager
      super()

    setup: ->
      @dependOnDevice(@device)
      super()

    executeAction: (simulate) =>
      @_variableManager.evaluateStringExpression(@input)
      .then (value) =>
        @StartApp "" + value, simulate

    StartApp: (value, simulate) =>
      if simulate
        return Promise.resolve(__("Would start application: '%s' on %s"), value, @device.name)
      else
        @device.startApp( value )
        return Promise.resolve(__("%s started on %s", value, @device.name))
        
  
  return LgSmartTvStartAppActionProvider
