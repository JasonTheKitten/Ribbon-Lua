local ribbon = require()

local environment = ribbon.require "environment"
local process = ribbon.require "process"

local natives = environment.getNatives()

local isCC = environment.is("CC")
local isOC = environment.is("OC")

local shell = ...

shell.execute = function(command)
	process.executeRaw(function()
		if isCC then
			pcall(natives.shell.run, command)
		elseif isOC then
			pcall(natives.require("shell").execute, command)
		end
	end)
end
shell.loadfile = function(file, ...)
	return natives.loadfile("/"..file)
end
shell.runfile = function(file, ...)
	local args = {...}
	local env
	process.executeRaw(function()
		pcall(natives.loadfile("/"..file, natives), table.unpack(args))
	end)
end