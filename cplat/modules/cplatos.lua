--This file is used for passing data and action calls between 
--a host application and guest application

--Why might this file be useful?
--This file was designed to support passing of information
--This can be any type of information

--However, here are some ideas:
-- * Data sharing: Keep track of data being shared across applications
--   This may allow features such as file dragging and clipboards.
-- * Cursors: For example, the application may tell its host to display an "X" cursor if
--   a file dragging operation is invalid
-- * Permissions: An application may tell it's host to grant a permission that was not declared
--   when the application was launched. It may also receive permissions.

--In order for this file to be useful, two applications must use similar data handling methods

--Unless otherwise disabled, CPlat apps may automatically support a variety of data shares
--This includes, but is not limited to:
--CURSOR, CURSOR2, CURSORDATA, CLIPBOARD, event:MOUSE_EXIT

--CPlat does not natively support a permission API
--However, the reccomended data shares for this type of API are:
--PERMISSION_REQUEST, PERMISSION_CHECK, PERMISSION_GET, event:PERMISSION_GRANTED

--Non-standard events you may wish to implement include:
--event:CLIPBOARD_CHANGE


local cplat = require()

local environment = cplat.require "environment"
local process = cplat.require "process"

local natives = environment.getNatives()

local cplatos = ...

local defaultCB = true
local triggers = {}
local dhdata = {
	CLIPBOARD = {
		clipboarddata = nil,
		clipboardtype = nil
	},
	CURSOR = {
		FOREGROUND = 0,
		BACKGROUND = 15,
		SYMBOL = nil
	},
	CURSOR2 = {
		FOREGROUND = 0,
		BACKGROUND = 15,
		SYMBOL = nil
	},
	CURSORDATA = {
		clipboarddata = nil,
		clipboardtype = nil,
	},
}
local normal = {
	["CLIPBOARD"] = true,
	["CURSOR"] = true,
	["CURSOR2"] = true,
	["CURSORDATA"] = true
}
local defaultHost = {
	onReceiveRequested = function(g, d)
		if normal[g] then
			dhdata[g] = d
		end
	end,
	onSendRequested = function(g, d)
		if normal[g] then
			return dhdata[g]
		end
	end,
	connectEventListener = function(es)
		table.insert(triggers, es.fireEvent)
	end
}
process.addEventListener("mouse_up", function()
	dhdata["CURSORDATA"] = {}
end)


cplatos.getHost = function()
	local host = natives.CPLATHOST
	return (host or {}).SUPPORT_CPLATOS and host or defaultHost
end

cplatos.send = function(g, d)
	local host = cplatos.getHost()
	if host.onSendRequested then host.onReceiveRequested(g, d) end
end
cplatos.receive = function(g, d)
	local host = cplatos.getHost()
	if host.onSendRequested then return host.onSendRequested(g, d) end
end

do
	local host = cplatos.getHost()
	local es, inst = process.createEventSystem()
	inst(cplatos)
	if host.connectEventListener then
		host.connectEventListener(es)
	end
	cplatos.addEventListener("MOUSE_EXIT", function(e)
		process.fireEvent("mouse_exit", e)
	end)
end

cplatos.getDefaultDataShareEnabled = function()
	return defaultCB
end
cplatos.setDefaultDataShareEnabled = function(b)
	defaultCB = b
end
cplatos.sendIfD = function(...)
	if defaultCB then cplatos.send(...) end
end
cplatos.receiveIfD = function(...)
	return defaultCB and cplatos.receive(...) or {}
end