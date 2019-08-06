local cplat = require()

local environment = cplat.require "environment"
local ctxu = cplat.require "contextutils"
local displayapi = cplat.require "display"
local util = cplat.require "util"

local natives = environment.getNatives()

local isCC = environment.is("CC")
local isOC = environment.is("OC")

local appinfo = cplat.getAppInfo()
local apptype = appinfo.TYPE:upper()
if apptype ~= "GRAPHICAL" and apptype ~= "HYBRID" then
	error("Unsupported application type", 3)
end
local defaultContext = appinfo.CONTEXT

local hex = {
	[0] = "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"
}

--Helper functions
local function checkCanStartDraw(internals)
	if internals.drawing then error("Cannot start drawing: already drawing", 3) end
end
local function checkCanEndDraw(internals)
	if not internals.drawing then error("Cannot stop drawing: already not drawing", 3) end
end
local function checkInitialized(internals)
	if not internals.drawing then error("Attempt to use context while not drawing", 3) end
end
local function checkLH(ctx, l, h)
	if not l or not h then error("Arguments missing", 3) end
	return l<1 or h<1
end
local function cXY(ctx, x, y, l)
	x, y = x-ctx.scroll.x, y-ctx.scroll.y
	x = (ctx.INTERNALS.xinverted and ctx.width-x-(l or 1)) or x
	return x, y
end
local runIFN = util.runIFN

--Context lib
local context = ...
context.getContext = function(parent, x, y, l, h)
	if not parent and x and y and l and h then
		error("Arguments missing", 2)
	end

	local ctx = {
		parent = parent,
		position = {x=x or 0, y=y or 0},
		scroll = {x=0, y=0},
		width = l or (parent and parent.width),
		height = h or (parent and parent.height),
	}
	local internals = {
		isNative = false,
		optimizationsEnabled = true,
		enableColor = true,
		useParentwidth = not l,
		useParentheight = not h,
		xinverted = false,
		CONFIG = {
			defaultBackgroundColor = 0,
			defaultTextColor = 15,
		}
	}
	ctx.INTERNALS = internals
	
	local pinternals = (parent and parent.INTERNALS) or {}
	local ifn, pifn = {}, pinternals.IFN or {}
	internals.IFN = ifn
	
	ctx.startDraw = function()
		checkCanStartDraw(internals)
		internals.drawing = true
	end
	ctx.endDraw = function()
		checkCanEndDraw(internals)
		internals.drawing = false
	end
	
	ctx.clear = function(color, char)
		checkInitialized(internals)
		char = char and tostring(char) or " "
		runIFN(ifn.drawFilledRect, 0, 0, ctx.width, ctx.height, color, char)
		return 0, 0
	end
	
	ctx.drawPixel = function(x, y, color, char, fg)
		char = (char and tostring(char)) or ""
		runIFN(ifn.drawPixel, x, y, color, char, fg)
		if x+1<ctx.width then return x+1, y else return 0, y+1 end
	end
	ifn.drawPixel = function(q, x, y, color, char, fg)
		checkInitialized(internals)
		x, y = cXY(ctx, x, y)
		if (x>=0 and (not ctx.width or x<ctx.width)) and (y>=0 and (not ctx.height or y<ctx.height)) then
			color = color or internals.CONFIG.defaultBackgroundColor
			fg = fg or internals.CONFIG.defaultTextColor
			q()(pifn.drawPixel, ctx.position.x+x, ctx.position.y+y, color, char, fg)
		end
	end
	
	ctx.drawText = function(x, y, text, color, fg)
		text = (text and tostring(text)) or ""
		runIFN(ifn.drawText, x, y, text, color, fg)
		if x+#text<ctx.width then return x+#text, y else return 0, y+1 end
	end
	ifn.drawText = function(q, x, y, text, color, fg)
		checkInitialized(internals)
		if internals.xtinverted then
			text = ctxu.reverseTextX(text)
		end
		text = text:sub(1, ctx.width-x)
		if #text==0 then return end
		if pifn.drawText and internals.optimizationsEnabled then
			x, y = cXY(ctx, x, y, ctxu.getLineLength(text))
			if internals.xinverted then text = ctxu.reverseTextX(text) end
			q(pifn.drawText, ctx.position.x+x, ctx.position.y+y, text, color, fg)
		else
			local ox, oy = 0,0
			for i=1, #text do
				if text:sub(i,i)=="\n" then
					ox,oy = 0,oy+1
				else
					q(ifn.drawPixel, ctx.position.x+x+ox, ctx.position.y+y+oy, color, text:sub(i,i), fg)
					ox=ox+1
				end
			end
		end
	end

	ctx.drawRect = function(x, y, l, h, fill, color, char, fg)
		if checkLH(ctx, l, h) then return end
		char = char and tostring(char) or " "
		runIFN((fill==false and ifn.drawEmptyRect) or ifn.drawFilledRect, x, y, l, h, color, char, fg)
		local nx, ny = x+l, y+h
		if nx>=ctx.width then nx, ny = 0, ny+1 end
		return nx, ny
	end
	ifn.drawFilledRect = function(q, x, y, l, h, color, char, fg)
		checkInitialized(internals)
		if pifn.drawFilledRect and internals.optimizationsEnabled then
			x, y = cXY(ctx, x, y, l)
			q(pifn.drawFilledRect, ctx.position.x+x, ctx.position.y+y, l, h, color, char, fg)
		else
			local q2 = q()
			for ox=0, l-1 do
				for oy=0, h-1 do
					q2(ifn.drawPixel, x+ox, y+oy, color, char or " ", fg)
				end
			end
		end
	end
	ifn.drawEmptyRect = function(q, x, y, l, h, color, char, fg)
		checkInitialized(internals)
		for ox=0, l-1 do
			q(ifn.drawPixel, x+ox, y, color, char, fg)
			q(ifn.drawPixel, x+ox, y+h-1, color, char, fg)
		end
		for oy=0, h-1 do
			q(ifn.drawPixel, x, y+oy, color, char, fg)
			q(ifn.drawPixel, x+l-1, y+oy, color, char, fg)
		end
	end
	
	ctx.drawTextBox = function(x, y, text, color, fg, meta)
		text = tostring(text)
		text = text:gsub("\t", "  ")
		
		meta = meta or {}
		meta.width = meta.width or ctxu.getLineLength(text)
		meta.height = meta.height or ctxu.getLines(text)
		meta.fillChar = meta.fillChar or " "
		meta.fillTextColor = meta.fillTextColor or fg
	
		runIFN(ifn.drawTextBox, x, y, text, color, fg, meta)
		
		local nx, ny = x+meta.width, y+meta.height
		if nx>=ctx.width then nx, ny = 0, ny+1 end
		return nx, ny
	end
	ifn.drawTextBox = function(q, x, y, text, color, fg, meta)
		checkInitialized(internals)
		q(ifn.drawFilledRect, x, y, meta.width, meta.height, color, meta.fillChar, meta.fillTextColor)
		q(ifn.drawText, x, y, text, color, fg)
	end
	
	ctx.blit = function(x, y, str, bstr, fstr)
		runIFN(ifn.blit, x, y, str, bstr, fstr)
		if x+#str<ctx.width then return x+#str, y else return 0, y+1 end
	end
	ifn.blit = function(q, x, y, str, bstr, fstr)
		checkInitialized(internals)
		if internals.xtinverted then
			str = ctxu.reverseTextX(str)
			bstr = ctxu.reverseTextX(bstr)
			fstr = ctxu.reverseTextX(fstr)
		end
		if pifn.blit and ctx.optimizationsEnabled then
			if y>ctx.height then return end
			x, y = cXY(ctx, x, y, #str)
			if internals.xinverted then
				str = ctxu.reverseTextX(str)
				bstr = ctxu.reverseTextX(bstr)
				fstr = ctxu.reverseTextX(fstr)
			end
			str = str:sub(1, ctx.width-x)
			bstr = bstr:sub(1, ctx.width-x)
			fstr = fstr:sub(1, ctx.width-x)
			q(pifn.blit, x+ctx.position.x, y+ctx.position.y, str, bstr, fstr)
		else
			fstr = fstr:gsub(" ", "F")
			for i=1, #str do
				if bstr:sub(i, i) ~= " " then
					local bg = tonumber(bstr:sub(i,i), 16) or 0
					local fg = tonumber(fstr:sub(i,i), 16) or 15
					q(pifn.drawPixel, x+i-1, y, bg, str:sub(i, i), fg)
				end
			end
		end
	end
	
	ctx.drawData = function(data)
		runIFN(ifn.drawData, data)
		if not data[0] then return end
		local x, y = data.x+#data[#data], data.y+#data
		if x >= ctx.width then x, y = 0, y+1 end
		return x, y
	end
	ifn.drawData = function(q, data)
		checkInitialized(internals)
		if pifn.drawData and internals.optimizationsEnabled then
			local nx, ny = cXY(ctx, data.x, data.y)
			local trimmedData = {x=nx+ctx.position.x, y=ny+ctx.position.y}
			for y=0, #data do
				if y+trimmedData.y>=ctx.height then break end
				trimmedData[y] = {}
				for x=0, #data[y] do
					if x+trimmedData.x>=ctx.width then break end
					trimmedData[y][x] = {table.unpack(data[y][x])}
				end
			end
			q(pifn.drawData, trimmedData)
		else
			q(function()util.runIFN(function(q)
				local q2 = q()
				for y=0, #data do
					if not data[y] then break end
					for x=0, #data[y] do
						if not data[y][x] then break end
						if data[y][x][1] and data[y][x][2] then
							q2(ifn.drawPixel, x+data.x, y+data.y, data[y][x][2], data[y][x][1], data[y][x][3] or 15)
							--ifn.drawPixel(nil, x+data.x, y+data.y, data[y][x][2], data[y][x][1], data[y][x][3] or 15)
						end
					end
				end
			end) end)
		end
	end
	
	ctx.setColors = function(color, fg)
		internals.CONFIG.defaultBackgroundColor = color or internals.CONFIG.defaultBackgroundColor
		internals.CONFIG.defaultTextColor = fg or internals.CONFIG.defaultTextColor
	end
	ctx.getColors = function(color, fg)
		return internals.CONFIG.defaultBackgroundColor, internals.CONFIG.defaultTextColor
	end
	
	ctx.setTextColor = function(color)
		internals.CONFIG.defaultTextColor = color or internals.CONFIG.defaultTextColor
	end
	ctx.getTextColor = function()
		return internals.CONFIG.defaultTextColor
	end
	ctx.setBackgroundColor = function(color)
		internals.CONFIG.defaultBackgroundColor = color or internals.CONFIG.defaultBackgroundColor
	end
	ctx.getBackgroundColor = function()
		return internals.CONFIG.defaultBackgroundColor
	end
	
	ctx.update = function()
		ctx.width = (internals.useParentwidth and ctx.parent and ctx.parent.width) or ctx.width
		ctx.height = (internals.useParentheight and ctx.parent and ctx.parent.height) or ctx.height
		internals.isColor = pinternals.isColor and internals.enableColor
	end
	
	ctx.setAutoSize = function(w, h)
		if w~=nil then ctx.useParentwidth = w end
		if h~=nil then ctx.useParentheight = h end
	end
	ctx.setDimensions = function(l, h)
		ctx.width = math.abs(l)
		ctx.height = math.abs(h)
	end
	ctx.setPosition = function(x, y)
		ctx.position = {x=x, y=y}
	end
	
	ctx.setScroll = function(x, y)
		if type(x) == "table" then x, y = x[1], x[2] end
		ctx.scroll.x = x or ctx.scroll.x
		ctx.scroll.y = y or ctx.scroll.y
	end
	ctx.adjustScroll = function(x, y)
		if type(x) == "table" then x, y = x[1], x[2] end
		ctx.scroll.x = ctx.scroll.x + (x or 0)
		ctx.scroll.y = ctx.scroll.y + (y or 0)
	end
	ctx.getScroll = function(t)
		if t then return ctx.scroll[t] end
		return {ctx.scroll.x, ctx.scroll.y}
	end

	ctx.invertX = function() internals.xinverted = not internals.xinverted end
	ctx.setInvertedX = function(v) internals.xinverted = v end
	ctx.getInvertedX = function() return internals.xinverted end
	
	ctx.invertY = function() error("ENOSUP", 2) end
	ctx.setInvertedY = function(v) error("ENOSUP", 2) end
	ctx.getInvertedY = function() return false end

	ctx.invertTextX = function() internals.xtinverted = not internals.xtinverted end
	ctx.setTextInvertedX = function(v) internals.xtinverted = v end
	ctx.getTextInvertedX = function() return internals.xtinverted end
	
	ctx.invertTextY = function() error("ENOSUP", 2) end
	ctx.setTextInvertedY = function(v) error("ENOSUP", 2) end
	ctx.getTextInvertedY = function() return false end
	
	return ctx
end

context.getNativeContext = function(display)
	local ctx = context.getContext(nil, 0, 0)
	local internals = ctx.INTERNALS
	local ifn = ctx.INTERNALS.IFN
	internals.isNative, internals.optimizationsEnabled = true, false
	if isCC then
		local function resolveDisplay()
			if display == displayapi.term_current then
				return natives.term.current()
			elseif display == displayapi.term_native then
				return natives.term.native()
			else
				return natives.peripheral.wrap(display)
			end
		end
		local term
		term = {
			getSimulated = function() 
				local disp = resolveDisplay()
				return not (disp and pcall(disp.isColor))
			end,
			getSize = function()
				if term.getSimulated() then return 0, 0 end
				return resolveDisplay().getSize()
			end
		}
		setmetatable(term, {__index=function(t, k)
			return rawget(t, k) or function(...)
				local args = {...}
				local res = {pcall(function()
					return resolveDisplay()[k](table.unpack(args))
				end)}
				if res[1] then return table.unpack(res, 2) end
			end
		end})
		
		if natives.term.blit then
			ifn.blit = function(q, x, y, str, bstr, fstr)
				checkInitialized(internals)
				if term.getSimulated() then return end
				
				x, y = x-ctx.scroll.x, y-ctx.scroll.y
				if internals.xtinverted then
					str = ctxu.reverseTextX(str)
					bstr = ctxu.reverseTextX(bstr)
					fstr = ctxu.reverseTextX(fstr)
				end
				if internals.xinverted then
					str = ctxu.reverseTextX(str)
					bstr = ctxu.reverseTextX(bstr)
					fstr = ctxu.reverseTextX(fstr)
					x=ctx.width-x-#str
				end
				term.setCursorPos(x+1, y+1)
				term.blit(str, fstr:gsub(" ", "0"), bstr:gsub(" ", "f"))
			end
			ifn.drawData = function(q, data)
				checkInitialized(internals)
				if term.getSimulated() then return end
				
				local buffer = {}
				
				for y=0, #data do
					local by = {"", "", ""}
					for x=0, #data[y] do
						by[1] = by[1]..data[y][x][1]
						by[2] = by[2]..(hex[data[y][x][2]] or "0")
						by[3] = by[3]..(hex[data[y][x][3]] or "f")
					end
					buffer[y] = by
				end
				
				for k, v in pairs(buffer) do
					q(ifn.blit, data.x, data.y+k, buffer[k][1], buffer[k][2], buffer[k][3])
				end
			end
		end
		
		ifn.drawPixel = function(q, x, y, color, char, fg)
			checkInitialized(internals)
			if term.getSimulated() then return end
			
			char = (char and tostring(char)) or " "
			color = color or ctx.currentBackgroundColor
			fg = fg or ctx.currentTextColor
			
			x, y = x-ctx.scroll.x, y-ctx.scroll.y
			
			x = (ctx.INTERNALS.xinverted and ctx.width-x-1) or x
			
			if ctx.INTERNALS.isColor then
				term.setBackgroundColor(2^(color or internals.CONFIG.defaultBackgroundColor))
				term.setTextColor(2^(fg or internals.CONFIG.defaultTextColor))
			end
			
			term.setCursorPos(x+1, y+1)
			term.write(char)
		end
		ctx.clear = function(color, char)
			checkInitialized(internals)
			if term.getSimulated() then return end
			
			char = char and tostring(char) or " "
			if char == " " then
				term.setBackgroundColor(color or internals.CONFIG.defaultBackgroundColor)
				term.clear()
			else
				runIFN(ifn.drawFilledRect, 0, 0, ctx.width, ctx.height, color, char)
			end
			return 0, 0
		end
		ctx.startDraw = function()
			checkCanStartDraw(internals)
			local ox, oy = term.getCursorPos()
			local ob, of = term.getBackgroundColor(), term.getTextColor()
			internals.drawing = true
			internals.backup = {
				pos = {x=ox, y=oy},
				theme = {bg=ob, fg=of}
			}
			ctx.update()
		end
		ctx.update = function()
			ctx.width, ctx.height = term.getSize()
			ctx.INTERNALS.isColor = ctx.INTERNALS.enableColor and term.isColor()
		end
		ctx.setAutoSize = function()
			error("Cannot set autosize on native conext")
		end
		ctx.endDraw = function()
			checkCanEndDraw(internals)
			internals.drawing = false
			local bkp = internals.backup
			term.setCursorPos(bkp.pos.x, bkp.pos.y)
			if internals.isColor then
				term.setBackgroundColor(bkp.theme.bg)
				term.setTextColor(bkp.theme.fg)
			end
		end
	elseif isOC then
		local component = natives.require("component")
		local gpu = component.proxy(component.list("gpu", true)())
		local addr = display
		if display==displayapi.term_current then addr = gpu.getScreen() end
		local term = {
			getSimulated = function() return not gpu or not gpu.getScreen() end,
			getSize = function() if gpu then return gpu.getViewport() else return 1, 1 end end,
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
			address = display,
			gpu = gpu
		}
		setmetatable(term, {__index=function(t, k)
			return rawget(t, k) or function(...)
				if not gpu then return end
				local args = {...}
				local res = {pcall(function()
					return gpu[k](table.unpack(args))
				end)}
				if res[1] then return table.unpack(res, 2) end
			end
		end})
		
		ifn.drawPixel = function(q, x, y, color, char, fg)
			checkInitialized(internals)
			if term.getSimulated() then return end
			
			char = char and tostring(char)
			color = color or ctx.currentBackgroundColor
			fg = fg or ctx.currentTextColor
			
			x, y = x-ctx.scroll.x, y-ctx.scroll.y
			
			x = (internals.xinverted and ctx.width-x-1) or x
			
			if internals.isColor then
				term.setBackground(color or internals.CONFIG.defaultBackgroundColor)
				term.setForeground(fg or internals.CONFIG.defaultTextColor)
			end
			term.set(x+1, y+1, char or " ")
		end
		ifn.drawFilledRect = function(q, x, y, l, h, color, char, fg)
			checkInitialized(internals)
			if term.getSimulated() then return end
			
			if not l or not h or l<1 or h<1 then error("Invalid dimensions", 2) end
			
			char = char and tostring(char)
			color = color or ctx.currentBackgroundColor
			fg = fg or ctx.currentTextColor
			
			x, y = x-ctx.scroll.x, y-ctx.scroll.y
			
			x = (internals.xinverted and ctx.width-x-l) or x
			
			
			if internals.isColor then
				term.setBackground(color or internals.CONFIG.defaultBackgroundColor)
				term.setForeground(fg or internals.CONFIG.defaultTextColor)
			end
			gpu.fill(x+1, y+1, l, h, char or " ")
		end
		ifn.blit = function(q, x, y, str, bstr, fstr)
			checkInitialized(internals)
			if term.getSimulated() then return end
			
			x, y = x-ctx.scroll.x, y-ctx.scroll.y
			if internals.xtinverted then
				str = ctxu.reverseTextX(str)
				bstr = ctxu.reverseTextX(bstr)
				fstr = ctxu.reverseTextX(fstr)
			end
			if internals.xinverted then
				str = ctxu.reverseTextX(str)
				bstr = ctxu.reverseTextX(bstr)
				fstr = ctxu.reverseTextX(fstr)
				x=ctx.width-x-#str
			end
			
			local builtstr, bcol, fcol = "", "", ""
			local ni = 0
			local function blitIf()
				local nbc, nfc = bstr:sub(1, 1), fstr:sub(1, 1)
				if nbc~=bcol or nfc~=fcol then
					if bcol and (bcol~=" ") and (bcol~="") then
						if internals.isColor then
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
		ifn.drawData = function(q, data)
			checkInitialized(internals)
			if term.getSimulated() then return end
			
			local trimmedData = {x=data.x, y=data.y}
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
				--coroutine.yield() --TODO: ?
				term.setBackground(bg or 0)
				for fg, gps in pairs(fgs) do
					term.setForeground(fg or 15)
					for id, dat in pairs(gps) do
						term.set(dat.x+trimmedData.x+1, dat.y+trimmedData.y+1, dat.text, dat.vertical)
					end
				end
			end
		end
		ctx.startDraw = function()
			checkCanStartDraw(internals)
			internals.drawing = true
			
			if term.getSimulated() then return end
			
			local ob, of = gpu.getBackground(), gpu.getForeground()
			local depth = gpu.getDepth()
			local oscreen = gpu.getScreen()
			
			local shouldBind = addr~=oscreen
			if shouldBind then gpu.bind(addr, false) end
			
			internals.backup = {
				depth = depth,
				screen = oscreen,
				theme = {bg=ob, fg=of}
			}
			
			ctx.update()
		end
		ctx.update = function()
			ctx.width, ctx.height = term.getSize()
			if term.getSimulated() then return end
			internals.isColor = internals.enableColor and pcall(gpu.setDepth, 4)
		end
		ctx.setAutoSize = function()
			error("Cannot set autosize on native conext")
		end
		ctx.endDraw = function()
			checkCanEndDraw(internals)
			internals.drawing = false

			if term.getSimulated() then return end
			gpu.bind(internals.backup.screen, false)
			pcall(gpu.setDepth, internals.backup.depth)
			pcall(gpu.setBackground, internals.backup.theme.bg)
			pcall(gpu.setForeground, internals.backup.theme.fg)
		end
	end
	ctx.update()
	return ctx
end