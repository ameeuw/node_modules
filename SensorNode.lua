--[[
SensorNode.lua module
Author: Arne Meeuw
github.com/ameeuw

Skeleton for creating a SensorNode

Initialize:
SensorNode = require('SensorNode').new(sensor, sleeptime, mqttHost, mqttPort)

Methods:
SensorNode:publishValue()
SensorNode:goSleep()
 --]]

local SensorNode = {}
SensorNode.__index = SensorNode

function SensorNode.new(sensor, sleeptime, mqttHost, mqttPort)

	local self = setmetatable({}, SensorNode)
	name = name or 'SensorNode:'..string.sub(wifi.sta.getmac(),13,-1)
	self.timer = timer or 4
	self.sleeptime = sleeptime or 60
	-- Keep SensorNode open to use with every SensorType
	self.Sensor = require(sensor).new()
	-- Instantiate MqttClient with topic and services
	self.MqttClient = require('MqttClient').new(mqttHost, mqttPort, 'AQI', '{"MqttClient" : "true", "'..sensor..'" : "true"}')

	-- Take measurement after boot up
	-- TODO: Idea is that sensor takes care of duration to get ready and only executes callback when done
	self.Sensor:measure(function(value) self:publishValue(value) end)

	return self
end

function SensorNode:publishValue(value)
	if value ~= nil then
		print("Attempting to publish...")
		self.MqttClient:publish(self.MqttClient.topic.."get", tostring(value), 0, 0,
			function()
				print("Published "..value.." to "..self.MqttClient.topic.."get")
				self:goSleep()
			end)
	else
		print("No return value received.")
		self:goSleep()
	end
end

function SensorNode:goSleep()
	tmr.alarm(self.timer,2500, 0,
		function()
			print("Going to sleep for "..self.sleeptime.." seconds...")
			node.dsleep(self.sleeptime*1000000)
		end)
end

return SensorNode
