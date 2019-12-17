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

--Unless otherwise disabled, Ribbon apps may automatically support a variety of data shares
--This includes, but is not limited to:
--OPEN, CURSOR, CURSOR2, CURSORDATA, CLIPBOARD, event:MOUSE_EXIT

--Ribbon does not natively support a permission API
--However, the reccomended data shares for this type of API are:
--PERMISSION_REQUEST, PERMISSION_CHECK, PERMISSION_GET, event:PERMISSION_GRANTED

--Non-standard events you may wish to implement include:
--event:CLIPBOARD_CHANGE


local ribbon = require()

local process = ribbon.require "process"
local shell = ribbon.require "shell"

local ribbonos = ...

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
	SUPPORT_RIBBONOS = true,
	onReceiveRequested = function(g, d)
		g=g:upper()
		if normal[g] then
			dhdata[g] = d
		elseif g=="OPEN" then
			if not type(d) == "string" then return end
			local p = d:find(":")
			if not p then return end
			local pro = d:sub(1, p-1):lower()
			local pa = d:sub(p+1, #d)
			if pro=="edit" then
				shell.execute("edit "..pa)
			end
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

local mhost = ((host or {}).SUPPORT_RIBBONOS and host) or {}
local host = {}
setmetatable(host, {__index = function(t, k)
	return mhost[k] or defaultHost[k]
end})

ribbonos.getHost = function()
	return host
end

ribbonos.send = function(g, d)
	local host = ribbonos.getHost()
	host.onReceiveRequested(g, d)
end
ribbonos.receive = function(g, d)
	local host = ribbonos.getHost()
	return host.onSendRequested(g, d)
end

do
	local host = ribbonos.getHost()
	local es, inst = process.createEventSystem()
	inst(ribbonos)
	if host.connectEventListener then
		host.connectEventListener(es)
	end
	ribbonos.addEventListener("MOUSE_EXIT", function(e)
		process.fireEvent("mouse_exit", e)
	end)
end

ribbonos.getDefaultDataShareEnabled = function()
	return defaultCB
end
ribbonos.setDefaultDataShareEnabled = function(b)
	defaultCB = b
end
ribbonos.sendIfD = function(...)
	if defaultCB then ribbonos.send(...) end
end
ribbonos.receiveIfD = function(...)
	return defaultCB and ribbonos.receive(...) or {}
end