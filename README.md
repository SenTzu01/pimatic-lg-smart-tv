# pimatic-lg-smart-tv

A pimatic plugin to control WebOS based LG Smart TV's. 
This plugin was developed against a LG OLED55B8PLA. Similar models should work equally well.
I do recommend connecting a Smart TV through cabled LAN for stability reasons - Which you already did for Netflix quality reasons anyway ;)

## Status of Implementation

Since the first release the following features have been implemented:
* Autodiscovery of LG WebOS capable televisions 
* Button devices for TV Channels, TV Inputs, and installed WebOS Apps, allowing to switch apps, inputs and channels rule-based
* Rule Action to show Toast messages on the television
* Turning TV on and off (Turning the TV on is accomplished through Wake-On-LAN)

Roadmap:
* Implement volume control (Not done initially since I use my AV Receiver for TV volume).

## Contributions / Credits
Originally this project was inspired by pimatic-lgtv (Vincent Riemer). However, the code base has deviated significantly since then.

## Configuration

* Add the plugin to your config.json, or via the GUI (Do not forget to activate)
* Create a device config, or run device autodiscovery (Recommended)

### Plugin Configuration
```json
{
  "plugin": "lg-smart-tv",
  "debug": false,
  "smartTVs": [
    {
      "id": "192.168.0.101",
      "mac": "a8:23:fe:66:dd:11"
    },
    {
      .......
    }
  ],
  "active": true
}
```

The plugin has the following configuration properties:

| Property          | Default  | Type    | Description                                     |
|:------------------|:---------|:--------|:------------------------------------------------|
| debug             | false    | Boolean | Debug messages to pimatic log, if set to true   |


### Device Configuration
Default settings through autodiscovery should work fine.

#### LgSmartTvDevice

```json
{
  "class": "LgSmartTvDevice",
  "name": "TV Livingroom",
  "id": "tv-livingroom",
  "tvIp": "192.168.0.101",
  "tvMac": "a8:23:fe:66:dd:11",
  "key": "401d6a314a8992695c0139c042084e4a"
}
```
The device has the following configuration properties:

| Property            | Default  | Type    | Description                                      |
|:--------------------|:---------|:--------|:-------------------------------------------------|
| tvIP                | ''       | String  | IPv4 address of TV (Populated by auto discovery  |
| tvMAC               | ''       | String  | MAC address of TV (Populated by auto discovery   |
| key             	  | ''       | String  | Unique key identifying Pimatic with the TV       |


#### LgSmartTvAppsDevice / LgSmartTvInputsDevice

```json
{
  "class": "LgSmartTvAppsDevice",
  "name": "TV Apps",
  "id": "lg-smart-tv-applications",
  "tvIp": "192.168.0.101",
  "buttons": [
    {
      "id": "netflix",
      "text": "Netflix"
    },
    {
	  .....
    }
  ]
}
```

| Property            | Default  | Type    | Description                                      |
|:--------------------|:---------|:--------|:-------------------------------------------------|
| buttons             | ''       | Array   | Array of Applications installed on TV            |
| id                  | ''       | String  | Internal WebOS app id                            |
| text             	  | ''       | String  | Friendly App name for Pimatic GUI                |

In WebOS Apps and Inputs are treated similarly, therefore you can opt to include your inputs in your Apps device!
**In case you want to have a separate buttons device for inputs, the syntax is equal, where the id refers to the input in that case.**
*E.g. "id": "com.webos.app.hdmi2", "name": "Input HDMI 2"

#### LgSmartTvChannelsDevice

```json
{
  "class": "LgSmartTvChannelsDevice",
  "name": "TV Channels",
  "id": "lg-smart-tv-channels",
  "tvIp": "192.168.0.101",
  "buttons": [
    {
      "id": "npo-1-hd",
      "text": "NPO 1 HD",
      "webosId": "3_36_1_501_114_14010_2249"
    },
    {
      ......
    }
  ]
}
```

| Buttons Property    | Default  | Type    | Description                                      |
|:--------------------|:---------|:--------|:-------------------------------------------------|
| id                  | ''       | String  | Pimatic button ID                                |
| webosId             | ''       | String  | Internal WebOS channel id                        |
| text             	  | ''       | String  | Friendly Channel name for Pimatic GUI            |




## Predicates and Actions

The following predicates are supported:
* {device} is turned on|off

The following actions are supported:
* switch {device} on|off
* show message "Look at the TV!" on TV Living Room
* press Discovery Channel HD (Discovery Channel HD being the friendly name for the TV Channel)
* Press Mediaplayer (Mediaplayer being the Pimatic friendly name for the corresponding TV Input)


## License 

Copyright (c) 2021, Danny Wigmans and contributors. All rights reserved.

[GPL-3.0](https://github.com/SenTzu01/pimatic-woox/blob/main/LICENSE)