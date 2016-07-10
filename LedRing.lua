-- LedRing.lua module
-- Author: Arne Meeuw
-- github.com/ameeuw
--
--
-- Initialize:
-- LedRing = require('LedRing').new(pin, numberOfLeds)
--

local LedRing = {}
LedRing.__index = LedRing

function LedRing.new(pin, numberOfLeds)
	-- TODO: add timer variable to change timer number
	local self = setmetatable({}, LedRing)
	local self.pin = pin

  self.buffer = ws2812.newBuffer(numberOfLeds, 3)
	--self.strand = require("strand")

	return self
end

function spotToAngle(self, bgColor, spotColor, angle)
	local function getMixColor(bgColor, fgColor, dist)
		local color = {}
		for i,v in ipairs(bgColor) do
			color[i] = ( (dist * bgColor[i]) + (100-dist) * fgColor[i] ) / 100
		end
		return color
	end
  local ledRange = 100 * angle%360 * self.buffer:size() / 360 -- led number * 100
  local distribution = (ledRange % 100)
  local led = (ledRange - distribution) / 100
  ledColor = getMixColor(bgColor, spotColor, distribution)
  nexLedColor = getMixColor(bgColor, spotColor, (100 - distribution))

  self.buffer:fill(bgColor[1], bgColor[2], bgColor[3])
  self.buffer:set(led, ledColor[1], ledColor[2], ledColor[3])
  self.buffer:set((led+1), nexLedColor[1], nexLedColor[2], nexLedColor[3])
  self.buffer:write()
  
  print("Setting led "..led.." to: "..ledColor[1]..","..ledColor[2]..","..ledColor[3])
  print("Setting led "..(led+1).." to: "..nexLedColor[1]..","..nexLedColor[2]..","..nexLedColor[3])
  end

return LedRing
