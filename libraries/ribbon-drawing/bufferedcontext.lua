--TODO: Track updated pixels
--TODO: Add a Z buffer

local ribbon = require()

local contextapi = ribbon.require "context"
local debugger = ribbon.require "debugger"
local util = ribbon.require "util"

local bctx = ...

local function getData(buffer, x, y, l, h)
	px, py = px or 0, py or 0
	l, h = l or buffer.width, h or buffer.height
	local scrollx, scrolly = buffer.scrollx, buffer.scrolly
	local data = {x=(buffer.x or 0)+px, y=(buffer.y or 0)+py}
	for y=0, h-1 do 
		data[y] = {}
		for x=0, l-1 do data[y][x] = {} end
	end
	for k=1, #buffer do
		local v = buffer[k]
		if v.x and v.y and v.width and v.height then
			local sy, sx
			for y=v.y, v.y+v.height-1 do
				sy = y-scrolly
				data[sy] = data[sy] or {}
				for x=v.x, v.x+v.width-1 do
					sx = x - scrollx
					data[sy][sx] = data[sy][sx] or {}
					data[sy][sx] = {
						v.char or data[sy][sx][1] or " ",
						v.background or data[sy][sx][2] or buffer.color or 0,
						v.foreground or data[sy][sx][3] or buffer.textColor or 15,
					}
				end
			end
		else
			for y=0, h-1 do 
				data[y] = data[y] or {}
				for x=0, l-1 do 
					data[y][x] = {
						v.char or data[y][x][1] or " ",
						v.background or data[y][x][2] or buffer.color or 0,
						v.foreground or data[y][x][3] or buffer.textColor or 15,
					}
				end
			end
		end
	end
	
	return data
end

bctx.wrapContext = function(ctx, es)
	if not ctx then error("Arguments should be ctx, es", 2) end
	
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
	local charVisible, contextColor, textColor = true, nil, nil
	local functions = {}
	
	ifn.drawPixel = function(x, y, color, char, fg)
		checkInitialized()
		char = char and charVisible and tostring(char)
		if x>=0 and y>=0 and x<ctx.width and y<ctx.height then
			return ifn.drawFilledRect(x, y, 1, 1, color, char, fg)
		end
	end
	ctx.drawPixel = ifn.drawPixel
	
	ifn.drawFilledRect = function(x, y, l, h, color, char, fg)
		if x>=0 and y>=0 then
			local pixel = {x=x, y=y, width=l, height=h, functions = {}}
			pixel.char = char or " "
			pixel.foreground = fg or internals.CONFIG.defaultTextColor
			pixel.background = color or internals.CONFIG.defaultBackgroundColor
			pixel.functions = util.copy(functions)
			
			table.insert(buffer, pixel)
		end
	end
	
	ctx.getPixelInfo = function(x, y, dtype, iF)
		for k, v in util.ripairs(buffer) do
			if ((iF and v.functions[dtype]) or (not iF and v[dtype])) and 
				(not v.x or (x>=v.x and (not v.width or x<v.x+v.width))) and 
				(not v.y or (y>=v.y and (not v.height or y<v.y+v.height))) then
				if iF then return v.functions[dtype] else return v[dtype] end
			end
		end
		if iF then return buffer.screen.functions[dtype] end
	end
	
	ctx.clear = function(color, fg)
		checkInitialized()
		
		contextColor = color or internals.CONFIG.defaultBackgroundColor
		textColor = fg or internals.CONFIG.defaultTextColor
		
		local screen = {functions = {}, background=contextColor}
		buffer = {screen}
		
        for k, v in pairs(functions) do
            screen.functions[k] = v
        end
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
	
	ctx.useFunctions = function(f)
	   for k, v in pairs(f) do functions[k] = v end
	end
	ctx.setFunctions = function(f)
		functions = util.copy(f)
	end
	ctx.setFunction = function(t, f)
		functions[t] = f
	end
	ctx.getFunctions = function()
		return util.copy(functions)
	end
	ctx.getFunction = function(t)
		return functions[t]
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
		buffer.x, buffer.y = ctx.position.x, ctx.position.y
		buffer.width, buffer.height = ctx.width, ctx.height
		buffer.scrollx, buffer.scrolly = ctx.scroll.x, ctx.scroll.y
		return buffer
	end
	
	ctx.drawBuffer = function(x, y, l, h)
		ctx.parent.applyBuffer(ctx.getBuffer(), x or 0, y or 0, l or ctx.width, h or ctx.height)
		--ctx.parent.drawData(ctx.getData(x, y, l, h))
	end
	
	ctx.getData = function(px, py, l, h)
		buffer.scrollx = self.scroll.x
		buffer.scrolly = self.scroll.y
		buffer.color = contextColor
		buffer.textColor = textColor
		return getData(buffer)
	end
	
	local function getT(t)
		return function(n, e)
            local x = e.x-ctx.position.x-ctx.scroll.x
    		local y = e.y-ctx.position.y-ctx.scroll.y
    		if x>=0 and x<ctx.width and y>=0 and y<ctx.height then
				local f = ctx.getPixelInfo(x, y, t, true)
				if f then f(n, {
					x = x, y = y,
					button = e.button,
					display = e.display,
					process = es,
					context = ctx,
					originevent = e.originevent or e
				}) end
    		end
	   end
	end
	local function linkT(en, t)
		t = t or en
		if es then es.addEventListener(en, getT(t)) end
	end
	
	linkT("mouse_click", "onclick")
	linkT("mouse_up", "onrelease")
	linkT("mouse_drag", "ondrag")
	
	ctx.triggers = {
		onclick = getT("onclick"),
		onrelease = getT("onrelease"),
		ondragover = getT("ondragover"),
	}
	
	return ctx
end
bctx.getContext = function(p, x, y, l, h, es)
	return bctx.wrapContext(contextapi.getContext(p, x, y, l, h), es)
end
bctx.getData = getData