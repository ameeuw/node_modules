--[[
SensorNode.lua module
Author: Arne Meeuw
github.com/ameeuw

Initialize:
SensorNode = require('SensorNode').new(sleeptime, mqttHost, mqttPort)

Methods:
SensorNode:addSensor(sensor, opt1, opt2)
SensorNode:measure()
SensorNode:publishValue(value)
SensorNode:goSleep()
 --]]

local SensorNode = {}
SensorNode.__index = SensorNode

function SensorNode.new(sleeptime, mqttHost, mqttPort)

	local self = setmetatable({}, SensorNode)
	name = name or 'SensorNode:'..string.sub(wifi.sta.getmac(),13,-1)
	self.timer = timer or 2
	self.sleeptime = sleeptime or 60
	self.waittime = waittime or 5
	-- Keep SensorNode open to use with every SensorType
	--self.Sensor = require(sensor).new()

	self.sensors = {}
	self.counter = 1

	-- Instantiate MqttClient with topic and services
	self.MqttClient = require('MqttClient').new(mqttHost, mqttPort, 'IAQ', '{"MqttClient" : "true", "'..name..'" : "true"}')

	print("Measurement starting in "..self.waittime.." seconds...")
	tmr.alarm(self.timer,self.waittime*1000, 0,
		function()
				self:measure()
		end)

	return self
end

function SensorNode:addSensor(sensor, opt0, opt1)
	table.insert(self.sensors, require(sensor).new(opt0, opt1))
end

function SensorNode:measure()
	if self.sensors[self.counter] ~= nil then
		self.sensors[self.counter]:measure(
			function(value)
				self.counter = self.counter + 1
				self:publishValue(value)
				tmr.alarm(self.timer, 500, 0,
					function()
						self:measure()
					end)
			end)
	else
		-- self.counter = 1
		-- self:goSleep()
	end

end

function SensorNode:publishValue(value)
	if value ~= nil then
		print("Attempting to publish...")
		self.MqttClient:publish(self.MqttClient.topic.."get", tostring(value), 0, 0,
			function()
				print("Published "..value.." to "..self.MqttClient.topic.."get")

				if self.sensors[self.counter] == nil then
					self:goSleep()
				end

			end)
	else
		print("No return value received.")
		--self:goSleep()
	end
end

function SensorNode:goSleep()
	tmr.alarm(self.timer+1,2500, 0,
		function()
			print("Going to sleep for "..self.sleeptime.." seconds...")
			node.dsleep(self.sleeptime*1000000)
		end)
end

return SensorNode
