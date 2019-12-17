local ribbon = require()
local environment = ribbon.require "environment"

local natives = environment.getNatives()

local isCC = environment.is("CC")
local isOC = environment.is("OC")

local display = ...

local term_current, term_native, null_ref = {}, {}, {}
display.term_current, display.term_native = term_current, term_native
local displays, displays2 = {[0] = term_current}, {}
if isCC then table.insert(displays, term_native) end

local function putDisplay(d)
	if not displays2[d] then
		table.insert(displays, d)
		displays2[d] = true
	end
end

display.getDisplay = function(id)
	return display.getDisplays()[id or 1]
end

display.getDisplays = function()
	if isCC then
		for k, v in pairs(natives.peripheral.getNames()) do
			if not displays2[v] and natives.peripheral.getType(v) == "monitor" then
				table.insert(displays, v)
				displays2[v] = true
			end
		end
		return displays
	elseif isOC then
		local component = natives.require("component")
		local gpu = component.proxy(component.list("gpu", true)())
		if not gpu then
			displays[0] = null_ref
			return displays
		end
		for addr in component.list("screen") do
			putDisplay(addr)
		end
		return displays
	end
end
display.getDefaultDisplayID = function()
	return 0
end
display.getTotalDisplays = function()
	return #display.getDisplays()+1
end
display.checkDisplayAvailable = function(id)
	if not id then return false end
	local disp = displays[id]
	if not disp then return false end
	if disp == term_native and isCC then return true end
	if disp == null_ref then return false end
	if isOC then
		local component = natives.require("component")
		local gpu = component.proxy(component.list("gpu", true)())
		if not gpu then return false end
		local addr = id
		if disp == term_current then
			addr = gpu.getScreen()
		end
		if not addr then return false end
		return component.isAvailable(addr)
	elseif isCC then
		if disp == term_current then
			local ok = pcall(term.current().isColor)
			return ok
		end
		return not not natives.peripheral.wrap(disp)
	end
	return true
end
