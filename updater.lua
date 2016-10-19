-- ESP8266 updater library
-- Gianluigi Cosari gianluigi@cosari.it
-- Ver 1.1 October 2016
-- Tested with NodeMCU 1.5.4.1
-- Licensed under MIT

local APPLICATION_NAME = "test" -- matches the folder name on web server
local APPLICATION_FILE = "application.lua" -- actual application startup file to be executed upon update check
local WEB_SERVER_HOST  = "192.168.71.1" -- web server hosting updated files
local WEB_SERVER_PATH  = "/ESPupdater/" -- including trailing slash
local SLEEP_CYCLES = 2 -- number of sleep-wakeup cycles to go through before checking for updates
local RTCMEM_INDEX = 127 -- choose a memory location not used by your application
local EMERGENCY_TIMER = 5 -- seconds, a reboot will be forced when emergency timer expires

-- No need to edit anything beyond this line

local flESP = nil -- ESP file list
local tdiff = nil -- List of files being updated
local wsfp = "http://"..WEB_SERVER_HOST..WEB_SERVER_PATH
local ff = nil
local ndx = 1

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function execapp()
	tmr.softwd(-1)
	flESP = nil
	tdiff = nil
	wsfp = nil
	collectgarbage()
	dofile(APPLICATION_FILE)
end

local function flist()
	fl = {}
	l = file.list();
	for f,_ in pairs(l) do
		fl[f] = crypto.toHex(crypto.fhash("md5",f))
	end
	return fl
end

local function buildMD5()
	flESP = flist()
	list = {}
	for name,value in pairs(flESP) do
	  list[#list+1] = name
	end
	hs = ""
	table.sort(list)
	for k=1,#list do
		c = list[k]
		v = flESP[list[k]]
		hs = hs..c..v
	end
	h = crypto.toHex(crypto.hash("md5",hs))
	return h
end

function download(filename)
	httpDL.download(WEB_SERVER_HOST, 80, WEB_SERVER_PATH.."appfiles/"..APPLICATION_NAME.."/"..filename, filename, function (payload)
		tmr.softwd(EMERGENCY_TIMER)
		-- Finished downloading
		print(filename.." "..payload.." downloaded to ESP")
		ndx = ndx + 1
		tmr.start(6)
	end)
end

tmr.register(6, 10, tmr.ALARM_SEMI, function()
	if ndx > #ff then
		print("Update done !")
		tmr.unregister(6)
		httpDL = nil
		package.loaded["httpDL"] = nil
		ff = nil
		collectgarbage()
		node.task.post(node.task.LOW_PRIORITY, execapp)
	else
		download(ff[ndx])
	end
end)

local function dlFiles()
	print("Start downloading files...")
	httpDL = require("httpDL")
	collectgarbage()
	ff = {}
	for k,v in pairs(tdiff) do
		ff[#ff+1] = k
	end
	tmr.start(6)
end

local function dlJson()
	flESP = flist() -- Rebuilding local file list
	http.get(wsfp..APPLICATION_NAME..".json", nil, function(code, data)
		tmr.softwd(EMERGENCY_TIMER)
		if code == 200 then
			t = cjson.decode(data)
			tdiff = {}
			for k,v in pairs(t) do
				if (flESP[k] ~= v) then
					tdiff[k] = v
				end
			end
			node.task.post(dlFiles)
		else
			print("HTTP request failed "..code)
		end
	end)
end

local function updater()
	md = buildMD5()
	print("local_md5_hash= "..md)
	http.get(wsfp.."md5.php?a="..APPLICATION_NAME, nil, function(code, data)
		tmr.softwd(EMERGENCY_TIMER)
		d = trim(data)
		print("server md5= "..d)
		if code == 200 then
			if d == md then
				print("No updates, executing application")
				node.task.post(node.task.LOW_PRIORITY, execapp)
			else
				print("Update available")
				node.task.post(dlJson)
			end
		else
			print("HTTP request failed "..code)
		end
	end)
end

slcy = rtcmem.read32(RTCMEM_INDEX)
print("RTCMEM = " .. slcy)

if slcy == 0 or slcy > SLEEP_CYCLES then
	rtcmem.write32(RTCMEM_INDEX, SLEEP_CYCLES)
	tmr.softwd(EMERGENCY_TIMER)
	tmr.alarm(5, 200, tmr.ALARM_AUTO, function()
		if wifi.sta.status() == 5 then
			tmr.unregister(5)
			print("WiFi connected, executing update check")
			u = updater()
		else
			print("WiFi connecting...")
		end
	end)
else
	slcy = slcy - 1
	rtcmem.write32(RTCMEM_INDEX, slcy)
	node.task.post(node.task.LOW_PRIORITY, execapp)
end
