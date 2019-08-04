--TODO: Track updated pixels
--TODO: Add a Z buffer

local cplat = require()

local contextapi = cplat.require "context"
local debugger = cplat.require "debugger"

local bctx = ...

bctx.wrapContext = function(ctx, es)
	if not (ctx and es) then error("Arguments should be ctx, es", 2) end
	
	local internals = ctx.INTERNALS
	if internals.isNative then
		error("A buffered context can not be created with a native context; Please use bufferedcontext.getContext to wrap the native context.", 2)
	end
	internals.optimizationsEnabled = false
	
	local ifn = internals.IFN
	
	local function checkInitialized()
		if not internals.drawing then
			error("Attempt to use context while not drawing", 3)
		end
	end

	local buffer = {}
	local charVisible, contextColor = true, nil
	local onclick, onrelease, ondragstart, ondragover, ondragend
	local defaultFunctions = {}
	
	ifn.drawPixel = function(q, x, y, color, char, fg)
		checkInitialized()
		char = char and charVisible and tostring(char)
		x = (internals.xinverted and ctx.width-x-1) or x
		if x>=0 and y>=0 then
			buffer[y] = buffer[y] or {}
			buffer[y][x] = buffer[y][x] or {}
			buffer[y][x].char = char or buffer[y][x].char
			buffer[y][x].foreground = fg or internals.CONFIG.defaultTextColor or buffer[y][x].foreground
			buffer[y][x].background = color or internals.CONFIG.defaultBackgroundColor or buffer[y][x].background
			buffer[y][x].onclick = onclick or buffer[y][x].onclick
			buffer[y][x].onrelease = onrelease or buffer[y][x].onrelease
			buffer[y][x].ondragstart = ondragstart or buffer[y][x].ondragstart
			buffer[y][x].ondragover = ondragover or buffer[y][x].ondragover
			buffer[y][x].ondragend = ondragend or buffer[y][x].ondragend
		end
	end
	
	ctx.getPixel = function(x, y)
		return buffer[y] and buffer[y][x] or {}
	end
	
	ctx.clear = function(color)
		checkInitialized()
		contextColor = color or internals.CONFIG.defaultBackgroundColor
		buffer = {}
		
		defaultFunctions.onclick = onclick
		defaultFunctions.onrelease = onrelease
		defaultFunctions.ondragstart = ondragstart
		defaultFunctions.ondragover = ondragover
		defaultFunctions.ondragend = ondragend
	end
	ctx.setContextColor = function(color)
		contextColor = color or internals.CONFIG.defaultBackgroundColor
	end
	ctx.setColors = function(color, fg)
		internals.CONFIG.defaultBackgroundColor = color or internals.CONFIG.defaultBackgroundColor
		internals.CONFIG.defaultTextColor = fg or internals.CONFIG.defaultTextColor
		if color == -1 then internals.CONFIG.defaultBackgroundColor = nil end
		if fg == -1 then internals.CONFIG.defaultTextColor = nil end
	end
	
	ctx.setClickFunction = function(f)
		onclick = f
	end
	ctx.getClickFunction = function(f)
		return f
	end
	
	ctx.setPixelsVisible = function(b)
		charVisible = true
		if not b then charVisible = nil end
	end
	
	ctx.emptyBuffer = function()
		buffer = {}
	end
	ctx.setBuffer = function(b)
		buffer = {}
	end
	ctx.getBuffer = function()
		return buffer
	end
	ctx.drawBuffer = function(x, y, l, h)
		ctx.parent.drawData(ctx.getData(x, y, l, h))
	end
	ctx.getData = function(px, py, l, h)
		px, py = px or 0, py or 0
		l, h = l or ctx.width, h or ctx.height
		local data = {x=ctx.position.x+px, y=ctx.position.y+py}
		for y=0, h-1 do
			local by = y+ctx.scroll.y+py
			data[y] = {}
			for x=0, l-1 do
				local bx = x+ctx.scroll.x+px
				data[y][x] = {}
				if buffer[by] and buffer[by][bx] then
					data[y][x] = {buffer[by][bx].char, buffer[by][bx].background or contextColor, buffer[by][bx].foreground or 15}
				else
					data[y][x] = {" ", contextColor}
				end
			end
		end
		
		return data
	end
	
	local function getT(t)
		return function(n, e)
            local x = e.x-ctx.position.x-ctx.scroll.x
    		local y = e.y-ctx.position.y-ctx.scroll.y
    		if x>=0 and x<ctx.width and y>=0 and y<ctx.height then
				local e = {
					x = x, y = y,
					button = e.button,
					display = e.display,
					process = es,
					context = ctx,
					originevent = e.originevent or e
				}
    			if buffer[y] and buffer[y][x] and buffer[y][x][t] then
    				buffer[y][x][t](t, e)
				elseif defaultFunctions[t] then
					defaultFunctions[t](t, e)
    			end
    		end
	   end
	end
	local function linkT(en, t)
		t = t or en
		es.addEventListener(en, getT(t))
	end
	
	linkT("mouse_click", "onclick")
	linkT("mouse_up", "onrelease")
	linkT("mouse_drag", "ondragover")
	
	ctx.triggers = {
		onclick = getT("onclick"),
		onrelease = getT("onrelease"),
		ondragover = getT("ondragover")
	}
	
	return ctx
end
bctx.getContext = function(p, x, y, l, h, es)
	return bctx.wrapContext(contextapi.getContext(p, x, y, l, h), es)
end