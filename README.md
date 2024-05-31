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

Charger status is updated every minute or on demand through the refresh button.

This Quick App only works with a registered account at wallbox.com with your own email address.
If you are using a Google SSO (Single-Sign-on), you need to create a second account with Administrator privilege to control EV charger !

## Configuration

`username` - email used to connect on https://my.wallbox.com/

`password` - password used to connect on https://my.wallbox.com/

`chargerId` - the charger id (ie serial number). This id visible in the name of the charger if you haven't changed it before (ex. for "Copper Business SN 12345", chargerId is `12345`). You can also find id on https://my.wallbox.com/

## Installation

Add a new device in Fibaro HC3 interface, choose upload a file next to "Quick App" and upload `dist/wallbox.fqa` file.
Configure variable `username`, `password` and `chargerId`.

Choose icons for your device. Some icons are provided in `icons/` directory.

Go to the device on you computer or on your mobile app and verify EV charger status.
If username or password are invalid or charger id is unknown, you will have an error message.

## Operation

The Quick App will first get a Token at startup using username and password and will use it until its expiration date.
The token will be renewed when necessary (token is valid for 15 days).

Once authenticated, the Quick App will use the EV charger id (ie. serial number) to get its status and control it.

Each time the charger status is updated, a global variable "Wallbox_`chargerId`" is updated

## Internationalization

This Quick App contains translations for `en` and `fr` languages, you can easily add translations for other languages by modifying the `main` file of the Quick App.

Please share your translations and create a PR on Github !

## Source code

Original source code is on Github https://github.com/Ludo-LM/fibaro-hc3-quickapp-wallbox

## Support
To report an issue,  please create it on Github https://github.com/Ludo-LM/fibaro-hc3-quickapp-wallbox/issues
