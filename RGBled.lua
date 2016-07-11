-- RGBled.lua module
-- Author: Arne Meeuw
-- github.com/ameeuw
--
-- Simplified API for PWM driven or WS2812 RGBled
-- Initialize:
-- RGBled = require('RGBled').new(mode, pins)
-- 		mode: "PWM" or "WS2812"w
--		pins: table of pins (use {})
-- Use:
-- RGBled:blink(times, delay, r, g, b)
--	times: how many times blink
--	delay: time between flashes in ms
--	r, g, b: Byte values of colors to blink
--
-- RGBled:setRgb(r, g, b)
-- RGBled:fade(r, g, b)
-- RGBled:blink(times, delay, r, g, b)
-- RGBled:breathe(times, r, g, b)

local RGBled = {}
RGBled.__index = RGBled

function RGBled.new(mode, pins, timer)
	local self = setmetatable({}, RGBled)

	self.color = {['on']=0, ['r']=0, ['g']=0, ['b']=0, ['h']=0, ['s']=0, ['v']=0}
	self.oldColor = {['on']=0, ['r']=0, ['g']=0, ['b']=0, ['h']=0, ['s']=0, ['v']=0}

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
		if pins[1] ~= nil then
			self.pins = {['ws']=pins[1]}
		else
			self.pins = {['ws']=pins}
		end
			self.mode = "WS2812"
	end

	if timer~=nil then
		self.timer = timer
	else
		self.timer = 0
	end

	return self
end

function RGBled.blink(self, times, delay, r, g, b)
	local lighton=0
	local count=0
	tmr.alarm(self.timer,delay,1,
		function()
			if lighton==0 then
				lighton=1
				self.setRgb(self, r, g, b)
			else
				lighton=0
				self.setRgb(self, 0, 0, 0)
			end
			if count==(times*2-1) then
				tmr.stop(self.timer)
			else
				count=count+1
			end
		end)
end

function RGBled.breathe(self, times, r, g, b)
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
            if dim > maxSteps then
                direction = -1
            end
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

function RGBled.fade(self, r, g, b)
	local step = 0
	local steps = 35
	local stepDelay = 20
	local dr = (r - self.oldColor.r)
	local dg = (g - self.oldColor.g)
	local db = (b - self.oldColor.b)

	tmr.alarm(self.timer,stepDelay,tmr.ALARM_AUTO,
		function()
			step = step + 1
			local cr = math.max(0, self.oldColor.r + step * dr / steps)
			local cg = math.max(0, self.oldColor.g + step * dg / steps)
			local cb = math.max(0, self.oldColor.b + step * db / steps)

			self.setRgb(self, cr, cg, cb)

			if step > steps then
				tmr.stop(self.timer)
				self.oldColor.r = r
				self.oldColor.g = g
				self.oldColor.b = b
				self.setRgb(self, r, g, b)
			end
		end)
end

function RGBled.setRgb(self, r, g, b)

	if self.mode == "PWM" then
		pwm.setduty(self.pins.r, r)
		pwm.setduty(self.pins.g, g)
		pwm.setduty(self.pins.b, b)
	end

	if self.mode == "WS2812" then
		ws2812.writergb(self.pins.ws, string.char(r,g,b))
	end

	self.color.r = r
	self.color.g = g
	self.color.b = b
end

function RGBled.setHsb(self, h, s, b)
	--[[ INTEGER VERSION!
	 * Converts an HSV color value to RGB. Conversion formula
	 * adapted from http://en.wikipedia.org/wiki/HSV_color_space.
	 * Assumes h e[0,360], s e[0, 100] and v e[0,100]
	 * returns r, g, and b in the set [0, 255].
	 *
	 * @param   Number  h       The hue
	 * @param   Number  s       The saturation
	 * @param   Number  v       The value
	 * @return  Array           The RGB representation
	]]
	local function hsvToRgb(h, s, v)
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

	  return r * 255 / 100, g * 255 / 100, b * 255 / 100
	end

	self:fade(hsvToRgb(h,s,b))

end

function RGBled.stop(self)
    tmr.stop(self.timer)
end

return RGBled
