--TODO: Only support graphical and terminal applications
--TODO: Cool idea, keep a cursor and return it on draw functions
--TODO: Thick Empty Rects
--TODO: Co-ord bounce: checks coordinate locations of one context relative to another context
--TODO: Use actual addresses

local cplat = require()
local environment = cplat.require "environment"
local ctxu = cplat.require "contextutils"

local natives = environment.getNatives()

local isCP = environment.is("CP")
local isCC = environment.is("CC")
local isOC = environment.is("OC")

local defaultContext = cplat.getAppInfo().CONTEXT

local gui = ...
local contextAPI = {}
local drawFunctions = {}

local function checkInitialized(context)
	if not context.INTERNALS.drawing then
		error("Attempt to use context while not drawing", 3)
	end
end
local function checkCanStartDraw(context)
	if context.INTERNALS.drawing then
		error("Cannot start drawing: already drawing", 3)
	end
end
local function checkCanEndDraw(context)
	if not context.INTERNALS.drawing then
		error("Cannot stop drawing: already not drawing", 3)
	end
end

gui.getDisplay = function(id)
	return gui.getDisplays()[id or 1]
end
gui.getDisplays = function()
	if isCP then
		return natives.require("gui").getDisplays()
	elseif isCC then
		local displays = {natives.term.current(), natives.term.native()}
		for k, v in pairs(natives.peripheral.getNames()) do
			if natives.peripheral.getType(v) == "monitor" then
				table.insert(displays, natives.peripheral.wrap(v))
			end
		end
		return displays
	elseif isOC then
		local screens = {}
		local dumbHandle = {
			getSize = function() return 0, 0 end,
			getSimulated = function() return true end
		}
		local component = natives.require("component")
		local gpu = component.proxy(component.list("gpu", true)())
		if not gpu then
			screens[1] = dumbHandle
			return screens
		end
		local function addAddr(addr)
			table.insert(screens, {
				getSize = function() return gpu.getResolution() end,
				getSimulated = function() return false end,
				address = addr,
				gpu = gpu
			})
		end
		if gpu.getScreen() then addAddr(gpu.getScreen()) end
		for addr in component.list("screen") do
			addAddr(addr)
		end
		screens[1] = screens[1] or dumbHandle
		return screens
	end
end
gui.getDefaultDisplayID = function()
	return 1
end
gui.getTotalMDisplays = function()
	return #gui.getDisplays()
end

gui.getDefaultContext = function(term)
	return defaultContext or gui.getNativeContext(term)
end
gui.getNativeContext = function(term)
	term = term or gui.getDisplay(1)
	if isCP then
		return natives.getDefaultContext(term)
	elseif isCC then
		local ctx = gui.getContext(term, 0, 0, 0, 0)
		ctx.drawPixel = function(x, y, color, char, fg)
			checkInitialized(ctx)
			
			char = char and tostring(char)
			color = color or ctx.currentBackgroundColor
			fg = fg or ctx.currentTextColor
			
			x = (ctx.INTERNALS2.xinverted and ctx.WIDTH-x-1) or x
			
			term.setBackgroundColor(2^(color or ctx.CONFIG.defaultBackgroundColor))
			term.setTextColor(2^(fg or ctx.CONFIG.defaultTextColor))
			
			term.setCursorPos(x+1, y+1)
			term.write(char or " ")
		end
		ctx.startDraw = function()
			checkCanStartDraw(ctx)
			local ox, oy = term.getCursorPos()
			local ob, of = term.getBackgroundColor(), term.getTextColor()
			ctx.INTERNALS = {
				drawing = true,
				pos = {x=ox, y=oy},
				theme = {bg=ob, fg=of}
			}
			ctx.update()
		end
		ctx.update = function()
			ctx.WIDTH, ctx.HEIGHT = term.getSize()
		end
		ctx.endDraw = function()
			checkCanEndDraw(ctx)
			term.setCursorPos(ctx.INTERNALS.pos.x, ctx.INTERNALS.pos.y)
			term.setBackgroundColor(ctx.INTERNALS.theme.bg)
			term.setTextColor(ctx.INTERNALS.theme.fg)
		end
		return ctx
	elseif isOC then
		local ctx = gui.getContext(term, 0, 0, 0, 0)
		local gpu, addr = term.gpu, term.address
		ctx.drawPixel = function(x, y, color, char, fg)
			checkInitialized(ctx)
			if term.getSimulated() then return end
			
			char = char and tostring(char)
			color = color or ctx.currentBackgroundColor
			fg = fg or ctx.currentTextColor
			
			x = (ctx.INTERNALS2.xinverted and ctx.WIDTH-x-1) or x
			
			gpu.setBackground(color or ctx.CONFIG.defaultBackgroundColor, true)
			gpu.setForeground(fg or ctx.CONFIG.defaultTextColor, true)
			gpu.set(x+1, y+1, char or " ")
		end
		ctx.drawFilledRect = function(x, y, l, h, color, char, fg)
			checkInitialized(ctx)
			if term.getSimulated() then return end
			
			if not l or not h or l<1 or h<1 then error("Invalid dimensions", 2) end
			
			char = char and tostring(char)
			color = color or ctx.currentBackgroundColor
			fg = fg or ctx.currentTextColor
			
			x = (ctx.INTERNALS2.xinverted and ctx.WIDTH-x-l) or x
			
			
			gpu.setBackground(color or ctx.CONFIG.defaultBackgroundColor, true)
			gpu.setForeground(fg or ctx.CONFIG.defaultTextColor, true)
			gpu.fill(x+1, y+1, l, h, char or " ")
		end
		ctx.startDraw = function()
			checkCanStartDraw(ctx)
			if term.getSimulated() then 
				ctx.INTERNALS.drawing = true 
				return 
			end
			
			local ob, of = gpu.getBackground(), gpu.getForeground()
			local depth = gpu.getDepth()
			local oscreen = gpu.getScreen()
			
			local shouldBind = addr~=oscreen
			if shouldBind then gpu.bind(addr, false) end
			
			gpu.setDepth(4) --TODO: What if depth "4" is not supported!? Then what!
			
			ctx.INTERNALS = {
				drawing=true,
				depth = depth,
				screen = oscreen,
				theme = {bg=ob, fg=of}
			}
			
			ctx.update()
		end
		ctx.update = function()
			ctx.WIDTH, ctx.HEIGHT = term.getSize()
		end
		ctx.endDraw = function()
			checkCanEndDraw(ctx)
			ctx.INTERNALS.drawing = false
			if term.getSimulated() then return end
			if shouldBind then gpu.bind(ctx.INTERNALS.screen, false) end
			gpu.setDepth(ctx.INTERNALS.depth)
			gpu.setBackground(ctx.INTERNALS.theme.bg)
			gpu.setForeground(ctx.INTERNALS.theme.fg)
		end
		return ctx
	end
end
gui.setDefaultContext = function(ctx)
	if ctx == "native" then
		defaultContext = nil
	elseif ctx then
		defaultContext = ctx
	else
		defaultContext = cplat.getAppInfo().CONTEXT
	end
end
gui.getContext = function(parent, x, y, l, h)
	local context = {
		position = {x=x,y=y},
		WIDTH = l,
		HEIGHT = h,
		hasColor = true,
		parent = parent,
		INTERNALS = {},
		INTERNALS2 = {
			enableOptimizations = true,
			xinverted = false,
		},
		CONFIG = {
			defaultBackgroundColor = 12,
			defaultTextColor = 5
		}
	}
	for k, v in pairs(contextAPI) do
		context[k] = function(...)
			v(context, ...)
		end
	end
	for k, v in pairs(drawFunctions) do
		context[k] = function(...)
			checkInitialized(context)
			v(context, ...)
		end
	end
	context.startDraw = function()
		checkCanStartDraw(context)
		context.INTERNALS.drawing = true
	end
	context.endDraw = function()
		checkCanEndDraw(context)
		context.INTERNALS.drawing = false
	end
	
	return context
end

local function checkLH(ctx, l, h)
	if not l or not h then error("Arguments missing", 4) end
	return l<1 or h<1
end

contextAPI.clear = function(ctx, color, char)
	ctx.drawFilledRect(0, 0, ctx.WIDTH, ctx.HEIGHT, color, char)
end
contextAPI.drawPixel = function(ctx, x, y, color, char, fg)
	char = char and tostring(char)
	x = (ctx.INTERNALS2.xinverted and ctx.WIDTH-x-1) or x
	if (x<ctx.WIDTH) and (y<ctx.HEIGHT) then
		ctx.parent.drawPixel(ctx.position.x+x, ctx.position.y+y, color, char, fg)
	end
end
contextAPI.drawText = function(ctx, x, y, text, color, fg)
	text = tostring(text)
	if #text==0 then return end
	if ctx.INTERNALS2.xtinverted then
		text = ctxu.reverseTextX(text)
	end
	if ctx.parent.drawText and ctx.INTERNALS2.enableOptimizations then
		if ctx.INTERNALS2.xinverted then
			text = ctxu.reverseTextX(text)
			x=ctx.WIDTH-x-ctxu.getLineLength(text)
		end
		ctx.parent.drawText(ctx.position.x+x, ctx.position.y+y, text, color, fg)
		return
	end
	local ox, oy = 0,0
	for i=1, #text do
		if text:sub(i,i)=="\n" then
			ox,oy = 0,oy+1
		else
			ctx.drawPixel(ctx.position.x+x+ox, ctx.position.y+y+oy, color, text:sub(i,i), fg)
			ox=ox+1
		end
	end
end
contextAPI.drawFilledRect = function(ctx, x, y, l, h, color, char, fg)
	if checkLH(ctx, l, h) then return end
	char = char and tostring(char)
	if ctx.parent.drawFilledRect and ctx.INTERNALS2.enableOptimizations then
		x = (ctx.INTERNALS2.xinverted and ctx.WIDTH-x-l) or x
		ctx.parent.drawFilledRect(ctx.position.x+x, ctx.position.y+y, l, h, color, char, fg)
		return
	end
	for ox=0, l-1 do
		for oy=0, h-1 do
			ctx.drawPixel(x+ox, y+oy, color, char, fg)
		end
	end
end
contextAPI.drawEmptyRect = function(ctx, x, y, l, h, color, char, fg)
	if checkLH(ctx, l, h) then return end
	char = char and tostring(char)
	for ox=0, l-1 do
		ctx.drawPixel(x+ox, y, color, char, fg)
		ctx.drawPixel(x+ox, y+h-1, color, char, fg)
	end
	for oy=0, h-1 do
		ctx.drawPixel(x, y+oy, color, char, fg)
		ctx.drawPixel(x+l-1, y+oy, color, char, fg)
	end
end
contextAPI.drawTextBox = function(ctx, x, y, text, color, fg, meta)
	text = tostring(text)
	text = text:gsub("\t", "  ")
	
	meta = meta or {}
	meta.width = meta.width or ctxu.getLineLength(text)
	meta.height = meta.height or ctxu.getLines(text)
	meta.fillChar = meta.fillChar or " "
	meta.fillTextColor = meta.fillTextColor or fg
	
	ctx.drawFilledRect(x, y, meta.width, meta.height, color, meta.fillChar, meta.fillTextColor)
	ctx.drawText(x, y, text, color, fg)
end
contextAPI.setColors = function(ctx, color, fg)
	ctx.defaultBackgroundColor = color
	ctx.defaultTextColor = fg
end
contextAPI.setTextColor = function(ctx, color)
	ctx.defaultTextColor = fg
end
contextAPI.setBackgroundColor = function(ctx, color)
	ctx.defaultBackgroundColor = color
end

for k, v in pairs(contextAPI) do drawFunctions[k] = v end

contextAPI.invertX = function(ctx)
	ctx.INTERNALS2.xinverted = not ctx.INTERNALS2.xinverted
end
contextAPI.invertY = function(ctx)
	error("ENOSUP", 2)
end
contextAPI.setInvertedX = function(ctx, v)
	ctx.INTERNALS2.xinverted = v
end
contextAPI.setInvertedY = function(ctx, v)
	error("ENOSUP", 2)
end
contextAPI.getInvertedX = function(ctx)
	return ctx.INTERNALS2.xinverted
end
contextAPI.getInvertedY = function(ctx)
	return false
end

contextAPI.invertTextX = function(ctx)
	ctx.INTERNALS2.xtinverted = not ctx.INTERNALS2.xtinverted
end
contextAPI.invertTextY = function(ctx)
	error("ENOSUP", 2)
end
contextAPI.setTextInvertedX = function(ctx, v)
	ctx.INTERNALS2.xtinverted = v
end
contextAPI.setTextInvertedY = function(ctx, v)
	error("ENOSUP", 2)
end
contextAPI.getTextInvertedX = function(ctx)
	return ctx.INTERNALS2.xtinverted
end
contextAPI.getTextInvertedY = function(ctx)
	return false
end