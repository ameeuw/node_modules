-- Esp.lua module
-- Author: Arne Meeuw
-- github.com/ameeuw
--
-- Skeleton for creating a Esp
-- This skript is launched after boot of ESP8266 and loads the Wifi configuration (expected in wifi.lua).
-- If this fails, enduser_setup is launched and the settings are saved.
-- After an IP is acquired, begin() is triggered.
--
-- Initialize:
-- Esp = require('Esp').new(begin, rgbled, button)
--
-- begin: callback function on ready
-- rgbled: create rgbled
-- button: create button

local Esp = {}
Esp.__index = Esp

function Esp.new(begin, rgbled, button)

	local self = setmetatable({}, Esp)

	self.begin = begin

	if name == nil then
		name = 'Esp:'..string.sub(wifi.sta.getmac(),13,-1)
	end

	-- Initialize global PWM RGBled on pins 8,6,7 (floodlight on 6,5,7)
	if rgbled~=nil then
		if ( file.exists("RGBled.lua") or file.exists("RGBled.lc") ) then
			RGBled = require("RGBled").new("PWM",{8,6,7})
		end
	end

	-- Initialize global Button on pin 2
	if button~=nil then
		if ( file.exists("Button.lua") or file.exists("Button.lc") ) then
			Button = require("Button").new(2, function() print("Short press.") end, nil)
		end
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
function Esp.checkIP(self)
		if RGBled ~= nil then
    	RGBled:breathe(-1,100,138,11)
		end
    tmr.alarm(4,2000, 1,
      function()
        if wifi.sta.getip()==nil then
            print("Waiting for IP address...")
        else
            print("Obtained IP: "..wifi.sta.getip())
						if RGBled ~= nil then
            	RGBled:breathe(3,150,52,141,0)
						end
            self:begin()
            tmr.stop(4)
        end
      end)
end

function Esp.start(self)	-- Try to open wifi.lua and start enduser_setup if it fails
	if file.exists('wifi.lua') then
	    dofile('wifi.lua')
	    self:checkIP()
	else
	    if enduser_setup~=nil then
					if RGBled ~= nil then
	        	RGBled:breathe(-1,0,255,11)
					end
					if name == nil then
		        name = 'Sonoff:'..string.sub(wifi.sta.getmac(),13,-1)
					end
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
