-- ESP8266 generic config file
-- Gianluigi Cosari gianluigi@cosari.it
-- Ver 1.3 December 2016
-- Tested with NodeMCU 1.5.4.1
-- Licensed under MIT

local module = {}

-- ESP UPDATER
module.APPLICATION_NAME = "application" -- matches the folder name on web server
module.APPLICATION_FILE = "application.lua" -- actual application startup file to be executed upon update check
module.WEB_SERVER_HOST  = "192.168.71.1" -- web server hosting updated files
module.WEB_SERVER_PATH  = "/ESPupdater/" -- including trailing slash
module.SLEEP_CYCLES = 2 -- number of sleep-wakeup cycles to go through before checking for updates
module.RTCMEM_INDEX = 127 -- choose a memory location not used by your application
module.EMERGENCY_TIMER = 5 -- seconds, a reboot will be forced when emergency timer expires
module.WAIT_FOR_WIFI = true -- always waits until wifi is connected even though an update is not required

return module
