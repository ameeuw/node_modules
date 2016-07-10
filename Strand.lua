-- Strand.lua module
-- Author: Arne Meeuw
-- github.com/ameeuw
--
--
-- Initialize:
-- Strand = require('Strand').new(length, pinC, pinD)
--
-- Methods:
-- Strand:setRgb(r,g,b)
-- Strand:setHsb(h,s,b)
-- Strand:cycle()
-- Strand:rainbowCycle()
-- Strand:stop()


local Strand = {}
Strand.__index = Strand

function Strand.new(length, pinC, pinD)
	-- TODO: add timer variable to change timer number
	local self = setmetatable({}, Strand)

	self.on = false
	self.color = {}
	self.color.r = 0
	self.color.g = 0
	self.color.b = 0
	self.color.h = 0
	self.color.s = 0
	self.color.v = 0
  self.timer = 2
  self.length = length

  self.lpd = require('LPD8806').new(length, pinC, pinD)
  self.lpd:show()

  return self
end


function Strand.setRgb(self, r, g, b)
  for i = 0, self.length-1 do
    self.lpd:setPixelColor(i, r, g, b)
  end
  self.lpd:show()
  self.color.r = r
  self.color.g = g
  self.color.b = b
end

function Strand.fade(self, r, g, b)
	local step = 0
	local steps = 35
	local stepDelay = 20
	local dr = (r - self.color.r)
	local dg = (g - self.color.g)
	local db = (b - self.color.b)

	tmr.alarm(self.timer, stepDelay, tmr.ALARM_AUTO,
		function()
			step = step + 1
			local cr = math.min(255, math.max(0, self.color.r + step * dr / steps))
			local cg = math.min(255, math.max(0, self.color.g + step * dg / steps))
			local cb = math.min(255, math.max(0, self.color.b + step * db / steps))

      for i = 0, self.length-1 do
        self.lpd:setPixelColor(i, cr/2, cg/2, cb/2)
      end
      self.lpd:show()

			if step > steps then
				self:stop()
				self:setRgb(cr/2, cg/2, cb/2)
			end
		end)
end


function Strand.setHsb(self, h, s, b)
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

	  r = math.min(127, math.max(0, r * 127 / 100))
		g = math.min(127, math.max(0, g * 127 / 100))
		b = math.min(127, math.max(0, b * 127 / 100))

		return r, g, b
	end

	self:fade(hsvToRgb(h,s,b))

end

function Strand.Wheel(self, WheelPos)
	local comp = WheelPos/128
	if comp==0 then
	  r = 127 - WheelPos % 128
	  g = WheelPos % 128
	  b = 0
	elseif comp==1 then
	  g = 127 - WheelPos % 128
	  b = WheelPos % 128
	  r = 0
	elseif comp==2 then
	  b = 127 - WheelPos % 128
	  r = WheelPos % 128
	  g = 0
	end
	return tonumber(r),tonumber(g),tonumber(b)
end

function Strand.rainbowCycle(self)
	local j=0
  local speed = 3
  local delay = 100
	tmr.alarm(self.timer,delay,1,
    function()
  		for i=0,self.length-1 do
  		  self.lpd:setPixelColor(i, self:Wheel( ((i * 384 / self.length) + j) % 384) )
  		end

  		self.lpd:show()

  		if j<383*5 then
  			j=j+speed
  		else
  			j=0
  		end
    end)
end

function Strand.cycle(self)
	local pos = 0
  local speed = 1
  local delay = 1000
	tmr.alarm(self.timer,delay,1,
    function()
  		self:setRgb(self:Wheel(pos))

  		if pos<384 then
  			pos=pos+speed
  		else
  			pos=0
  		end
    end)
end

function Strand.stop(self)
  tmr.stop(self.timer)
end

return Strand
