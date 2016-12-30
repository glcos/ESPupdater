-- ESP8266 updater library
-- Gianluigi Cosari gianluigi@cosari.it
-- Ver 1.3 December 2016
-- Tested with NodeMCU 1.5.4.1
-- Licensed under MIT

updater_cfg = require("config")

local flESP = nil -- ESP file list
local tdiff = nil -- List of files being updated
local wsfp = "http://"..updater_cfg.WEB_SERVER_HOST..updater_cfg.WEB_SERVER_PATH
local ff = nil
local ndx = 1
updFB = {ver = "1.3", ds = 0, nf = 0, st = 0} -- Provides feedback about update process to actual application

local function resetEmTmr()
	if tmr.state(updet) ~= nil then
		updet:stop()
		updet:start()
	end
end

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function execapp()
	if updet ~= nil and tmr.state(updet) ~= nil then
		updet:stop()
		updet:unregister()
	end
	if uptmr ~= nil and tmr.state(uptmr) ~= nil then
		uptmr:stop()
		uptmr:unregister()
	end
	wifi.eventmon.unregister(wifi.eventmon.STA_GOT_IP)
	updet = nil
	uptmr = nil
	flESP = nil
	tdiff = nil
	wsfp = nil
	collectgarbage()
	dofile(updater_cfg.APPLICATION_FILE)
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

local function download(filename)
	httpDL.download(updater_cfg.WEB_SERVER_HOST, 80, updater_cfg.WEB_SERVER_PATH.."appfiles/"..updater_cfg.APPLICATION_NAME.."/"..filename, filename, function (payload)
		resetEmTmr()
		-- Finished downloading
		print(filename.." "..payload.." downloaded to ESP")
		ndx = ndx + 1
		updtmr:start()
	end)
end

local function dlFiles()
	print("Start downloading files...")
	httpDL = require("httpDL")
	collectgarbage()
	ff = {}
	for k,v in pairs(tdiff) do
		ff[#ff+1] = k
	end
	updFB.nf = #ff
	updtmr:start()
end

local function dlJson()
	flESP = flist() -- Rebuilding local file list
	resetEmTmr()
	http.get(wsfp..updater_cfg.APPLICATION_NAME..".json", nil, function(code, data)
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
	print("Running updater")
	updtmr = tmr.create()
	updtmr:register(10, tmr.ALARM_SEMI, function()
		if ndx > #ff then
			print("Update done !")
			updtmr:unregister()
			httpDL = nil
			package.loaded["httpDL"] = nil
			ff = nil
			collectgarbage()
			updFB.st = 3
			node.task.post(node.task.LOW_PRIORITY, execapp)
		else
			download(ff[ndx])
		end
	end)
	md = buildMD5()
	print("local_md5_hash= "..md)
	resetEmTmr()
	http.get(wsfp.."md5.php?a="..updater_cfg.APPLICATION_NAME, nil, function(code, data)
		if code == 200 then
			d = trim(data)
			print("server md5= "..d)
			-- check if MD5 value is valid or errors occurred at server side
			if string.sub(d, 1, 7) == "*error*" then
				updFB.st = 0
				execapp()
			else
				if d == md then
					print("No updates, executing application")
					updFB.st = 2
					node.task.post(node.task.LOW_PRIORITY, execapp)
				else
					print("Update available")
					node.task.post(dlJson)
				end
			end
		else
			print("HTTP request failed "..code)
		end
	end)
end

print("ESPUpdater start")
-- Setting emergency timer
updet = tmr.create()
updet:register(updater_cfg.EMERGENCY_TIMER * 1000, tmr.ALARM_SINGLE, function()
	updet:unregister()
	print("ESPUpdater emergency timer, starting application...")
	execapp()
end)
updet:start()

slcy = rtcmem.read32(updater_cfg.RTCMEM_INDEX)
updFB.ds = slcy
print("RTCMEM = " .. slcy)

local function connectwifi(F)
	if wifi.sta.status() == wifi.STA_GOTIP then
		print("WiFi connected")
		F()
	else
		print("WiFi connecting...")
		wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
			wifi.eventmon.unregister(wifi.eventmon.STA_GOT_IP)
			print("WiFi connected")
			F()
		end)
	end
end

local function ckupdate()
	if slcy <= 0 or slcy > updater_cfg.SLEEP_CYCLES then
		rtcmem.write32(updater_cfg.RTCMEM_INDEX, updater_cfg.SLEEP_CYCLES)
		--updater()
		connectwifi(updater)
	else
		slcy = slcy - 1
		rtcmem.write32(updater_cfg.RTCMEM_INDEX, slcy)
		updFB.st = 1
		node.task.post(node.task.LOW_PRIORITY, execapp)
	end
end

if updater_cfg.WAIT_FOR_WIFI == true then
	connectwifi(ckupdate)
else
	ckupdate()
end

