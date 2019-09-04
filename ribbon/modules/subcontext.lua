local ribbon = require()

local contextapi = ribbon.require "context"

local sctx = ...

sctx.getContext = function(p, x, y, l, h)
	local ctx = contextapi.getContext(p, x, y, l, h)
	
	ctx.useFunctions = p.useFunctions
	ctx.setFunctions = p.setFunctions
	ctx.setFunction = p.setFunction
	ctx.getFunctions = p.getFunctions
	ctx.getFunction = p.getFunction
	ctx.triggers = p.triggers
	
	return ctx
end