--[[
Button.lua module
Author: Arne Meeuw
github.com/ameeuw

Simplified API for push button handling ESP8266 hardware

Initialize:
Button = require('Button').new(pin, pressCallback, longPressCallback)
pin : Pin push button is connected to
pressCallback :  function to call when button is pressed
longPressCallback : function to call when button is pressed long
--]]

local Button = {}
Button.__index = Button

function Button.new(pin, pressCallback, longPressCallback)
	-- TODO: add timer variable to change timer number
	local self = setmetatable({}, Button)

	self.pin = pin
	self.pressed = false
	self.lastPress = 0
	self.pressCallback = pressCallback
	self.longPressCallback = longPressCallback or pressCallback

	-- Set mode and trigger
	gpio.mode(self.pin, gpio.INT, gpio.PULLUP)
	gpio.trig(self.pin, 'both',
		function(level)
			self.debounce(self, self.onChange(self))
		end)

	return self
end

function Button.debounce (self, func)
    local last = 0
    local delay = 100000 -- 50ms * 1000 as tmr.now() has μs resolution

    return function (...)
        local now = tmr.now()
        local delta = now - last
        if delta < 0 then delta = delta + 2147483647 end; -- proposed because of delta rolling over, https://github.com/hackhitchin/esp8266-co-uk/issues/2
        if delta < delay then return end;

        last = now
        return func(...)
    end
end

function Button.onChange(self)
    --print('The pin value has changed to '..gpio.read(self.pin))
    if self.pressed == false then
      self.lastPress = tmr.now()
			self.pressed = true
      --print("lastPress:",self.lastPress)
    else
      if (tmr.now()-self.lastPress)<500000 then
        --print("Short press.")
				self.pressCallback()
      else
        --print("Long press.")
				self.longPressCallback()
      end
			self.pressed = false
    end
end

return Button
