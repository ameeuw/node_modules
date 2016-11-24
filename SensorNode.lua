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

function SensorNode.new(sleeptime, mqttHost, mqttPort, period)

	local self = setmetatable({}, SensorNode)
	name = name or 'SensorNode:'..string.sub(wifi.sta.getmac(),13,-1)
	self.timer = timer or 2
	self.sleeptime = sleeptime or -1
	self.period = period or 120
	self.waittime = waittime or 2
	-- Keep SensorNode open to use with every SensorType
	--self.Sensor = require(sensor).new()

	self.sensors = {}
	self.counter = 1

	-- Instantiate MqttClient with topic and services
	self.MqttClient = require('MqttClient').new(mqttHost, mqttPort, 'IAQ', '{"MqttClient" : "true", "'..name..'" : "true"}')

	-- TODO: sync time every 12 hours
	if rtctime.get() == 0 then
		self:syncTime(function() self:goSleep() end)
	else

	end

	-- print("Measurement starting in "..self.waittime.." seconds...")
	-- tmr.alarm(self.timer,self.waittime*1000, 0,
	-- 	function()
	-- 			--self:measure()
	-- 	end)

	return self
end

function SensorNode:syncTime(callback)
	sntp.sync('3.ch.pool.ntp.org',

	  function(sec,usec,server)
			rtctime.set(sec, usec)
	    print(string.format('Got UTC: %d.%d s, from: %s', sec, usec, server))
			local tm = rtctime.epoch2cal(rtctime.get())
			print(string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
			callback()
	  end,

	  function()
	 		print('Sync failed, trying again in 10 seconds...')
			tmr.alarm(self.timer, 10000, 0, function()
				self:syncTime(callback)
			end)
	  end)
end

function SensorNode:addSensor(sensor, opt0, opt1)
	table.insert(self.sensors, require(sensor).new(opt0, opt1))
end

function SensorNode:measure()
	local sec, usec = rtctime.get()
	if self.sensors[self.counter] ~= nil then
		self.sensors[self.counter]:measure(
			function(returnTable)
				self.counter = self.counter + 1
				returnTable.timestamp = sec
				returnJSON = cjson.encode(returnTable)
				if returnJSON~=nil then
					-- TODO: implement random offset, so that not all sensors publish at the same time
					self:publishValue(returnJSON)
				else
					print("Error in encoding returnTable.")
				end
				tmr.alarm(self.timer, 500, 0,
					function()
						self:measure()
					end)
			end)
	else
		--print("No sensors registered.")
		self.counter = 1
		self:goSleep()
	end

end

function SensorNode:publishValue(value)
	if value ~= nil then
		print("Attempting to publish...")
		-- TODO: implement random offset, so that not all sensors publish at the same time
		self.MqttClient:publish(self.MqttClient.topic.."get", tostring(value), 0, 0,
			function()
				print("Published "..value.." to "..self.MqttClient.topic.."get")

				if self.sensors[self.counter] == nil then
					self:goSleep()
				end

			end)
	else
		print("No return value received.")
		if self.sensors[self.counter] == nil then
			self:goSleep()
		end
	end
end

function SensorNode:goSleep()
	if self.sleeptime ~= -1 then
		tmr.alarm(self.timer,2500, 0,
			function()
				print("Going to sleep for "..self.sleeptime.." seconds...")
				rtctime.dsleep(self.sleeptime*1000000)
			end)
	else

		tmr.alarm(self.timer, 1000, 1,
			function()
				local sec, usec = rtctime.get()
				if sec % self.period == 0 then
					tmr.stop(self.timer)
					print("Starting a new measurement...")
					local tm = rtctime.epoch2cal(rtctime.get())
					print(string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
					self:measure()
				end
			end)
	end
end

return SensorNode
