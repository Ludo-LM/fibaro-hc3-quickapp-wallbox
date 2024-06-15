# Fibaro HC3 Quick App for Wallbox

An integration to Wallbox EV Charger https://wallbox.com/ for HC3.

You need to install this Quick App for each charger you want to manage.

This Quick App works as a binary switch, it allows you to:
- Lock and unlock the EV charger with the main switch.
- See the EV charger status
- Refresh the charger status (if you don't want to wait for the next auto refresh)
- Use the EV charger status as a global variable in scenes
- Manage the power limit
- Pause charging if EV charger is in "charging" status
- Start charging if EV charger is in "scheduled" or "paused" status
- Reschedule the EV charger for the next session if it is in "paused" status
- View instantaneous power consumption
- View total power usage for the current charge
- Collect energy usage in energy panel

Charger status is updated every minute or on demand through the refresh button.

This Quick App only works with a registered account at wallbox.com with your own email address.
If you are using a Google SSO (Single-Sign-on), you need to create a second account with Administrator privilege to control EV charger !

Reminder : Locking the charger after plugging in a vehicle has no effect on the current charge.

## Configuration

`username` - email used to connect on https://my.wallbox.com/

`password` - password used to connect on https://my.wallbox.com/

`chargerId` - the charger id (ie serial number). This id visible in the name of the charger if you haven't changed it before (ex. for "Copper Business SN 12345", chargerId is `12345`). You can also find id on https://my.wallbox.com/

## Installation

Add a new device in Fibaro HC3 interface, choose upload a file next to "Quick App" and upload `dist/wallbox.fqa` file.
Configure variable `username`, `password` and `chargerId`.

To report energy usage in energy panel, go on Advanced tab and enable switch to calculate energy used
(Advanced > Configuration of power and energy reports > Calculate energy used)

Choose icons for your device. Some icons are provided in `icons/` directory.

Go to the device on you computer or on your Fibaro mobile app and verify EV charger status.
If username or password are invalid or charger id is unknown, you will have an error message.

## Operation

The Quick App will first get a Token at startup using username and password and will use it until its expiration date.
The token will be renewed when necessary (token is valid for 15 days).

Once authenticated, the Quick App will use the EV charger id (ie. serial number) to get its status and control it.

Each time the charger status is updated, a global variable "Wallbox_`chargerId`" is updated

## Internationalization

This Quick App contains translations for `en` and `fr` languages, you can easily add translations for other languages by modifying the `i18n` file of the Quick App.

Please share your translations and create a PR on Github !

## Release Notes
- v1.1 - 15/06/2024\
Report energy usage in energy panel.
- v1.0 - 31/05/2024\
Initial version.

## Source code

Original source code is on Github https://github.com/Ludo-LM/fibaro-hc3-quickapp-wallbox

## Support
To report an issue, please create it on Github https://github.com/Ludo-LM/fibaro-hc3-quickapp-wallbox/issues

## Credits
- Wallbox API specification - Stephan Kreyenborg https://github.com/SKB-CGN/wallbox
- Jwt library - Inaiat Henrique https://gist.github.com/inaiat/02bf5d11732d8e4d7b7546399a3a49af
- Peugeot Lock/Unlock icons - fredokl from https://www.domotique-fibaro.fr/ forum
