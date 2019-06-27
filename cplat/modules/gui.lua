--TODO: Only support graphical and hybrid applications
--TODO: Support 8-bit depth
--TODO: Cool idea, keep a cursor and return it on draw functions
--TODO: Co-ord bounce: checks coordinate locations of one context relative to another context

local cplat = require()
local environment = cplat.require "environment"
local ctxu = cplat.require "contextutils"
--local debugger = cplat.require "debugger"

local natives = environment.getNatives()

local isCC = environment.is("CC")
local isOC = environment.is("OC")

local defaultContext = cplat.getAppInfo().CONTEXT

local gui = ...
local contextAPI = {}
local drawFunctions = {}

local null_ref, term_current, term_native = {}, {}, {}

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
local displays, displays2 = {}, {}
if isCC then displays = {term_current, term_native} end
local function putDisplay(d)
	if not displays2[d] then
		table.insert(displays, d)
		displays2[d] = true
	end
end
gui.getDisplays = function()
	if isCC then
		for k, v in pairs(natives.peripheral.getNames()) do
			if not displays2[v] and natives.peripheral.getType(v) == "monitor" then
				table.insert(displays, v)
				displays2[v] = true
			end
		end
		return displays
	elseif isOC then
		local component = natives.require("component")
		local gpu = component.proxy(component.list("gpu", true)())
		if not gpu then 
			displays[1] = null_ref
			return displays
		end
		
		local s = gpu.getScreen()
		displays[1] = s or null_ref --Do not register with displays2
		for addr in component.list("screen") do
			putDisplay(addr)
		end
		return displays
	end
end
gui.getDefaultDisplayID = function()
	return 1
end
gui.getTotalDisplays = function()
	return #gui.getDisplays()
end
gui.checkDisplayAvailable = function(id)

end

gui.getDefaultContext = function(term)
	return defaultContext or gui.getNativeContext(term)
end
gui.getNativeContext = function(term)
	term = term or gui.getDisplay(gui.getDefaultDisplayID())
	if isCC then
		local dumbTerm = { --This will need updated to track stuff later on
			setCursorPos = function() end,
			setBackgroundColor = function() end,
			setTextColor = function() end,
			getCursorPos = function() return 0, 0 end,
			getBackgroundColor = function() return 0 end,
			getTextColor = function() return 2^15 end,
			isColor = function() return false end,
			write = function() end,
		}
		xpcall(function()
			if term == term_current then
				term = natives.term.current()
			elseif term == term_native then
				term = natives.term.native()
			elseif term then
				term = natives.peripheral.wrap(term)
			end
		end, function() term = dumbTerm end)
	
		local ctx = gui.getContext(term, 0, 0, 0, 0)
		ctx.INTERNALS2.isNative = true
		ctx.INTERNALS2.enableOptimizations = false
		ctx.drawPixel = function(x, y, color, char, fg)
			checkInitialized(ctx)
			
			char = char and tostring(char)
			color = color or ctx.currentBackgroundColor
			fg = fg or ctx.currentTextColor
			
			x, y = x-ctx.scroll.x, y-ctx.scroll.y
			
			x = (ctx.INTERNALS2.xinverted and ctx.WIDTH-x-1) or x
			
			if ctx.INTERNALS2.isColor then
				term.setBackgroundColor(2^(color or ctx.CONFIG.defaultBackgroundColor))
				term.setTextColor(2^(fg or ctx.CONFIG.defaultTextColor))
			end
			
			term.setCursorPos(x+1, y+1)
			term.write(char or " ")
		end
		ctx.blit = function(x, y, str, bstr, fstr)
			x, y = x-ctx.scroll.x, y-ctx.scroll.y
			
			if ctx.INTERNALS2.xtinverted then
				str = ctxu.reverseTextX(str)
				bstr = ctxu.reverseTextX(bstr)
				fstr = ctxu.reverseTextX(fstr)
				x=ctx.WIDTH-x-#str
			end
			if ctx.INTERNALS2.xinverted then
				str = ctxu.reverseTextX(str)
				bstr = ctxu.reverseTextX(bstr)
				fstr = ctxu.reverseTextX(fstr)
				x=ctx.WIDTH-x-#str
			end
			
			term.setCursorPos(x+1, y+1)
			local built1, built2, built3 = "", "", ""
			while #str>0 do
				if not tonumber(bstr:sub(1, 1), 16) then
					local x, y = term.getCursorPos()
					term.setCursorPos(x+1, y)
				else
					built1 = built1..str:sub(1, 1)
					built2 = built2..bstr:sub(1, 1)
					built3 = built3..fstr:sub(1, 1)
				end
				str, bstr, fstr = str:sub(2), bstr:sub(2), fstr:sub(2)
				if not tonumber(bstr:sub(1, 1), 16) then
					term.blit(built1, built3:lower(), built2:lower())
					built1, built2, built3 = "","",""
				end
			end
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
			ctx.INTERNALS2.isColor = ctx.INTERNALS2.enableColor and term.isColor()
		end
		ctx.setAutoSize = function()
			error("Cannot set autosize on native conext")
		end
		ctx.endDraw = function()
			checkCanEndDraw(ctx)
			term.setCursorPos(ctx.INTERNALS.pos.x, ctx.INTERNALS.pos.y)
			if ctx.INTERNALS2.isColor then
				term.setBackgroundColor(ctx.INTERNALS.theme.bg)
				term.setTextColor(ctx.INTERNALS.theme.fg)
			end
		end
		ctx.update()
		return ctx
	elseif isOC then
		local dumbTerm = {
			getSize = function() return 0, 0 end,
			getSimulated = function() return true end
		}
		
		local ctx
		xpcall(function()
			assert(term~=null_ref)
			local component = natives.require("component")
			local gpu = assert(component.proxy(component.list("gpu", true)()))
			term = { --TODO: Handle removed gpu/monitor
				getSize = function() return gpu.getViewport() end,
				getSimulated = function() return not gpu or not gpu.getScreen() end,
				setBackground = function(color)
					if color>15 then error("Extended pallete coming at a later time", 3) end
					if gpu then pcall(gpu.setBackground, color, true) end
				end, 
				setForeground = function(color)
					if color>15 then error("Extended pallete coming at a later time", 3) end
					if gpu then pcall(gpu.setForeground, color, true) end
				end,
				set = function(x, y, t, v)
					if gpu then pcall(gpu.set, x, y, t, v) end
				end,
				address = term,
				gpu = gpu
			}
		end, function() term = dumbTerm end)
		
		local ctx = gui.getContext(term, 0, 0, 0, 0)
		ctx.INTERNALS2.isNative = true
		ctx.INTERNALS2.enableOptimizations = false
		local gpu, addr = term.gpu, term.address
		ctx.drawPixel = function(x, y, color, char, fg)
			checkInitialized(ctx)
			if term.getSimulated() then return end
			
			char = char and tostring(char)
			color = color or ctx.currentBackgroundColor
			fg = fg or ctx.currentTextColor
			
			x, y = x-ctx.scroll.x, y-ctx.scroll.y
			
			x = (ctx.INTERNALS2.xinverted and ctx.WIDTH-x-1) or x
			
			if ctx.INTERNALS2.isColor then
				term.setBackground(color or ctx.CONFIG.defaultBackgroundColor)
				term.setForeground(fg or ctx.CONFIG.defaultTextColor)
			end
			term.set(x+1, y+1, char or " ")
		end
		ctx.drawFilledRect = function(x, y, l, h, color, char, fg)
			checkInitialized(ctx)
			if term.getSimulated() then return end
			
			if not l or not h or l<1 or h<1 then error("Invalid dimensions", 2) end
			
			char = char and tostring(char)
			color = color or ctx.currentBackgroundColor
			fg = fg or ctx.currentTextColor
			
			x, y = x-ctx.scroll.x, y-ctx.scroll.y
			
			x = (ctx.INTERNALS2.xinverted and ctx.WIDTH-x-l) or x
			
			
			if ctx.INTERNALS2.isColor then
				term.setBackground(color or ctx.CONFIG.defaultBackgroundColor)
				term.setForeground(fg or ctx.CONFIG.defaultTextColor)
			end
			gpu.fill(x+1, y+1, l, h, char or " ")
		end
		ctx.blit = function(x, y, str, bstr, fstr)
			checkInitialized(ctx)
			if term.getSimulated() then return end
			
			x, y = x-ctx.scroll.x, y-ctx.scroll.y
			if ctx.INTERNALS2.xtinverted then
				str = ctxu.reverseTextX(str)
				bstr = ctxu.reverseTextX(bstr)
				fstr = ctxu.reverseTextX(fstr)
			end
			if ctx.INTERNALS2.xinverted then
				str = ctxu.reverseTextX(str)
				bstr = ctxu.reverseTextX(bstr)
				fstr = ctxu.reverseTextX(fstr)
				x=ctx.WIDTH-x-#str
			end
			
			local builtstr, bcol, fcol = "", "", ""
			local ni = 0
			local function blitIf()
				local nbc, nfc = bstr:sub(1, 1), fstr:sub(1, 1)
				if nbc~=bcol or nfc~=fcol then
					if bcol and (bcol~=" ") and (bcol~="") then
						if ctx.INTERNALS2.isColor then
							term.setBackground(tonumber(bcol, 16) or 0)
							term.setForeground(tonumber(fcol, 16) or 15)
						end
						term.set(x+ni+1, y+1, builtstr)
					end
					ni = ni+#builtstr
					builtstr, bcol, fcol = "", nbc, nfc
				end
			end
			while #str>0 do
				blitIf()
				builtstr = builtstr..str:sub(1, 1)
				
				str, bstr, fstr = str:sub(2), bstr:sub(2), fstr:sub(2)
			end
			blitIf()
		end
		ctx.drawData = function(data)
			local trimmedData = {} --Should be squared
			for y=0, #data do
				trimmedData[y] = {}
				for x=0, #data[y] do
					trimmedData[y][x] = {processed = false, data[y][x][1],data[y][x][2],data[y][x][3]}
				end
			end
			local space = {[" "] = true, ["\t"] = true}
			local groups = {}
			local function checkEligible(x, y, bg, fg)
				return
					trimmedData[y] and
					trimmedData[y][x] and
					trimmedData[y][x][1] and
					(trimmedData[y][x][2] == bg or not bg) and
					(trimmedData[y][x][3] == fg or not fg or space[trimmedData[y][x][1]]) and
					trimmedData[y][x][1] ~= ""
			end
			for y=0, #trimmedData do
				for x=0, #trimmedData[y] do
					if not trimmedData[y][x].processed then
						local pointsH, pointsV = 0, 0
						local lengthH, heightV = 0, 0
						local textH, textV = "", ""
						local bgH, fgH, bgV, fgV
						while checkEligible(x+lengthH, y, bgH, fgH) do
							if not trimmedData[y][x+lengthH].processed then
								pointsH = pointsH+1
							end
							textH = textH..trimmedData[y][x+lengthH][1]
							bgH = bgH or trimmedData[y][x+lengthH][2]
							fgH = fgH or trimmedData[y][x+lengthH][3]
							lengthH = lengthH+1
						end
						while checkEligible(x, y+heightV, bgV, fgV) do
							if not trimmedData[y+heightV][x].processed then
								pointsH = pointsH+1
							end
							textV = textV..trimmedData[y+heightV][x][1]
							bgV = bgV or trimmedData[y+heightV][x][2]
							fgV = fgV or trimmedData[y+heightV][x][3]
							heightV = heightV+1
						end
						local textm, bgm, fgm
						if pointsV>pointsH then
							textm, bgm, fgm = textV, bgV, fgV
							for y2=0, heightV-1 do
								trimmedData[y+y2][x].processed = true
							end
						else
							textm, bgm, fgm = textH, bgH, fgH
							for x2=0, lengthH-1 do
								trimmedData[y][x+x2].processed = true
							end
						end
						bgm, fgm = bgm or 0, fgm or 15
						groups[bgm] = groups[bgm] or {}
						groups[bgm][fgm] = groups[bgm][fgm] or {}
						table.insert(groups[bgm][fgm], {
							x=x, y=y,
							text = textm,
							vertical = pointsV>pointsH,
						})
					end
				end
			end
			for bg, fgs in pairs(groups) do
				term.setBackground(bg or 0)
				for fg, gps in pairs(fgs) do
					term.setForeground(fg or 15)
					for id, dat in pairs(gps) do
						term.set(dat.x+1, dat.y+1, dat.text, dat.vertical)
					end
				end
			end
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
			
			ctx.INTERNALS = {
				drawing=true,
				depth = depth,
				screen = oscreen,
				theme = {bg=ob, fg=of}
			}
			
			ctx.update()
		end
		ctx.update = function()
			if term.getSimulated() then return end
			ctx.WIDTH, ctx.HEIGHT = term.getSize()
			ctx.INTERNALS2.isColor = ctx.INTERNALS2.enableColor and pcall(gpu.setDepth, 4)
		end
		ctx.setAutoSize = function()
			error("Cannot set autosize on native conext")
		end
		ctx.endDraw = function()
			checkCanEndDraw(ctx)
			ctx.INTERNALS.drawing = false

			if term.getSimulated() then return end
			gpu.bind(ctx.INTERNALS.screen, false)
			pcall(gpu.setDepth, ctx.INTERNALS.depth)
			if ctx.INTERNALS2.isColor then
				term.setBackground(ctx.INTERNALS.theme.bg)
				term.setForeground(ctx.INTERNALS.theme.fg)
			end
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
		position = {x=x or 0,y=y or 0},
		scroll = {x=0, y=0},
		WIDTH = l or (parent and parent.WIDTH),
		HEIGHT = h or (parent and parent.HEIGHT),
		hasColor = true,
		parent = parent,
		INTERNALS = {},
		INTERNALS2 = {
			isNative = false,
			enableOptimizations = true,
			enableColor = true,
			useParentWidth = not l,
			useParentHeight = not h,
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
	x, y = x-ctx.scroll.x, y-ctx.scroll.y
	x = (ctx.INTERNALS2.xinverted and ctx.WIDTH-x-1) or x
	if (x>0 and (not ctx.WIDTH or x<ctx.WIDTH)) and (y>0 and (not ctx.HEIGHT or y<ctx.HEIGHT)) then
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
		x, y = x-ctx.scroll.x, y-ctx.scroll.y
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
		x, y = x-ctx.scroll.x, y-ctx.scroll.y
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
contextAPI.blit = function(ctx, x, y, str, bstr, fstr)
	if ctx.INTERNALS2.xtinverted then
		str = ctxu.reverseTextX(str)
		bstr = ctxu.reverseTextX(bstr)
		fstr = ctxu.reverseTextX(fstr)
	end
	if ctx.enableOptimizations then
		if y>ctx.HEIGHT then return end
		x, y = x-ctx.scroll.x, y-ctx.scroll.y
		if ctx.INTERNALS2.xinverted then
			str = ctxu.reverseTextX(str)
			bstr = ctxu.reverseTextX(bstr)
			fstr = ctxu.reverseTextX(fstr)
			x=ctx.WIDTH-x-#str
		end
		str = str:sub(1, ctx.WIDTH-x)
		bstr = bstr:sub(1, ctx.WIDTH-x)
		fstr = fstr:sub(1, ctx.WIDTH-x)
		ctx.parent.blit(x+ctx.position.x, y+ctx.position.y, str, bstr, fstr)
	else
		fstr = fstr:gsub(" ", "F")
		for i=1, #str do
			if bstr:sub(i, i) ~= " " then
				local bg = tonumber(bstr:sub(i,i), 16) or 0
				local fg = tonumber(fstr:sub(i,i), 16) or 15
				ctx.drawPixel(x+i-1, y, bg, str:sub(i, i), fg)
			end
		end
	end
end
contextAPI.drawData = function(ctx, data)
	--TODO: Canvas inversion
	if ctx.INTERNALS2.enableOptimizations and ctx.parent.drawData then
		local trimmedData = {x=data.x, y=data.y}
		for y=0, #data do
			if y+trimmedData.y>=ctx.HEIGHT then break end
			trimmedData[y] = {}
			for x=0, #data[y] do
				if x+trimmedData.x>=ctx.WIDTH then break end
				trimmedData[y][x] = {table.unpack(data[y][x])}
			end
		end
		ctx.parent.drawData(trimmedData)
	else
		for y=0, #data do
			for x=0, #data[y] do
				if data[y][x][1] and data[y][x][2] then
					ctx.drawPixel(x+data.x, y+data.y, data[y][x][2], data[y][x][1], data[y][x][3] or 15)
				end
			end
		end
	end
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

contextAPI.isColor = function(ctx)
	return ctx.INTERNALS2.isColor
end

for k, v in pairs(contextAPI) do drawFunctions[k] = v end

contextAPI.update = function(ctx)
	ctx.WIDTH = (ctx.INTERNALS2.useParentWidth and ctx.parent and ctx.parent.WIDTH) or ctx.WIDTH
	ctx.HEIGHT = (ctx.INTERNALS2.useParentHeight and ctx.parent and ctx.parent.HEIGHT) or ctx.HEIGHT
	ctx.INTERNALS2.isColor = ctx.parent.INTERNALS2.isColor and ctx.INTERNALS2.enableColor
end
contextAPI.setAutoSize = function(ctx, w, h)
	if w~=nil then
		ctx.useParentWidth = w
	end
	if h~=nil then
		ctx.useParentHeight = h
	end
end
contextAPI.setScroll = function(ctx, x, y)
	if type(x) == "table" then x, y = x[1], x[2] end
	ctx.scroll.x = x or ctx.scroll.x
	ctx.scroll.y = y or ctx.scroll.y
end
contextAPI.adjustScroll = function(ctx, x, y)
	if type(x) == "table" then x, y = x[1], x[2] end
	ctx.scroll.x = ctx.scroll.x + (x or 0)
	ctx.scroll.y = ctx.scroll.y + (y or 0)
end
contextAPI.getScroll = function(ctx, t)
	if t then return ctx.scroll[t] end
	return {ctx.scroll.x, ctx.scroll.y}
end

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