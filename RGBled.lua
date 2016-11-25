--[[
RgbLed.lua module
Author: Arne Meeuw
github.com/ameeuw

Simplified API for PWM driven or WS2812 RgbLed
Initialize:
RgbLed = require('RgbLed').new(mode, pins)
		mode: "PWM" or "WS2812"w
		pins: table of pins (use {})
Use:
RgbLed:blink(times, delay, r, g, b)
	times: how many times blink
	delay: time between flashes in ms
	r, g, b: Byte values of colors to blink

RgbLed:setRgb(r, g, b)
RgbLed:fade(r, g, b)
RgbLed:blink(times, delay, r, g, b)
RgbLed:breathe(times, r, g, b)
--]]

local RgbLed = {}
RgbLed.__index = RgbLed

function RgbLed.new(mode, pins, timer)
	local self = setmetatable({}, RgbLed)

	self.color = {['on']=0, ['r']=0, ['g']=0, ['b']=0, ['h']=0, ['s']=0, ['v']=0}
	self.oldColor = {['on']=0, ['r']=0, ['g']=0, ['b']=0, ['h']=0, ['s']=0, ['v']=0}

	self.timer = timer or 0

	if mode == "PWM" then
		-- RGB LED pins:
		self.pins = {['r']=pins[1], ['g']=pins[2], ['b']=pins[3]}
		self.mode = "PWM"
		-- Set PWM modes
		for k,pin in pairs(self.pins) do
			pwm.setup(pin,300,0)
			pwm.start(pin)
			pwm.setduty(pin,0)
		end
	end

	if mode == "WS2812" then
		-- RGB LED pin:
		self.pins = {['ws']=pins[1]} or {['ws']=pins}
		self.mode = "WS2812"
	end

	return self
end

function RgbLed:blink(times, delay, r, g, b)
	local on=false
	local count=0
	tmr.alarm(self.timer,delay,1,
		function()
			on = not on
			self:setRgb( (on and 1 or 0)*r, (on and 1 or 0)*g, (on and 1 or 0)*b )
			if count==(times*2-1) then
				tmr.stop(self.timer)
			else
				count=count+1
			end
		end)
end

function RgbLed:breathe(times, r, g, b)
    local dim = 5
    local direction = 1
    local count = 0
    local stepDelay = 20
    local maxSteps = 100
    local minSteps = 5
    tmr.alarm(self.timer,stepDelay,1,
        function()
            local tR = r * dim / maxSteps
            local tG = g * dim / maxSteps
            local tB = b * dim / maxSteps
            self:setRgb(tR, tG, tB)
            dim = dim + direction
            if dim > maxSteps then direction = -1 end
            if dim < minSteps then
                direction = 1
                count = count + 1
            end
            if count == times then
                tmr.stop(self.timer)
                self:setRgb(0,0,0)
            end
        end)
end

function RgbLed:fade(r, g, b)
	local step = 0
	local steps = 35
	local stepDelay = 20
	tmr.alarm(self.timer,stepDelay,tmr.ALARM_AUTO,
		function()
			step = step + 1
			-- linear function 'start + x * dc / c'
			local cr = math.max(0, self.oldColor.r + step * (r - self.oldColor.r) / steps)
			local cg = math.max(0, self.oldColor.g + step * (g - self.oldColor.g) / steps)
			local cb = math.max(0, self.oldColor.b + step * (b - self.oldColor.b) / steps)
			self.setRgb(self, cr, cg, cb)
			if step > steps then
				tmr.stop(self.timer)
				self.oldColor.r, self.oldColor.g, self.oldColor.b = r, g, b
				self:setRgb(r, g, b)
			end
		end)
end

function RgbLed:setRgb(r, g, b)
	r, g, b = self:correctGamma(r, g, b)
	if self.mode == "PWM" then
		pwm.setduty(self.pins.r, r)
		pwm.setduty(self.pins.g, g)
		pwm.setduty(self.pins.b, b)
	end
	if self.mode == "WS2812" then
		ws2812.writergb(self.pins.ws, string.char(r,g,b))
	end
	self.color.r, self.color.g, self.color.b = r, g, b
end

function RgbLed:correctGamma(r, g, b)
	return math.sqrt(10000*r)*1000/6257, math.sqrt(10000*g)*1000/6257, math.sqrt(10000*b)*1000/6257
end

function RgbLed:setHsb(h, s, v)
	local h = h or self.color.h
	local s = s or self.color.s
	local v = v or self.color.v

  local r, g, b
  h = h * 5 / 18
  local i = math.floor(h * 6) - (math.floor(h * 6) % 100);
  local f = h * 6 - i;
  local p = (v * (100 - s)) / 100;
  local q = v * (10000 - f * s) / 10000;
  local t = v * (10000 - (100 - f) * s) / 10000;
  i = i % 600

  if i == 0 then r, g, b = v, t, p
  elseif i == 100 then r, g, b = q, v, p
  elseif i == 200 then r, g, b = p, v, t
  elseif i == 300 then r, g, b = p, q, v
  elseif i == 400 then r, g, b = t, p, v
  elseif i == 500 then r, g, b = v, p, q
  end
	self:fade(r * 255 / 100, g * 255 / 100, b * 255 / 100)
end

function RgbLed:stop()
    tmr.stop(self.timer)
end

return RgbLed
