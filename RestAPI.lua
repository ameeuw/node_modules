-- RestAPI.lua module
-- Author: Arne Meeuw
-- github.com/ameeuw
--
-- Simplified API for RestAPI calls to ESP8266 hardware
--
-- Initialize:
-- RestAPI = require('RestAPI').new(port)
--
-- Add action hook:
-- RestAPI:addHook(callBack, keys)
--
-- Parameters:
-- 	callBack : pointer to callBack function
--	keys : table of key-strings to identify complete entry
--
-- Run server - call this after you made sure you have a connection
-- RestAPI:runServer()

local RestAPI = {}
RestAPI.__index = RestAPI

function RestAPI.new(port)
	local self = setmetatable({}, RestAPI)
	self.port = port
	self.hooks = {}

	return self
end

function RestAPI.runServer(self)
	self.srv = net.createServer(net.TCP)
	self.srv:listen(self.port, function(conn)
		conn:on("receive", function(conn, payload)
			self.parsePayload(self, conn, payload)
		end)
        conn:on("sent", function(conn)
            --print("Closing connection.")
            conn:close()
        end)
	end)
end

function RestAPI.stopServer(self)
    self.srv:close()
end

function RestAPI.addHook(self, callBack, keys)
	local hook = {}
	hook['callBack'] = callBack
	hook['keys'] = keys
	table.insert(self.hooks, hook)
end

function RestAPI.parseCommandTable(self, conn, commandTable)
	-- Loop of registered hooks
	for _,hook in pairs(self.hooks) do
		local matchcount = 0
		-- Loop over keys in current hook
		for _,key in pairs(hook.keys) do
			-- Loop over keys in commandTable
			for cK,_ in pairs(commandTable) do
				-- If keys match
				if key == cK then
					matchcount = matchcount + 1
			   end
		   end
		end

		-- If key matches are sufficient
		if matchcount == table.getn(hook.keys) then
			-- Call the hook callBack function
			hook.callBack(conn, commandTable)
		end
	end
end

function RestAPI.parsePayload(self, conn, payload)
	local commandTable = {}
    --print('!!PAYLOAD!!\n\n'..payload..'\n\n')
    local req = dofile("httpserver-request.lc")(payload)

		-- ok, json = pcall(cjson.encode, req.uri.args)
		-- 		if ok and json~="null" then
		-- 				--print('Sending JSON:',json)
		-- 				conn:send(json)
		-- 		else
		-- 				--print("failed to encode!")
		-- 				conn:send("{'error':'cjson encode fail'}")
		-- end

    self.parseCommandTable(self, conn, req.uri.args)
end

return RestAPI
