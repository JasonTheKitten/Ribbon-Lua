--TODO: Track updated pixels
--TODO: Add a Z buffer
--TODO: Scroll

local cplat = require()

local gui = cplat.require "gui"

local bctx = ...

bctx.wrapContext = function(ctx, es)
	if not (ctx and es) then error("Arguments should be ctx, es", 2) end
	
	if ctx.INTERNALS2.isNative then
		error("A buffered context can not be created with a native context; Please use gui.getContext to wrap the native context.", 2)
	end
	ctx.INTERNALS2.enableOptimizations = false
	
	local function checkInitialized()
		if not ctx.INTERNALS.drawing then
			error("Attempt to use context while not drawing", 3)
		end
	end

	local buffer = {}
	local charVisible, contextColor = true, nil
	local onclick, onrelease, ondragstart, ondragover, ondragend
	

	ctx.INTERNALS2.optimizationsEnabled = false
	ctx.drawPixel = function(x, y, color, char, fg)
		char = char and charVisible and tostring(char)
		x = (ctx.INTERNALS2.xinverted and ctx.WIDTH-x-1) or x
		if x>=0 and y>=0 then
			buffer[y] = buffer[y] or {}
			buffer[y][x] = buffer[y][x] or {}
			buffer[y][x].char = char or buffer[y][x].char
			buffer[y][x].foreground = fg or buffer[y][x].foreground
			buffer[y][x].background = color or buffer[y][x].background
			buffer[y][x].onclick = onclick or buffer[y][x].onclick
			buffer[y][x].onrelease = onrelease or buffer[y][x].onrelease
			buffer[y][x].ondragstart = ondragstart or buffer[y][x].ondragstart
			buffer[y][x].ondragover = ondragover or buffer[y][x].ondragover
			buffer[y][x].ondragend = ondragend or buffer[y][x].ondragend
		end
	end
	
	ctx.clear = function(color)
		contextColor = color
		buffer = {}
	end
	ctx.setContextColor = function(color)
		contextColor = color
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
	ctx.drawBuffer = function()
		ctx.parent.drawData(ctx.getData())
	end
	ctx.getData = function()
		local data = {x=ctx.position.x, y=ctx.position.y}
		for y=0, ctx.HEIGHT-1 do
			data[y] = {}
			for x=0, ctx.WIDTH-1 do
				data[y][x] = {}
				if buffer[y] and buffer[y][x] then
					data[y][x] = {buffer[y][x].char, buffer[y][x].background or 0, buffer[y][x].foreground or 15}
				else
					data[y][x] = {" ", contextColor}
				end
			end
		end
		
		return data
	end
	
	local function linkT(e, t)
		es.addEventListener(e, function(e)
            local x = e.x-ctx.position.x-ctx.scroll.x
    		local y = e.y-ctx.position.y-ctx.scroll.y
    		if x>=0 and x<ctx.WIDTH and y>=0 and y<ctx.HEIGHT then
    			if buffer[y] and buffer[y][x] and buffer[y][x][t] then
    				buffer[y][x][t]({
    					x = x,
    					y = y,
    					button = e.button
    				})
    			end
    		end
	   end)
	end
	
	linkT("mouse_click", "onclick")
	linkT("mouse_up", "onrelease")
	linkT("mouse_drag", "ondragover")
	
	return ctx
end
bctx.getContext = function(p, x, y, l, h, es)
	return bctx.wrapContext(gui.getContext(p, x, y, l, h), es)
end