--TODO: Pixel Info and Pixel Functions
--Pixels can be given extra info
--A function can be assigned to a context to process this info
--Additionally, backgrounds, foregrounds, and text can be passed as functions

local ribbon = require()

local bctx = ribbon.require "bufferedcontext"
local ctxu = ribbon.require "contextutils"
local debugger = ribbon.require "debugger"
local displayapi = ribbon.require "display"
local environment = ribbon.require "environment"
local util = ribbon.require "util"

local natives = environment.getNatives()

local isCC = environment.is("CC")
local isOC = environment.is("OC")

local appinfo = ribbon.getAppInfo()
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
local function checkLH(l, h)
	if not l or not h then error("Arguments missing", 3) end
	return l<1 or h<1
end
local function cXY(ctx, x, y)
	return x-ctx.scroll.x, y-ctx.scroll.y
end
local function resolvePixelValue(v, i)
    --[=[while true do
        if type(v)=="function" then v=v()
        elseif type(v)=="table" and i then v=v[1][v[2]][v[3]][i]
        else return v end
    end]=]
    return v
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
		enableOCFlickerOptimizations = true,
		enableCCFlickerOptimizations = true,
	}
	local internals = {
		isNative = false,
		optimizationsEnabled = true,
		enableColor = true,
		useParentWidth = not l,
		useParentHeight = not h,
		CONFIG = {}
	}
	ctx.INTERNALS = internals

	local pinternals = (parent and parent.INTERNALS) or {}
	local ifn, pifn = {}, pinternals.IFN or {}
	internals.IFN = ifn

	ctx.setParent = function(parent)
		ctx.parent = parent
		pinternals = (parent and parent.INTERNALS) or {}
		pifn = pinternals.IFN or {}
	end

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
		return ifn.drawFilledRect(0, 0, ctx.width, ctx.height, color, char)
	end

	ifn.drawPixel = function(x, y, color, char, fg)
		x, y = cXY(ctx, x, y)
		if (not ctx.width or (x>=0 and x<ctx.width)) and
			(not ctx.height or (y>=0 and y<ctx.height)) then

			checkInitialized(internals)

			color = color or internals.CONFIG.defaultBackgroundColor
			fg = fg or internals.CONFIG.defaultTextColor
			return pifn.drawPixel(ctx.position.x+x, ctx.position.y+y, color, char, fg)
		end
	end
	ctx.drawPixel = ifn.drawPixel

	ctx.drawText = function(x, y, text, color, fg)
		text = (text and tostring(text)) or ""
		ifn.drawText(x, y, text, color, fg)
	end
	ifn.drawText = function(x, y, text, color, fg)
		checkInitialized(internals)
		color = color or internals.CONFIG.defaultBackgroundColor
		fg = fg or internals.CONFIG.defaultTextColor
		text = text:sub(1, ctx.width-x)
		if #text==0 then return end
		if pifn.drawText and internals.optimizationsEnabled then
			x, y = cXY(ctx, x, y)
			return pifn.drawText(ctx.position.x+x, ctx.position.y+y, text, color, fg)
		else
			local ox, oy = 0,0
			for i=1, #text do
				if text:sub(i,i)=="\n" then
					ox,oy = 0,oy+1
				else
					ifn.drawPixel(ctx.position.x+x+ox, ctx.position.y+y+oy, color, text:sub(i,i), fg)
					ox=ox+1
				end
			end
		end
	end

	ctx.drawRect = function(x, y, l, h, fill, color, char, fg)
		if checkLH(l, h) then return end
		char = char and tostring(char) or " "
		local func = (fill==false and ifn.drawEmptyRect) or ifn.drawFilledRect
		func(x, y, l, h, color, char, fg)
	end
	ifn.drawFilledRect = function(x, y, l, h, color, char, fg)
		checkInitialized(internals)
		color = color or internals.CONFIG.defaultBackgroundColor
		fg = fg or internals.CONFIG.defaultTextColor
		if pifn.drawFilledRect and internals.optimizationsEnabled then
			x, y = cXY(ctx, x, y)
			if x<ctx.width and y<ctx.height then
				l = (l+x < ctx.width and l) or ctx.width-x
				h = (h+y < ctx.height and h) or ctx.height-y
				return pifn.drawFilledRect(ctx.position.x+x, ctx.position.y+y, l, h, color, char, fg)
			end
		else
			for ox=0, l-1 do
				for oy=0, h-1 do
					ifn.drawPixel(x+ox, y+oy, color, char or " ", fg)
				end
			end
		end
	end
	ifn.drawEmptyRect = function(x, y, l, h, color, char, fg)
		checkInitialized(internals)
		color = color or internals.CONFIG.defaultBackgroundColor
		fg = fg or internals.CONFIG.defaultTextColor
		for ox=0, l-1 do
			ifn.drawPixel(x+ox, y, color, char, fg)
			ifn.drawPixel(x+ox, y+h-1, color, char, fg)
		end
		for oy=0, h-1 do
			ifn.drawPixel(x, y+oy, color, char, fg)
			ifn.drawPixel(x+l-1, y+oy, color, char, fg)
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

		ifn.drawTextBox(x, y, text, color, fg, meta)
	end
	ifn.drawTextBox = function(x, y, text, color, fg, meta)
		checkInitialized(internals)
		ifn.drawFilledRect(x, y, meta.width, meta.height, color, meta.fillChar, meta.fillTextColor)
		ifn.drawText(x, y, text, color, fg)
	end

	ctx.blit = function(x, y, str, bstr, fstr)
		ifn.blit(x, y, str, bstr, fstr)
	end
	ifn.blit = function(x, y, str, bstr, fstr)
		checkInitialized(internals)
		if pifn.blit and ctx.optimizationsEnabled then
			if y>ctx.height then return end
			x, y = cXY(ctx, x, y)
			str = str:sub(1, ctx.width-x)
			bstr = bstr:sub(1, ctx.width-x)
			fstr = fstr:sub(1, ctx.width-x)
			return pifn.blit(x+ctx.position.x, y+ctx.position.y, str, bstr, fstr)
		else
			fstr = fstr:gsub(" ", "F")
			for i=1, #str do
				if bstr:sub(i, i) ~= " " then
					local bg = tonumber(bstr:sub(i,i), 16) or 0
					local fg = tonumber(fstr:sub(i,i), 16) or 15
					pifn.drawPixel(x+i-1, y, bg, str:sub(i, i), fg)
				end
			end
		end
	end

	ctx.applyBuffer = function(b, x, y, l, h)
		checkInitialized(internals)
		ifn.applyBuffer(b, x, y, l, h)
	end
	ifn.applyBuffer = function(b, x, y, l, h)
		local clock = os.clock()
		checkInitialized(internals)
		local function getPixelInfo(x, y, dtype)
			if not x or not y then return end
			for k, v in util.ripairs(b) do
				if v[dtype] and
					(not v.x or (x>=v.x and (not v.width or x<(v.x+v.width)))) and
					(not v.y or (y>=v.y and (not v.height or y<(v.y+v.height)))) then
					return v[dtype]
				end
			end
		end
		for k, v in util.ripairs(b) do
			local mx, my = (v.x or 0)+x-b.scrollx, (v.y or 0)+y-b.scrolly
			if v.width or v.height or (mx>=0 and mx<l) or (my>=0 and my<h) then
				local bg, char, fg =
					v.background or getPixelInfo(v.x, v.y, "background"),
					v.char or getPixelInfo(v.x, v.y, "char"),
					v.foreground or getPixelInfo(v.x, v.y, "foreground")
				if v.width==1 and v.height==1 then
					ifn.drawPixel(mx, my, bg, char, fg)
				else
					ifn.drawFilledRect((v.x or 0)+x, (v.y or 0)+y, v.width or l, v.height or h, bg, char, fg)
				end
			end
		end
	end

	ctx.drawData = function(data)
		ifn.drawData(data)
		if not data[0] then return end
	end
	ifn.drawData = function(data)
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
			pifn.drawData(trimmedData)
		else
			for y=0, #data do
				if not data[y] then break end
				for x=0, #data[y] do
					if not data[y][x] then break end
					if data[y][x][1] and data[y][x][2] then
						ifn.drawPixel(x+data.x, y+data.y, data[y][x][2], data[y][x][1], data[y][x][3] or 15)
					end
				end
			end
		end
	end

	ctx.setColors = function(color, fg)
		internals.CONFIG.defaultBackgroundColor = color or internals.CONFIG.defaultBackgroundColor
		internals.CONFIG.defaultTextColor = fg or internals.CONFIG.defaultTextColor
	end
	ctx.setColorsRaw = function(color, fg)
		internals.CONFIG.defaultBackgroundColor = color
		internals.CONFIG.defaultTextColor = fg
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
		ctx.width = (internals.useParentWidth and ctx.parent and ctx.parent.width) or ctx.width
		ctx.height = (internals.useParentHeight and ctx.parent and ctx.parent.height) or ctx.height
		internals.isColor = pinternals.isColor and internals.enableColor
	end

	ctx.setAutoSize = function(w, h)
		if w~=nil then ctx.useParentWidth = w end
		if h~=nil then ctx.useParentHeight = h end
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
				--Quick note, we are not actually using the result of isColor here
			end,
			getSize = function()
				if term.getSimulated() then return 0, 0 end
				return resolveDisplay().getSize()
			end,
			isColor = function()
				if term.getSimulated() then return false end
				return resolveDisplay().isColor()
			end
		}
		setmetatable(term, {__index=function(t, k)
			return rawget(t, k) or function(...)
				local args = {...}
				local res, e = {pcall(function()
					return resolveDisplay()[k](table.unpack(args))
				end)}
				if res[1] then return table.unpack(res, 2) end
			end
		end})

		if natives.term.blit then
			ifn.blit = function(x, y, str, bstr, fstr)
				checkInitialized(internals)
				if term.getSimulated() then return end

				x, y = x-ctx.scroll.x, y-ctx.scroll.y

				term.setCursorPos(x+1, y+1)
				if ctx.INTERNALS.isColor then
					term.blit(str, fstr:gsub(" ", "0"), bstr:gsub(" ", "f"))
				else
					term.write(str)
				end
			end
			ifn.drawData = function(data)
				checkInitialized(internals)
				if term.getSimulated() then return end

				local buffer = {}

				for y=0, #data do
					local by = {"", "", ""}
					for x=0, #(data[y] or {}) do
                        local pixel = (data[y] or {})[x] or {}
                        local c, fg, bg = pixel[1], pixel[2], pixel[3]
                        c=resolvePixelValue(c, 1)
                        fg=resolvePixelValue(fg, 2)
                        bg=resolvePixelValue(bg, 3)
                        --TODO: table.concat?
						by[1] = by[1]..(c       or " ")
						by[2] = by[2]..(hex[fg] or "0")
						by[3] = by[3]..(hex[bg] or "f")
					end
					buffer[y] = by
				end

                for k, v in pairs(buffer) do
                    local v1, v2, v3 = buffer[k][1], buffer[k][2], buffer[k][3]
    				ifn.blit(data.x, data.y+k, buffer[k][1], buffer[k][2], buffer[k][3])
				end
			end
		end

		local oldIFNAB = ifn.applyBuffer
		ifn.applyBuffer = function(b, x, y, l, h)
			checkInitialized(internals)
			if ctx.enableCCFlickerOptimizations then
				return ifn.drawData(bctx.getData(b, x, y, l, h))
			else
				return oldIFNAB(b, x, y, l, h)
			end
		end

		ifn.drawPixel = function(x, y, color, char, fg)
			checkInitialized(internals)
            if term.getSimulated() then return end

            color, char, fg = resolvePixelValue(color, 2), resolvePixelValue(char, 1), resolvePixelValue(fg, 3)

			char = (char and tostring(char)) or " "
			color = color or internals.CONFIG.defaultBackgroundColor
			fg = fg or internals.CONFIG.defaultTextColor

			x, y = x-ctx.scroll.x, y-ctx.scroll.y

			if internals.isColor then
				term.setBackgroundColor(2^(color or internals.CONFIG.defaultBackgroundColor or 15))
				term.setTextColor(2^(fg or internals.CONFIG.defaultTextColor or 0))
			end

			term.setCursorPos(x+1, y+1)
			term.write(char)
		end
		ctx.clear = function(color, char)
			checkInitialized(internals)
            if term.getSimulated() then return end

            color = resolvePixelValue(color, 2)
			char = char and tostring(char) or " "
			if char == " " then
				term.setBackgroundColor(2^(color or internals.CONFIG.defaultBackgroundColor or 0))
				term.clear()
			else
				return ifn.drawFilledRect(0, 0, ctx.width, ctx.height, color, char)
			end
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
			internals.isColor = internals.enableColor and term.isColor()
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
			getSize = function()
				if gpu then
					local ok, l, h = pcall(gpu.getViewport)
					if ok and l and h then return l, h end
				end
				return 0, 0
			end,
			setBackground = function(color)
				color = color or 15
				if color>15 then error("Extended pallete coming at a later time", 3) end
				if gpu then pcall(gpu.setBackground, color, true) end
			end,
			setForeground = function(color)
				color = color or 0
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

		ifn.drawPixel = function(x, y, color, char, fg)
			checkInitialized(internals)
            if term.getSimulated() then return end

            color, char, fg = resolvePixelValue(color, 2), resolvePixelValue(char, 1), resolvePixelValue(fg, 3)

			char = char and tostring(char)
			color = color or internals.CONFIG.defaultBackgroundColor
			fg = fg or internals.CONFIG.defaultTextColor

			x, y = x-ctx.scroll.x, y-ctx.scroll.y

			if internals.isColor then
				term.setBackground(color or internals.CONFIG.defaultBackgroundColor or 15)
				term.setForeground(fg or internals.CONFIG.defaultTextColor or 0)
			end
			term.set(x+1, y+1, char or " ")
		end
		ifn.drawFilledRect = function(x, y, l, h, color, char, fg)
			checkInitialized(internals)
			if term.getSimulated() then return end

            if not l or not h or l<1 or h<1 then error("Invalid dimensions", 2) end

            color, char, fg = resolvePixelValue(color, 2), resolvePixelValue(char, 1), resolvePixelValue(fg, 3)

			char = char and tostring(char)
			color = color or internals.CONFIG.defaultBackgroundColor
			fg = fg or internals.CONFIG.defaultTextColor

			x, y = x-ctx.scroll.x, y-ctx.scroll.y

			if internals.isColor then
				term.setBackground(color or internals.CONFIG.defaultBackgroundColor)
				term.setForeground(fg or internals.CONFIG.defaultTextColor)
			end
			gpu.fill(x+1, y+1, l, h, char or " ")
		end
		ifn.blit = function(x, y, str, bstr, fstr)
			checkInitialized(internals)
			if term.getSimulated() then return end

			x, y = x-ctx.scroll.x, y-ctx.scroll.y

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

		local oldIFNAB = ifn.applyBuffer
		ifn.applyBuffer = function(b, x, y, l, h)
			checkInitialized(internals)
			if ctx.enableOCFlickerOptimizations then
				return ifn.drawData(bctx.getData(b, x, y, l, h))
			else
				return oldIFNAB(b, x, y, l, h)
			end
		end
		ifn.drawData = function(data)
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
            local function gdata(y, x)
                local char, color, fg =
                    trimmedData[y][x][1],
                    trimmedData[y][x][2],
                    trimmedData[y][x][3]

                color, char, fg = resolvePixelValue(color, 2), resolvePixelValue(char, 1), resolvePixelValue(fg, 3)

                return color, char, fg
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

                            local char, color, fg = gdata(y, x+lengthH)
							textH, bgH = textH..char, bgH or color, fgH or fg
							lengthH = lengthH+1
						end
						while checkEligible(x, y+heightV, bgV, fgV) do
							if not trimmedData[y+heightV][x].processed then
								pointsH = pointsH+1
                            end

                            local char, color, fg = gdata(y+heightV, x)
							textV, bgV = textV..char, bgV or color, fgV or fg
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
			pcall(gpu.bind, internals.backup.screen, false)
			pcall(gpu.setDepth, internals.backup.depth)
			pcall(gpu.setBackground, internals.backup.theme.bg)
			pcall(gpu.setForeground, internals.backup.theme.fg)
		end
	end
	ctx.update()

	return ctx
end