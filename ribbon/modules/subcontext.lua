local ribbon = require()

local contextapi = ribbon.require "context"

local sctx = ...

local function checkInitialized(internals)
	if not internals.drawing then error("Attempt to use context while not drawing", 3) end
end
local function cXY(ctx, x, y, l)
	x, y = x-ctx.scroll.x, y-ctx.scroll.y
	x = (ctx.INTERNALS.xinverted and ctx.width-x-(l or 1)) or x
	return x, y
end

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