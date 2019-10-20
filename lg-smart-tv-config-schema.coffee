# #pimatic-denon-avr plugin config options
module.exports = {
  title: "pimatic-lg-smart-tv plugin config options"
  type: "object"
  properties:
    debug:
      description: "Debug mode. Writes debug messages to the pimatic log, if set to true."
      type: "boolean"
      default: false
    smartTVs:
      description: "The LG Smart TVs on the network"
      type: "array"
      default: []
      format: "table"
      items:
        type: "object"
        properties:
          id:
            type: "string"
            description: "TV IP Address"
            required: true
          mac:
            type: "string"
            description: "TV MAC Address"
            required: true
}