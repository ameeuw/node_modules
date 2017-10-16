--[[
Gauge.lua module
Author: Arne Meeuw
github.com/ameeuw

Skeleton for creating a Gauge

Initialize:
Gauge = require('Gauge').new()

Methods:
Gauge:function()
 --]]

local Gauge = {}
Gauge.__index = Gauge

function Gauge.new()
	local self = setmetatable({}, Gauge)
	name = name or 'Gauge:'..string.sub(wifi.sta.getmac(),13,-1)
	self.position = 0
	if switec ~= nil then
		switec.setup(0, 8, 7, 6, 5)
		self:calibrate()
	end

	self.start = 800
	self.stop = 200
	self.steps = 1000

	return self
end

function Gauge:calibrate(callback)
	switec.moveto(0, -1000, function()
		switec.reset(0)
		switec.moveto(0, self.start, function()
			print("Calibration done.")
			if callback ~= nil then
				callback()
			end
		end)
		self.position = 0
	end)
end

-- position ranges from 0-1000 and is mapped to 800-200
function Gauge:moveto(position, callback)
	newpos = (self.start * self.steps - ( (self.start - self.stop) * position )) / self.steps
	switec.moveto(0, newpos, function()
		self.position = position
		if callback ~= nil then
			callback()
		end
	end)
end

return Gauge
