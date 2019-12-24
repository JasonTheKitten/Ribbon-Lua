--Thank you @LDDestroier for getting workspace to work space with Ribbon!
--Thank you @Justyn for the alternate code for the `char` event in OC.

--TODO: Thank you @SquidDev for suggesting the use of os.sleep for timer events.
--TODO: Finish HTTP
--TODO: Move interrupts enabled check, queue interrupts, add clear interrupts function
--TODO: "False yields" - hide yielding from programs
--TODO: settimeout-type function

local ribbon = require()

local debugger = ribbon.require "debugger"
local environment = ribbon.require "environment"
local util = ribbon.require "util"

local natives = environment.getNatives()

local isCC = environment.is("CC")
local isOC = environment.is("OC")

local process = ...
local eventregister = {}
local backgroundscripts = {}
local eventsystems = {}
local rawProcs = {}

local eq = {}
process.execute = function(f, ...)
	local cid = tostring(ribbon):gsub("table: ", "")
	local c = coroutine.create(f)
	local ok, err = coroutine.resume(c, ...)
	local catchEvents
	local function runProcs()
		local i=0
		while #rawProcs>i do
			i=i+1
			rawProcs[i]()
		end
		rawProcs = {}
	end
	local function resume()
		for i=1, #eq do
			process.fireEvent("rawevent", {
				rawevent = eq[i],
				parent = process
			})
			if eventregister[eq[i][1]] then eventregister[eq[i][1]](eq[i]) end
		end
		runProcs()
		ok, err = coroutine.resume(c, ribbon.getPassArgs())
	end
	local function terminate()
		error("User terminated application", -1)
	end
	if isCC then
		catchEvents = function()
			eq = {}
			natives.os.queueEvent("q_bottom", cid)
			local tid = natives.os.startTimer(.1) --.05
			local e = {coroutine.yield()}
			while not ((e[1]=="q_bottom" and e[2]==cid) or (e[1] == "timer" and e[2] == tid)) do
				if e[1] == "terminate" then terminate() end
				table.insert(eq, 1, e)
				e = {coroutine.yield()}
			end
			natives.os.cancelTimer(tid)
		end
	elseif isOC then
		catchEvents = function()
			eq = {}
			local e = {natives.require("computer").pullSignal(.1)}
			while (#e>0) do
				if e[1] == "interrupted" then terminate() end
				eq[#eq+1] = e --I guess we insert at the last index for OC? Huh..
				e = {natives.require("computer").pullSignal(.1)}
			end
		end
	end
	while coroutine.status(c)~="dead" do
		process.executingBackgroundScripts = true
		for k, v in pairs(backgroundscripts) do
			if coroutine.status(v)~="dead" then
				coroutine.resume(v)
			end
		end
		process.executingBackgroundScripts = nil
		catchEvents()
		resume()
	end
	if not ok then error(err, -1) end
end
process.executeRaw = function(f)
	table.insert(rawProcs, f)
end

process.registerEvent = function(e, f)
	eventregister[e] = f
end

process.registerBackgroundScript = function(s)
	table.insert(backgroundscripts, coroutine.create(s))
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
		d.name = e
		if not eventSystem.interruptsEnabled then return end
		eventSystem.doDefault = true
		local function execL(v)
			local c = coroutine.create(function(...)
				local ok, err = pcall(v, ...)
				if not ok then debugger.error(err) end
			end)
			local ok, err = coroutine.resume(c, e, d)
			if not ok then debugger.log(err) end
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
				eventSystem.defaultListeners[e] = eventSystem.defaultListeners[e] or {}
				eventSystem.defaultListeners[e][id] = f
			else
				eventSystem.defaultRListeners[id] = f
			end
		else
			if e then
				eventSystem.listeners[e] = eventSystem.listeners[e] or {}
				eventSystem.listeners[e][id] = f
			else
				eventSystem.rlisteners[id] = f
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
	--[[eventSystem.getLatestEvent = function()
		return eventSystem.latestEvent
	end]]

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
	process.registerEvent("monitor_resize", function(e)
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
			x = e[3]-1,
			y = e[4]-1,
			button = e[2],
			display = 1
		})
	end)
	process.registerEvent("monitor_touch", function(e)
		local evd = {
			parent = process,
			rawevent = e,
			x = e[3]-1,
			y = e[4]-1,
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
			x = e[3]-1,
			y = e[4]-1,
			button = e[2],
			display = nil
		})
	end)
	process.registerEvent("mouse_drag", function(e)
		process.fireEvent("mouse_drag", {
			parent = process,
			rawevent = e,
			x = e[3]-1,
			y = e[4]-1,
			button = e[2],
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

	--HTTP
	local function httpGenHandle(nh)
		if not nh then return end
		return {
			getResponseHeader = function(n)
				local headers = nh.getResponseHeaders()
				n=n:lower()
				for k, v in pairs(headers) do
					if k:lower() == n then return v end
				end
			end,
			getResponseHeaders = nh.getResponseHeaders,
			getResponseCode = nh.getResponseCode,
			--getResponseText = nh.getResponseText or function() return "<?>" end,
			read = nh.read,
			readAll = nh.readAll,
			close = nh.close
		}
	end
	process.registerEvent("http_success", function(e)
		process.fireEvent("http_response", {
			parent = process,
			rawevent = e,
			ok = true,
			URL = e[2],
			handle = httpGenHandle(e[3])
		})
	end)
	process.registerEvent("http_failure", function(e)
		process.fireEvent("http_response", {
			parent = process,
			rawevent = e,
			ok = false,
			URL = e[2],
			error = e[3],
			handle = httpGenHandle(e[4])
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
		if e[3]>31 and e[3]<=255 then
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
	process.registerEvent("touch", function(e)
		process.fireEvent("mouse_click", {
			parent = process,
			rawevent = e,
			x = e[3]-1,
			y = e[4]-1,
			button = e[5]+1,
			display = nil
		})
	end)
	process.registerEvent("drop", function(e)
		process.fireEvent("mouse_up", {
			parent = process,
			rawevent = e,
			x = e[3]-1,
			y = e[4]-1,
			button = e[5]+1,
			display = nil
		})
	end)
	process.registerEvent("drag", function(e)
		process.fireEvent("mouse_drag", {
			parent = process,
			rawevent = e,
			x = e[3]-1,
			y = e[4]-1,
			button = e[5]+1,
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