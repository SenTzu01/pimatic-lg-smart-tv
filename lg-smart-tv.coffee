module.exports = (env) ->
  
  Promise = env.require 'bluebird'
  commons = require('pimatic-plugin-commons')(env)
  webos = Promise.promisifyAll(require('webos'))
  Remote = webos.Remote
  Scanner = webos.Scanner
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
        scanner.startScanning()
        
        scanner.on 'device', (device) =>
          
          mac = "00:00:00:00:00:00"
          newKey = null
          
          remote = @getRemote()
          remote.connectAsync({ address: device.address }).then( (key) =>
            newKey = key
            arp.getMACAsync( device.address)
            
          ).then( (address) =>
            mac = address
            @saveTvToConfig(device.address, mac)
            @createChannelsDevice(remote, device)
          
          ).then( () =>
            @createInputsDevice(remote, device)
          
          ).then( () =>
            @createAppsDevice(remote, device)
          
          ).then( () =>
            @createSmartTvDevice(device, mac, newKey)
            
          ).catch( (error) =>
            env.logger.info(error)
          ).finally( () =>
            remote.disconnectAsync()
            scanner.stopScanning()
          )
    
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
    
    createChannelsDevice: (remote, device) =>
      remote.getChannelsAsync().then( (channels) =>
        deviceConfig = {
          class: "LgSmartTvChannelsDevice"
          name: device.friendlyName
          id: 'lg-smart-tv-channels'
          tvIp: device.address
          buttons: []
        }
        
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
      )

    createInputsDevice: (remote, device) =>
      remote.getInputsAsync().then( (inputs) =>
        deviceConfig = {
          class: "LgSmartTvInputsDevice"
          name: device.friendlyName
          id: 'lg-smart-tv-inputs'
          tvIp: device.address
          buttons: []
        }
        
        inputs.map( (input) =>
          button = {
            id: input.id
            text: input.label
          }
          deviceConfig.buttons.push(button)
        )
        @framework.deviceManager.discoveredDevice('pimatic-lg-smart-tv-inputs', "#{deviceConfig.name}", deviceConfig)
      )
      
    createAppsDevice: (remote, device) =>
      remote.getAppsAsync().then( (apps) =>
        deviceConfig = {
          class: "LgSmartTvAppsDevice"
          name: device.friendlyName
          id: 'lg-smart-tv-apps'
          tvIp: device.address
          buttons: []
        }
        
        apps.map( (app) =>
          button = {
            id: app.id
            text: app.title
          }
          deviceConfig.buttons.push(button)
        )
        @framework.deviceManager.discoveredDevice('pimatic-lg-smart-tv-apps', "#{deviceConfig.name}", deviceConfig)
      )
    
    createSmartTvDevice: (device, macAddress, key) =>
      deviceConfig = {
        class: "LgSmartTvDevice"
        name: device.friendlyName
        id: "lg-smart-tv"
        tvIp: device.address
        tvMac: macAddress
        key: key
      }
      @framework.deviceManager.discoveredDevice('pimatic-lg-smart-tv', "#{deviceConfig.name}", deviceConfig)
    
    turnOnTv: (mac) =>
      wol.wake(mac)
    
    getRemote: () =>
      return new Remote({
        debug: false, 
        reconnect: false, 
        connectTimeout: false
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