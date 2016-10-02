# ESPupdater

This library enables automatic update of LUA files over Wi-Fi and a web server.

## Scenario

I had many devices based on ESP8266 spread around my house and I was tired of uninstalling them from their places any time I needed to apply a sofware update or just a config change, such as a modification of timing, addresses, etc.  
Some of them are even installed in remote places that would require me to drive for several miles to reach them. That was really unconvenient and time consuming.  
I wanted it to be fully automatic, similar to a smartphone app that gets updated by itself when an update is available.  
In addition, since all my devices are running on battery, the update process must have very low impact on battery life.

## Design specs and principle of operation

Many ESP8266 devices are running on batteries and use the deep-sleep feature to wake-up every N minutes. There is little point in checking for 
updates every single time the device wakes up. This also shortens battery life.  
For this reason the update check is attempted every N wake-up cycles by using a rtcmem registry that survives a reboot.  
This registry is decreased by 1 every time the device wakes up, when it reaches 0 the update check is fired.  
  
When new or updated files are found on the web server, the ESP module uploads them on its flash memory and then starts the actual application.

![Web server path](https://raw.githubusercontent.com/glcos/ESPupdater/master/images/webserver1.png)

![Web server path](https://raw.githubusercontent.com/glcos/ESPupdater/master/images/webserver2.png)

The new/updated content is detected by MD5 checksum comparison on both sides. This method is very fast and requires little bandwidth.
The web server can run on a very low spec hardware such as a Raspberry PI or even a router running OpenWrt like in my setup.
Even if the web server could also be on the internet, it is recommended to keep it on the same network as the ESP8266 devices in order to minimise
the time needed to download the updates and thus save the device battery.

![Large file upload](https://raw.githubusercontent.com/glcos/ESPupdater/master/images/largeupload1.png)

![Large file upload](https://raw.githubusercontent.com/glcos/ESPupdater/master/images/largeupload2.png)

The updater library is capable of update any type of file, not just LUA scripts. It syncs any file placed in the web server "appfiles" folder
to the ESP8266 flash memory including config files, images, sound files, etc.
It can also overwrite and update itself, if needed.
Thanks to the great httpDL library writen by Tobias Mädel, it can also download large files.
I tested a 900 KB JPG file download and it worked just fine.


## TO DO list

* Delete files on ESP8266 side. At this time the update library only uploads new and updates files.
* Provide feedback about the update, using MQTT messages on a dedicated topic, or HTTP posts against the web server.
* Implement a more robust update strategy capable of handling file transfer failures and file corruption that could lead to a dead device, no longer able to attempt new updates.

