--[[
MqttClient.lua module
Author: Arne Meeuw
github.com/ameeuw

Module for a simplified MQTT client. Callbacks are (un-)registered with the corresponding functions.
If a global name is present it is taken as base for mqtt topic.

Initialize:
MqttClient = require('MqttClient').new(mqttHost, mqttPort)

Methods:
MqttClient:register(topic, function(topic, message) print(topic, message) end)
MqttClient:unregister(topic)
--]]

local MqttClient = {}
MqttClient.__index = MqttClient

function MqttClient.new(mqttHost, mqttPort)

	local self = setmetatable({}, MqttClient)
	name = name or 'MqttClient:'..string.sub(wifi.sta.getmac(),13,-1)
	self.timer = timer or 5

	if RgbLed == nil and ( ( file.exists("RgbLed.lua") or file.exists("RgbLed.lc") ) ) then
			RgbLed = require("RgbLed").new("PWM",{8,6,7})
	end

	if RgbLed ~= nil then
		RgbLed:breathe(1,0,50,0)
	end

  self.mqttHost = mqttHost
  self.mqttPort = mqttPort
	self.domain = 'burggraben'
	self.topic = self.domain..'/'..name..'/'
	self.services = '{"MqttClient" : "true", "lightsensor" : "true"}'

	-- Initialize callback listener table
	self.callbacks = {}

	-- Instantiate new MQTT client
	self.MqttClient = mqtt.Client(name..':'..tostring(math.random(1000)), 120, "", "")

	if RgbLed ~= nil then
		RgbLed:breathe(-1,100,10,0)
	end

	-- Start connecting to broker
	tmr.alarm(self.timer,5000, 1,
		function()
			print("Connecting MQTT")
			self.MqttClient:connect(self.mqttHost, self.mqttPort)
		end)

	-- Publish services on connect and subscribe to topic
	self.MqttClient:on("connect",
		function()
    	tmr.stop(self.timer)
			if RgbLed ~= nil then
				RgbLed:stop()
				RgbLed:setRgb(0,40,40)
				RgbLed:fade(0,0,0)
			end
			print("Connected to:",self.mqttHost)
			self.MqttClient:publish(self.topic.."services/get", self.services, 0, 1)
			self.MqttClient:subscribe(self.topic.."#", 0)
		end)

	-- Add reconnection on disconnect
	self.MqttClient:on("offline",
		function(client)
			print("Connection lost - reconnecting.")
			if RgbLed ~= nil then
				RgbLed:breathe(-1,100,10,0)
			end
			tmr.alarm(self.timer,1000, 1,
				function()
					print("...")
					self.MqttClient:connect(self.mqttHost, self.mqttPort)
				end)
		end)

		-- Add on("message") function to forward incoming topic changes to existing hooks
		self.MqttClient:on("message",
			function(client, topic, message)
				if message ~= nil then
					for callbackTopic, callback in pairs(self.callbacks) do
						-- print(callbackTopic, callback)
						if (topic == self.topic..callbackTopic) then
							--print(topic, message)
							callback(topic, message)
						end
					end
				end
			end)

	return self
end

function MqttClient:register(topic, callback)
	-- add to callback listeners
	self.callbacks[topic] = self.callbacks[topic] or callback
end

function MqttClient:unregister(topic)
	-- remove callback listener
	self.callbacks[topic] = nil
end

return MqttClient
