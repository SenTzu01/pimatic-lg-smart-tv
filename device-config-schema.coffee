module.exports = {
  title: "pimatic-lg-smart-tv Device config schemas"
  LgSmartTvDevice: {
    title: "LG Smart TV Device"
    description: "LG Smart TV Device configuration"
    type: "object"
    extensions: ["xLink", "xOnLabel", "xOffLabel"]
    properties:
      tvIp:
        description: "IP Address of the LG Smart TV"
        type: "string"
      tvMac:
        description: "MAC Address of the LG Smart TV"
        type: "string"
      key:
        description: "Unique key identifying your pimatic instance to the LG Smart TV"
        type: "string"
  },
  LgSmartTvChannelsDevice: {
    title: "LG Smart TV Channels Device"
    description: "LG Smart TV Channels Device configuration"
    type: "object"
    extensions: ["xLink", "xOnLabel", "xOffLabel"]
    properties:
      tvIp:
        description: "IP Address of the LG Smart TV"
        type: "string"
      enableActiveButton:
        description: "Highlight last pressed button if enabled"
        type: "boolean"
        default: true
      buttons:
        description: "The channels to select from"
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            id:
              type: "string"
              description: "The button ID"
              required: true
            text:
              type: "string"
              description: "Channel friendly name."
              required: true
            webosId:
              type: "string"
              description: "The channel ID retrieved from the LG Smart TV"
              required: true
  },
  LgSmartTvInputsDevice: {
    title: "LG Smart TV Inputs Device"
    description: "LG Smart TV Inputs Device configuration"
    type: "object"
    extensions: ["xLink", "xOnLabel", "xOffLabel"]
    properties:
      tvIp:
        description: "IP Address of the LG Smart TV"
        type: "string"
      enableActiveButton:
        description: "Highlight last pressed button if enabled"
        type: "boolean"
        default: true
      buttons:
        description: "The inputs to select from"
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            id:
              type: "string"
              description: "The input ID"
              required: true
            text:
              type: "string"
              description: "Input friendly name"
              required: true
  },
  LgSmartTvAppsDevice: {
    title: "LG Smart TV Apps Device"
    description: "LG Smart TV Apps Device configuration"
    type: "object"
    extensions: ["xLink", "xOnLabel", "xOffLabel"]
    properties:
      tvIp:
        description: "IP Address of the LG Smart TV"
        type: "string"
      enableActiveButton:
        description: "Highlight last pressed button if enabled"
        type: "boolean"
        default: true
      buttons:
        description: "The applications to select from"
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            id:
              type: "string"
              description: "The application ID"
              required: true
            text:
              type: "string"
              description: "Application friendly name"
              required: true
  }
}