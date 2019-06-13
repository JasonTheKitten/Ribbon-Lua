local cplat = require()
local environment = cplat.require "environment"
local util = cplat.require "util"

local natives = environment.getNatives()

local isCP = environment.is("CP")
local isCC = environment.is("CC")
local isOC = environment.is("OC")

local process = ...
local eventregister = {}
local backgroundscripts = {}

local eq = {}

process.execute = function(f, ...)
	local cid = tostring(cplat):gsub("table: ", "")
	if isCC then natives.os.queueEvent("q_bottom", cid) end
	local ok, err
	local c = coroutine.create(f)
	ok, err = coroutine.resume(c, ...)
	local resume = function() end
	if isCC then
		resume = function()
			eq = {}
			local e = {coroutine.yield()}
			while (e[1]~="q_bottom" and e[2]~=cid) do
				if e[1] == "terminate" then error("Terminated", -1) end
				table.insert(eq, 1, e)
				e = {coroutine.yield()}
			end
			natives.os.queueEvent("q_bottom", tostring(cplat):gsub("table: ", ""))
			for i=1, #eq do
				process.fireEvent(eq[i][1], {})
			end
			ok, err = coroutine.resume(c, cplat.getPassArgs())
		end
	elseif isOC then
		resume = function()
			eq = {}
			local e = {natives.require("computer").pullSignal(0)}
			while (#e>0) do
				table.insert(eq, 1, e)
				e = {natives.require("computer").pullSignal(0)}
			end
			for i=1, #eq do
				process.fireEvent(eq[i][1], {})
			end
			ok, err = coroutine.resume(c, cplat.getPassArgs())
		end
	elseif isCP then
		resume = function()
			coroutine.yield()
			ok, err = coroutine.resume(c, cplat.getPassArgs())
		end
	end
	while coroutine.status(c)~="dead" do
		resume()
	end
	if not ok then error(err, -1) end
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
		if e~=nil and eventSystem.listeners[e] then
			for k, v in util.pairs(eventSystem.listeners[e]) do
				v(d)
			end
		end
		for k, v in util.pairs(eventSystem.rlisteners) do
			v(e, d)
		end
		if eventSystem.doDefault then
			if e~=nil and eventSystem.defaultListeners[e] then
				for k, v in util.pairs(eventSystem.defaultListeners[e]) do
					v(d)
				end
			end
			for k, v in util.pairs(eventSystem.defaultRListeners) do
				v(e, d)
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

local m_es, installer = process.createEventSystem()
installer(process)