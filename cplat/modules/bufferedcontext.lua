--TODO: Reflect buffer using blit

local cplat = require()

local gui = cplat.require "gui"

local bctx = ...

bctx.wrapContext = function(ctx, es)
	if ctx.INTERNALS2.isNative then
		error("A buffered context can not be created with a native context; Please use gui.getContext to wrap the native context.", 2)
	end

	local buffer = {}
	local charVisible = true
	local foregrond, background
	local onclick, onrelease, ondragstart, ondragover, ondragend
	

	ctx.INTERNALS2.optimizationsEnabled = false
	ctx.setPixel = function(x, y, color, char, fg)
		char = char and charVisible and tostring(char)
		x = (ctx.INTERNALS2.xinverted and ctx.WIDTH-x-1) or x
		if x>0 and y>0 then
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
	   for y, row in pairs(buffer) do
	       for x, pixel in pairs(buffer[y]) do
	           if pixel.char then
	               ctx.parent.drawPixel(
	                   x+ctx.position.x, y+ctx.position.y,
	                   pixel.background, pixel.char, pixel.foreground)
	           end
	       end
	   end
	end
	
	local function gmf(t)
		return function(e)
            local x = e.x-buffer.x
    		local y = e.y-buffer.y
    		if x<ctx.WIDTH and y<ctx.HEIGHT then
    			if buffer[y] and buffer[y][x] and buffer[y][x][t] then
    				buffer[y][x][t]({
    					x = x,
    					y = y,
    					button = e.button
    				})
    			end
    		end
	   end
	end
	
	es.addEventListener("mouse_click", gmf("onclick"))
	es.addEventListener("mouse_up", gmf("onrelease"))
	es.addEventListener("mouse_drag", gmf("ondragover"))
	
	return ctx
end
bctx.getContext = function(p, x, y, l, h, es)
	return bctx.wrapContext(gui.getContext(p, x, y, l, h), es)
end