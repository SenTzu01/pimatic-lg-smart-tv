module.exports = (env) ->
  
  Promise = env.require 'bluebird'
  commons = require('pimatic-plugin-commons')(env)
  #webos = require('webos')
  webos = require('./lib/webos')
  Remote = webos.WebOSDevice
  Scanner = webos.WebOSDiscovery
  arp = Promise.promisifyAll(require('arp'))
  wol = require('wol')
    
  deviceConfigTemplates = [
    {
      "name": "LG Smart TV",
      "class": "LgSmartTvDevice"
    },
    {
      "name": "LG Smart TV Channels Device",
      "class": "LgSmartTvChannelsDevice"
    },
    {
      "name": "LG Smart TV Inputs Device",
      "class": "LgSmartTvInputsDevice"
    },
    {
      "name": "LG Smart TV Apps Device",
      "class": "LgSmartTvAppsDevice"
    }
  ]
  
  actionProviders = [
    'lg-smart-tv-show-message-action'
  ]
  
  # ###LgSmartTvPlugin class
  class LgSmartTvPlugin extends env.plugins.Plugin
    constructor: () ->
    
    init: (app, @framework, @config) =>
      @debug = @config.debug || false
      @_base = commons.base @, 'Plugin'

      # register devices
      deviceConfigDef = require("./device-config-schema")
      
      for device in deviceConfigTemplates
        className = device.class
        # convert camel-case classname to kebap-case filename
        filename = className.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase()
        classType = require('./devices/' + filename)(env)
        @_base.debug "Registering device class #{className}"
        @framework.deviceManager.registerDeviceClass(className, {
          configDef: deviceConfigDef[className],
          createCallback: @_callbackHandler(className, classType)
        })
      
      
      # register actions
      for provider in actionProviders
        className = provider.replace(/(^[a-z])|(\-[a-z])/g, ($1) ->
          $1.toUpperCase().replace('-','')) + 'Provider'
        classType = require('./actions/' + provider)(env)
        @_base.debug "Registering action provider #{className}"
        @framework.ruleManager.addActionProvider(new classType @framework)
      
      # auto-discovery
      @framework.deviceManager.on 'discover', () =>
        @_base.debug("Starting discovery")
        @framework.deviceManager.discoverMessage( 'pimatic-lg-smart-tv', "Searching for LG Smart TV" )

        scanner = new Scanner()
        @_mac = ''
        @_key = ''
        scanner.on('device', (device) =>
          ip = device.getOpt('address')
          arp.getMACAsync(ip).then( (mac) =>
            @saveTvToConfig(ip, mac)
            @_mac = mac
          
          ).then( () =>
            @createInputsDevice(device)
            
          ).then( (device) =>
            @createSmartTvDevice(device, @_mac)
          
          ).then( (device) =>
            @createAppsDevice(device)
          
          ).then( (device) =>
            @createChannelsDevice(device)
            
          ).catch( (error) =>
            env.logger.info(error)
            
          ).finally( () =>
            scanner.stop()
          )
          
        )
        scanner.start()
    
    saveTvToConfig: (ip, mac) =>
      found = false
      i = 0
      @config.smartTVs.map( (tv) =>
        if tv.id is ip
          found = true
          @config.smartTvs[i].mac = mac if tv.mac isnt mac
        i++
      )
      @config.smartTVs.push({id: ip, mac: mac}) if !found
    
    createChannelsDevice: (device) =>
      deviceConfig = {
          class: "LgSmartTvChannelsDevice"
          name: device.getOpt('friendlyName') + " Channels"
          id: 'lg-smart-tv-channels'
          tvIp: device.getOpt('address')
          buttons: []
      }
      
      device.getChannels().then( (channels) =>
        channels.map( (channel) =>
          #if channel.tv and channel.adult is 0 and !channel.scrambled
          button = {
            id: channel.name.toLowerCase().replace(/[\s\/%!&]/g,'-')
            text: channel.name
            webosId: channel.id
          }
          deviceConfig.buttons.push(button)
        )
        @framework.deviceManager.discoveredDevice('pimatic-lg-smart-tv-channels', "#{deviceConfig.name}", deviceConfig)
        Promise.resolve(device)
      
      ).catch( (error) =>
        Promise.reject(error)
      
      )

    createInputsDevice: (device) =>
      deviceConfig = {
        class: "LgSmartTvInputsDevice"
        name: device.getOpt('friendlyName') + " Inputs"
        id: 'lg-smart-tv-inputs'
        tvIp: device.getOpt('address')
        buttons: []
      }
      
      device.getInputs().then( (inputs) =>
        console.log inputs
        inputs.map( (input) =>
          button = {
            id: input.appId
            text: input.label
          }
          console.log(button.text)
          deviceConfig.buttons.push(button)
        )
        @framework.deviceManager.discoveredDevice('pimatic-lg-smart-tv-inputs', "#{deviceConfig.name}", deviceConfig)
        Promise.resolve(device)
      
      ).catch( (error) =>
        Promise.reject(error)
      
      )
    
    createAppsDevice: (device) =>
      return new Promise( (resolve, reject) =>
        deviceConfig = {
          class: "LgSmartTvAppsDevice"
          name: device.getOpt('friendlyName') + " Apps"
          id: 'lg-smart-tv-apps'
          tvIp: device.getOpt('address')
          buttons: []
        }
        
        device.getApps().then( (apps) =>
          apps.map( (app) =>
            button = {
              id: app.id
              text: app.title
            }
            deviceConfig.buttons.push(button)
          )
          @framework.deviceManager.discoveredDevice('pimatic-lg-smart-tv-apps', "#{deviceConfig.name}", deviceConfig)
          resolve(device)
        
        ).catch( (error) =>
          reject(error)
        
        )
      )
    
    createSmartTvDevice: (device, mac) =>
      deviceConfig = {
        class: "LgSmartTvDevice"
        name: device.getOpt('friendlyName')
        id: device.getOpt('id')
        tvIp: device.getOpt('address')
        tvMac: mac
        key: device.getOpt('key')
      }
      
      @framework.deviceManager.discoveredDevice('pimatic-lg-smart-tv', "#{deviceConfig.name}", deviceConfig)
      return Promise.resolve(device)
      
    turnOnTv: (mac) =>
      wol.wake(mac)
    
    getRemote: (ip, key = '') =>
      return new webos.WebOSDevice({
        key: key,
        address: ip,
        debug: false,
        timeout: 1000
      })
    
    _callbackHandler: (className, classType) ->
      # this closure is required to keep the className and classType
      # context as part of the iteration
      return (config, lastState) =>
        return new classType(config, @, lastState, @framework)

  # ###Finally
  # Create a instance of my plugin
  # and return it to the framework.
  return new LgSmartTvPlugin