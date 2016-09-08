--[[
MqttClient.lua module
Author: Arne Meeuw
github.com/ameeuw

Module for a simplified MQTT client. Callbacks are (un-)registered with the corresponding functions.
If a global name is present it is taken as base for mqtt topic.

Initialize:
MqttClient = require('MqttClient').new(mqttHost, mqttPort, domain, services)
	domain: nil or domain-name
	service: nil or JSON with services

Methods:
MqttClient:register(topic, function(topic, message) print(topic, message) end)
MqttClient:unregister(topic)
--]]

local MqttClient = {}
MqttClient.__index = MqttClient

function MqttClient.new(mqttHost, mqttPort, domain, services)

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
	self.domain = domain or 'burggraben'
	self.topic = self.domain..'/'..name..'/'
	self.services = services or '{"MqttClient" : "true"}'
	self.online = false
	-- Initialize callback listener table
	self.callbacks = {}
	self.pubQueue = {}

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
			self.online = true
    	tmr.stop(self.timer)
			if RgbLed ~= nil then
				RgbLed:stop()
				RgbLed:setRgb(0,40,40)
				RgbLed:fade(0,0,0)
			end
			print("Connected to:",self.mqttHost)
			self.MqttClient:publish(self.topic.."services/get", self.services, 0, 1)
			self.MqttClient:subscribe(self.topic.."#", 0)
			self:processQueue()
		end)

	-- Add reconnection on disconnect
	self.MqttClient:on("offline",
		function(client)
			self.online = false
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
				-- print(topic, message)
				if message ~= nil then
					for callbackTopic, callback in pairs(self.callbacks) do
						 --print(callbackTopic, callback)
						if (topic == self.topic..callbackTopic) then
							-- print(topic, message)
							callback(topic, message)
						end
					end
				end
			end)

	return self
end

function MqttClient:publish(topic, message, qos, retain, callback)
	table.insert(self.pubQueue, {['topic']=topic, ['message']=message, ['qos']=qos, ['retain']=retain, ['callback']=callback})
	self:processQueue()
end

function MqttClient:processQueue()
	if self.online then
		for i,pub in ipairs(self.pubQueue) do
			self.MqttClient:publish(pub.topic, pub.message, pub.qos, pub.retain)
			if pub.callback ~= nil then
				pub.callback()
			end
			table.remove(self.pubQueue, i)
		end
	end
end

function MqttClient:register(topic, callback)
	-- add to callback listeners
	self.callbacks[topic] = self.callbacks[topic] or callback
	self.MqttClient:subscribe(self.topic..topic, 0)
end

function MqttClient:unregister(topic)
	-- remove callback listener
	self.callbacks[topic] = nil
	self.MqttClient:unsubscribe(self.topic..topic)
end

return MqttClient
