--[[
Lpm.lua module
Author: Arne Meeuw
github.com/ameeuw

Skeleton for creating a Lpm

Initialize:
Lpm = require('Lpm').new()

Methods:
Lpm:install(module, options)
Lpm:installModule(module, options)
Lpm:compile(module)
Lpm:compileModule(module)

options: '-c'
--]]

local Lpm = {}
Lpm.__index = Lpm

function Lpm.new()

	local self = setmetatable({}, Lpm)
	name = name or 'Lpm:'..string.sub(wifi.sta.getmac(),13,-1)

	-- self.repo = "https://raw.githubusercontent.com/ameeuw/nodemcu_modules/master/"
	self.baseUrl = "https://api.github.com/"
	self.repo = "repos/ameeuw/node_modules/contents/"

	if file.exists('package.lua') then
		dofile('package.lua')
		for k,v in pairs(modules) do
			print(k,v)
		end
	else
		print("No package.lua file found.")
	end

	return self
end

function Lpm.upgrade(self, module)
  print("function call!")
	if module ~= nil then
	else
		for k, v in pairs(modules) do
		end
	end
end

function Lpm.list()
	if modules ~= nil then
		for k, v in pairs(modules) do
			if file.exists(k..'.lua') then
				print(k, v)
			end
		end
	end
end

function Lpm.compile(self, module)
	if module ~= nil then
		self:compileModule(module)
	else
		for cmodule,v in pairs(modules) do
			self:compile(cmodule)
		end
	end
end

function Lpm.compileModule(self, module)
	print("Compiling: '"..module.."'")
	local filename = module..'.lua'
	if file.exists(filename) then
		node.compile(filename)
		file.remove(filename)
	end
end

function Lpm.installModule(self, module, options, callback)
	local filename = module..'.lua'
	local url = self.baseUrl..self.repo..filename
	local auth = "Authorization: Basic <AUTH INFO HERE>\r\n"
	-- TODO: add VERSION to 'application/vnd.github.VERSION.raw'
	local mediatype = "Accept: application/vnd.github.raw\r\n"

	print("\nDownloading: '"..module.."'")
	http.get(url, mediatype, function(code, data)
			if (code < 0) then
				print("HTTP request failed:", code)
				return code
			else
				print("Writing: '"..filename.."'")
				file.open(filename,"w+")
				file.write(data)
				file.close()
				if options ~= nil then
					if options == '-c' then
						self:compile(module)
					end
				end
			end
			print("\n'"..module.."' installed.")
			if callback~=nil then
				callback()
			end
		end)
end


function Lpm.install(self, module, options)
	if module ~= nil then
		self:installModule(module, options, nil)
	else

		-- TODO: BUILD THIS FUCKING ITERATOR!!
		local work = {}
		for k, v in pairs(modules) do
			print(k, v)
			table.insert(work,k)
		end
		local count = 1
		local cmodule = work[count]
		local function loop(module)
			self:installModule(module, options,
				function()
					count = count + 1
					cmodule = work[count]
					if cmodule~=nil then
						tmr.alarm(0, 200, tmr.ALARM_SINGLE,
							function()
								loop(cmodule)
							end)
					else
						print("\n---------------------\nlpm install finished.\n---------------------\n")
					end
				end)
		end
		loop(cmodule)
	end
end

return Lpm
