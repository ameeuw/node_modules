--[[
Strand.lua module
Author: Arne Meeuw
github.com/ameeuw


Initialize:
Strand = require('Strand').new(length, pinC, pinD)

Methods:
Strand:setRgb(r,g,b)
Strand:setHsb(h,s,b)
Strand:cycle()
Strand:rainbowCycle()
Strand:stop()
--]]

local Strand = {}
Strand.__index = Strand

function Strand.new(length, pinC, pinD)
	-- TODO: add timer variable to change timer number
	local self = setmetatable({}, Strand)

	self.color = {['on']=false, ['r']=0, ['g']=0, ['b']=0, ['h']=0, ['s']=0, ['v']=0}
  self.timer = timer or 2
  self.length = length

  self.lpd = require('LPD8806').new(length, pinC, pinD)
  self.lpd:show()

  return self
end


function Strand:setRgb(r, g, b)
  for i = 0, self.length-1 do
    self.lpd:setPixelColor(i, r, g, b)
  end
  self.lpd:show()
  self.color = {['r']=r, ['g']=g, ['b']=b}
end

function Strand:fade(r, g, b)
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

function RgbLed:setHsb(h, s, v)
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

function Strand:Wheel(WheelPos)
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

function Strand:rainbowCycle()
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

function Strand:cycle()
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

function Strand:stop()
  tmr.stop(self.timer)
end

return Strand
