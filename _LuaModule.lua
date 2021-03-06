--[[
LuaModule.lua module
Author: Arne Meeuw
github.com/ameeuw

Skeleton for creating a LuaModule

Initialize:
LuaModule = require('LuaModule').new()

Methods:
LuaModule:function()
 --]]

local LuaModule = {}
LuaModule.__index = LuaModule

function LuaModule.new()

	local self = setmetatable({}, LuaModule)
	name = name or 'LuaModule:'..string.sub(wifi.sta.getmac(),13,-1)

	return self
end

function LuaModule:function()
  print("function call!")
end

return LuaModule
