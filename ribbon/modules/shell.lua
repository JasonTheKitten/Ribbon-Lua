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
			natives.shell.run(command)
		elseif isOC then
			natives.require("shell").execute(command)
		end
	end)
end