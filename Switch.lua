--[[
Switch.lua module
Author: Arne Meeuw
github.com/ameeuw

Simplified API for push button handling ESP8266 hardware

Initialize:
Switch = require('Switch').new(pin, pressCallback, longPressCallback)
pin : Pin push button is connected to
pressCallback :  function to call when button is pressed
longPressCallback : function to call when button is pressed long
--]]

local Switch = {}
Switch.__index = Switch

function Switch.new(pin, callback)
	-- TODO: add timer variable to change timer number
	local self = setmetatable({}, Switch)

	self.pin = pin
	self.callback = callback

	-- Set state, mode and trigger
	gpio.mode(self.pin, gpio.INPUT)
	self.state = gpio.read(self.pin)

	gpio.mode(self.pin, gpio.INT, gpio.PULLUP)
	gpio.trig(self.pin, 'both',
		function(level)
			self:debounce(self:onChange())
		end)

	return self
end

function Switch:debounce (func)
    local last = 0
    local delay = 100000 -- 50ms * 1000 as tmr.now() has μs resolution

    return function (...)
        local now = tmr.now()
        local delta = now - last
        --if delta < 0 then delta = delta + 2147483647 end; -- proposed because of delta rolling over, https://github.com/hackhitchin/esp8266-co-uk/issues/2
        if delta < delay then return end;

        last = now
        return func(...)
    end
end

function Switch:onChange()
    --print('The pin value has changed to '..gpio.read(self.pin))
    if self.state == false then
			self.state = true
			self:callback(true)
    else
			self:callback(false)
			self.state = false
    end
end

return Switch
