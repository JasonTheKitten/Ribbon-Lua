local cplat = require()
local environment = cplat.require "environment"

local natives = environment.getNatives()

local isCC = environment.rootIs("CC")
local isOC = environment.rootIs("OC")

local shell = ...
shell.runShellApp = function(file, context, oenv, yieldhandler)
	--Lots of stuff: context, events, etc
	local env = util.copy(oenv or natives)
	
end