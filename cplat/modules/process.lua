--TODO: HTTP

local cplat = require()
local environment = cplat.require "environment"
local util = cplat.require "util"
local debugger = cplat.require "debugger"

local natives = environment.getNatives()

local isCC = environment.is("CC")
local isOC = environment.is("OC")

local process = ...
local eventregister = {}
local backgroundscripts = {}
local eventsystems = {}

local charsStr =
	"`1234567890-="..
	"qwertyuiop[]\\"..
	"asdfghjkl;'"..
	"zxcvbnm,./"..
	"~!@#$%^&*()_+"..
	"QWERTYUIOP{}|"..
	"ASDFGHJKL:\""..
	"ZXCVBNM<>?:"..
	"\t "
	
local chars = util.stringToTable(charsStr, true)


local eq = {}
process.execute = function(f, ...)
	local cid = tostring(cplat):gsub("table: ", "")
	if isCC then natives.os.queueEvent("q_bottom", cid) end
	local ok, err
	local c = coroutine.create(f)
	ok, err = coroutine.resume(c, ...)
	local catchEvents
	local function resume()
		for i=1, #eq do
			process.fireEvent("rawevent", {
				event = eq[i], 
				rawevent = eq[i],
				parent = process
			})
			if eventregister[eq[i][1]] then eventregister[eq[i][1]](eq[i]) end
		end
		ok, err = coroutine.resume(c, cplat.getPassArgs())
	end
	if isCC then
		catchEvents = function()
			eq = {}
			local e = {coroutine.yield()}
			while (e[1]~="q_bottom" and e[2]~=cid) do
				if e[1] == "terminate" then error("User terminated application", -1) end
				table.insert(eq, 1, e)
				e = {coroutine.yield()}
			end
			natives.os.queueEvent("q_bottom", tostring(cplat):gsub("table: ", ""))
		end
	elseif isOC then
		catchEvents = function()
			eq = {}
			local e = {natives.require("computer").pullSignal(0)}
			while (#e>0) do
				table.insert(eq, 1, e)
				e = {natives.require("computer").pullSignal(0)}
			end
		end
	end
	while coroutine.status(c)~="dead" do
		catchEvents()
		resume()
	end
	if not ok then error(err, -1) end
end

process.registerEvent = function(e, f)
	eventregister[e] = f
end

process.createEventSystem = function()
	--TODO: Catch-up when handlers re-enabled
	local eventSystem = {
		listeners = {},
		rlisteners = {},
		defaultListeners = {},
		defaultRListeners = {},
		doDefault = true,
		interruptsEnabled = true,
		latestEvent = nil
	}
	eventSystem.fireEvent = function(e, d)
		d = d or {}
		d.preventDefault = function()
			eventSystem.doDefault = false
		end
		if not eventSystem.interruptsEnabled then
			return --
		end
		eventSystem.doDefault = true
		local function execL(v)
			local c = coroutine.create(function(...)
				local ok, err = pcall(v, ...)
				if not ok then debugger.error(err) end
			end)
			coroutine.resume(c, d, e)
			if coroutine.status(c) ~= "dead" then
				debugger.warn("Interrupt yielded before completion; Execution will not finish.")
			end
		end
		if e~=nil and eventSystem.listeners[e] then
			for k, v in util.pairs(eventSystem.listeners[e]) do
				execL(v)
			end
		end
		for k, v in util.pairs(eventSystem.rlisteners) do
			execL(v)
		end
		if eventSystem.doDefault then
			if e~=nil and eventSystem.defaultListeners[e] then
				for k, v in util.pairs(eventSystem.defaultListeners[e]) do
					execL(v)
				end
			end
			for k, v in util.pairs(eventSystem.defaultRListeners) do
				execL(v)
			end
		end
	end
	local id = 0
	eventSystem.addEventListener = function(e, f, d, mid)
		if not mid then id = id+1 end
		local id = mid or id
		if d then
			if e then
				eventSystem.listeners[e] = eventSystem.listeners[e] or {}
				eventSystem.listeners[e][id] = f
			else
				eventSystem.rlisteners[id] = f
			end
		else
			if e then
				eventSystem.defaultListeners[e] = eventSystem.defaultListeners[e] or {}
				eventSystem.defaultListeners[e][id] = f
			else
				eventSystem.defaultRListeners[id] = f
			end
		end
		return id
	end
	eventSystem.removeEventListener = function(e, id, d)
		eventSystem.addEventListener(e, nil, d, id)
	end
	eventSystem.clearEventListeners = function()
		eventListeners.listeners = {}
		eventListeners.rlisteners = {}
		eventSystem.defaultListeners = {}
		eventSystem.defaultRListeners = {}
	end
	eventSystem.setInterruptsEnabled = function(e)
		eventSystem.interruptsEnabled = e
	end
	eventSystem.getInterruptsEnabled = function()
		return eventSystem.interruptsEnabled
	end
	eventSystem.getLatestEvent = function()
		return eventSystem.latestEvent
	end
	
	return eventSystem, function(tbl)
		--Event System Installer
		for k, v in pairs(eventSystem) do
			if type(v) == "function" then
				tbl[k] = v
			end
		end
	end
end

process.createSynchronousEventQueue = function(es)
	local queue = {}
end

--Setup
local m_es, installer = process.createEventSystem()
installer(process)

if isCC then
	--Keyboard
	process.registerEvent("key", function(e)
		process.fireEvent("key_down", {
			parent = process,
			code = e[2],
			rawevent = e
		})
	end)
	process.registerEvent("key_up", function(e)
		process.fireEvent("key_up", {
			parent = process,
			code = e[2],
			rawevent = e
		})
	end)
	process.registerEvent("char", function(e)
		process.fireEvent("char", {
			parent = process,
			char = e[2],
			rawevent = e
		})
	end)
	process.registerEvent("paste", function(e)
		process.fireEvent("paste", {
			parent = process,
			text = e[2],
			rawevent = e
		})
	end)
	
	--Modem
	process.registerEvent("modem_message", function(e)
		process.fireEvent("modem_message", {
			parent = process,
			rawevent = e,
			sender = e[2],
			port = e[3],
			message = e[5],
			distance = e[6],
		})
	end)
	
	--Display
	process.registerEvent("term_resize", function(e)
		process.fireEvent("display_resize", {
			parent = process,
			rawevent = e
		})
	end)
	
	--Mouse
	process.registerEvent("mouse_click", function(e)
		process.fireEvent("mouse_click", {
			parent = process,
			rawevent = e,
			x = e[3],
			y = e[4],
			button = e[2],
			display = 1
		})
	end)
	process.registerEvent("monitor_touch", function(e)
		local evd = {
			parent = process,
			rawevent = e,
			x = e[3],
			y = e[4],
			button = 1,
			display = nil
		}
		process.fireEvent("mouse_click", evd)
		process.fireEvent("mouse_up", evd)
	end)
	process.registerEvent("mouse_up", function(e)
		process.fireEvent("mouse_up", {
			parent = process,
			rawevent = e,
			x = e[2],
			y = e[3],
			button = e[4],
			display = nil
		})
	end)
	process.registerEvent("mouse_drag", function(e)
		process.fireEvent("mouse_drag", {
			parent = process,
			rawevent = e,
			x = e[2],
			y = e[3],
			button = e[4],
			display = nil
		})
	end)
	process.registerEvent("mouse_scroll", function(e)
		process.fireEvent("mouse_scroll", {
			parent = process,
			rawevent = e,
			amount = e[2],
			display = nil
		})
	end)
	
	--Inventory
	process.registerEvent("turtle_inventory", function(e)
		process.fireEvent("inventory_edit", {
			parent = process,
			rawevent = e,
		})
	end)
	
	--Redstone
	process.registerEvent("redstone", function(e)
		process.fireEvent("redstone_edit", {
			parent = process,
			rawevent = e,
		})
	end)
	
	--Device
	process.registerEvent("peripheral", function(e)
		process.fireEvent("device_connected", {
			parent = process,
			rawevent = e,
			id = e[2]
		})
	end)
	process.registerEvent("peripheral_detach", function(e)
		process.fireEvent("device_removed", {
			parent = process,
			rawevent = e,
			id = e[2]
		})
	end)
else
	--Keyboard
	process.registerEvent("key_down", function(e)
		process.fireEvent("key_down", {
			parent = process,
			code = e[4],
			rawevent = e
		})
		if chars[string.char(e[3])] then
			process.fireEvent("char", {
				parent = process,
				char = string.char(e[3]),
				rawevent = e
			})
		end
	end)
	process.registerEvent("key_up", function(e)
		process.fireEvent("key_up", {
			parent = process,
			code = e[4],
			rawevent = e
		})
	end)
	process.registerEvent("clipboard", function(e)
		process.fireEvent("paste", {
			parent = process,
			text = e[3],
			rawevent = e
		})
	end)
	
	--Modem
	process.registerEvent("modem_message", function(e)
		process.fireEvent("modem_message", {
			parent = process,
			rawevent = e,
			sender = e[3],
			port = e[4],
			distance = e[5],
			message = e[6]
		})
	end)
	
	--Display
	process.registerEvent("screen_resize", function(e)
		--TODO: Include size
		process.fireEvent("display_resize", {
			parent = process,
			rawevent = e
		})
	end)
	
	--Mouse
	process.registerEvent("mouse_click", function(e)
		process.fireEvent("mouse_click", {
			parent = process,
			rawevent = e,
			x = e[2],
			y = e[3],
			button = e[4],
			display = nil
		})
	end)
	process.registerEvent("mouse_drop", function(e)
		process.fireEvent("mouse_up", {
			parent = process,
			rawevent = e,
			x = e[2],
			y = e[3],
			button = e[4],
			display = nil
		})
	end)
	process.registerEvent("drag", function(e)
		process.fireEvent("mouse_drag", {
			parent = process,
			rawevent = e,
			x = e[2],
			y = e[3],
			button = e[4],
			display = nil
		})
	end)
	process.registerEvent("scroll", function(e)
		process.fireEvent("mouse_scroll", {
			parent = process,
			rawevent = e,
			amount = e[5],
			display = nil
		})
	end)
	
	--Inventory
	process.registerEvent("inventory_changed", function(e)
		process.fireEvent("inventory_edit", {
			parent = process,
			rawevent = e,
		})
	end)
	
	--Redstone
	process.registerEvent("redstone_changed", function(e)
		process.fireEvent("redstone_edit", {
			parent = process,
			rawevent = e,
		})
	end)
	
	--Device
	process.registerEvent("component_added", function(e)
		process.fireEvent("device_connected", {
			parent = process,
			rawevent = e,
			id = e[2]
		})
	end)
	process.registerEvent("component_removed", function(e)
		process.fireEvent("device_removed", {
			parent = process,
			rawevent = e,
			id = e[2]
		})
	end)
	
end