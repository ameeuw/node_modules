--[[
Esp.lua module
Author: Arne Meeuw
github.com/ameeuw

Skeleton for creating an Esp
This skript is launched after boot of ESP8266 and loads the Wifi configuration (expected in wifi.lua).
If this fails, enduser_setup is launched and the settings are saved.
After an IP is acquired, begin() is triggered.

Initialize:
Esp = require('Esp').new(begin, rgbled, button)

begin: callback function on ready
rgbled: create rgbled
button: create button
--]]

local Esp = {}
Esp.__index = Esp

function Esp.new(begin, rgbled, button)
	local self = setmetatable({}, Esp)

	name = name or 'Esp:'..string.sub(wifi.sta.getmac(),13,-1)
	wifi.sta.sethostname(string.gsub(name,':','-'))
	self.timer = timer or 4
	self.begin = begin

	-- Initialize global PWM RgbLed on pins 8,6,7 (floodlight on 6,5,7)
	if RgbLed==nil and ( ( file.exists("RgbLed.lua") or file.exists("RgbLed.lc") ) ) then
		RgbLed = require("RgbLed").new("PWM",{8,6,7})
	end

	-- Initialize global Button on pin 2
	if Button==nil and ( ( file.exists("Button.lua") or file.exists("Button.lc") ) ) then
		Button = require("Button").new(2, function() print("Short press.") end, nil)
	end

	self:start()
	return self
end

-- IP acquired, begin()
function Esp.begin(self)
	print(name.." is starting.")
	self.begin()
end

-- Check for IP status
function Esp:checkIP()
	if RgbLed ~= nil then
  	RgbLed:breathe(-1,100,138,11)
	end
  tmr.alarm(self.timer,5000, 1,
    function()
      if wifi.sta.getip()==nil then
          print("Waiting for IP address...")
      else
				tmr.stop(self.timer)
        print("Obtained IP: "..wifi.sta.getip())
				net.dns.setdnsserver('8.8.4.4', 0)
				net.dns.setdnsserver('208.67.222.222', 1)
				if RgbLed ~= nil then
        	RgbLed:breathe(3,150,52,141,0)
				end
        self:begin()
      end
    end)
end

function Esp:start()	-- Try to open wifi.lua and start enduser_setup if it fails
	if file.exists('wifi.lua') then
    dofile('wifi.lua')
    self:checkIP()
	else
    if enduser_setup~=nil then
			if RgbLed ~= nil then
      	RgbLed:breathe(-1,0,255,11)
			end
      name = name or 'Sonoff:'..string.sub(wifi.sta.getmac(),13,-1)
      wifi.setmode(wifi.STATIONAP)
      wifi.ap.config({ssid=name, auth=wifi.AUTH_OPEN})
      enduser_setup.manual(true)
      print('Starting end user setup..')
      enduser_setup.start(
        function()
            print("Connected to wifi as:" .. wifi.sta.getip())

						-- Write wifi station config to wifi.lua
						local function writeSettings()
					    local ssid, password, _, _ = wifi.sta.getconfig()
					    file.remove("wifi.lua")
					    file.open("wifi.lua", "a+")
					    file.writeline('wifi.setmode(wifi.STATION)')
					    file.writeline('wifi.sta.config("'..ssid..'","'..password..'")')
							file.writeline('wifi.sta.autoconnect(1)')
					    file.close()
						end

						writeSettings()
            self:checkIP()
        end,

        function(err, str)
					print("enduser_setup: Err #" .. err .. ": " .. str)
				end)
    end
	end
end

return Esp
