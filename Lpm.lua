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
	self.baseUrl = "http://192.168.2.17:8888/"
	self.repo = "node_modules/"

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

function Lpm:upgrade(module)
  print("function call!")
	if module ~= nil then
	else
		for k, v in pairs(modules) do
		end
	end
end

function Lpm:list()
	if modules ~= nil then
		for k, v in pairs(modules) do
			if file.exists(k..'.lua') then
				print(k, v)
			end
		end
	end
end

function Lpm:compile(module)
	if module ~= nil then
		self:compileModule(module)
	else
		for cmodule,v in pairs(modules) do
			self:compile(cmodule)
		end
	end
end

function Lpm:compileModule(module)
	print("Compiling: '"..module.."'")
	local filename = module..'.lua'
	if file.exists(filename) then
		node.compile(filename)
		file.remove(filename)
	end
end

function Lpm:installModule(module, options, callback)
	local filename = module..'.lua'
	local url = self.baseUrl..self.repo..filename
	local auth = "Authorization: Basic <AUTH INFO HERE>\r\n"
	-- TODO: add VERSION to 'application/vnd.github.VERSION.raw'
	--local mediatype = "Accept: application/vnd.github.raw\r\n"

	print("\nDownloading: '"..module.."'")
	local function download(bytestart)
	  bytestart = bytestart or 0
	  chunksize = 1000
	  range = "Range:bytes="..tostring(bytestart).."-"..tostring(bytestart+chunksize-1).."\r\n"
	  http.get(url, range, function(code, data)
	    if (code < 0) then
	      print("HTTP request failed:", code)
	      return code
	    else
	      file.open(tostring(bytestart),"w+")
	      file.write(data)
	      file.close()

	      if string.len(data) < chunksize then
					if file.exists(filename) then
						file.remove(filename)
					end
	        for i = 0,bytestart,chunksize do
	          file.open(tostring(i),"r")
	          local temp = file.read()
	          file.close()
	          file.open(filename,"a+")
	          file.write(temp)
	          file.close()
	          file.remove(tostring(i))
	        end
					if options ~= nil then
						if options == '-c' then
							self:compile(module)
						end
					end
					print("\n'"..module.."' installed.")
					if callback~=nil then
						callback()
					end
	      else
	        tmr.alarm(0, 100, tmr.ALARM_SINGLE,
	        function()
	          download(bytestart + chunksize)
	        end)
	      end
	    end
	    end)
	end
	download()
end

function Lpm:install(module, options)
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
