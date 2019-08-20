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
	
	ctx.setClickFunction = p.setClickFunction
	ctx.getClickFunction = p.getClickFunction
	ctx.triggers = p.triggers
	
	local internals = ctx.INTERNALS
	local ifn = internals.IFN
	local pifn = ctx.parent.INTERNALS.IFN
	ifn.drawPixel = function(q, x, y, color, char, fg)
		checkInitialized(internals)
		x, y = cXY(ctx, x, y)
		if (x>=0 and (not ctx.width or x<ctx.width)) and (y>=0 and (not ctx.height or y<ctx.height)) then
			color = color or internals.CONFIG.defaultBackgroundColor
			fg = fg or internals.CONFIG.defaultTextColor
			q(pifn.drawPixel, ctx.position.x+x, ctx.position.y+y, color, char, fg)
		end
	end
	
	return ctx
end