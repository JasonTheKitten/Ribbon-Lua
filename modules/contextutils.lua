--Note that this file also handles some string manipulation
local contextutils = ...

--Context Lib
contextutils.calcPos = function(ctx, ax, px, ay, py, l, opl, h, oph)
	local ol, oy = 0, 0
	if l and opl and l>0 and opl~=0 then
		ol = l*opl
	end
	if h and oph and h>0 and oph~=0 then
		oy = h*oph
	end
	ax, ay, px, py = ax or 0, ay or 0, px or 0, py or 0
	return 
		math.floor(ax+ctx.width*px+ol), 
		math.floor(ay+ctx.height*py+oy)
end

contextutils.translateMouseCordsUp = function(ctx, x, y, parent)
    local cctx = ctx
    while cctx and cctx~=parent do
        x=x-cctx.position.x
        y=y-cctx.position.y
        cctx=cctx.parent
    end
    if parent and cctx~=parent then
        error("Unable to resolve cords: Invalid parent", 2)
    end
    return x, y
end


--String Lib
local function splitNoGM(text)
	text = tostring(text)
	local result = {}
	local insertNL = text:sub(#text, #text) == "\n"
	repeat
		local nl = text:find("\n") or #text+1
		table.insert(result, text:sub(1, nl-1))
		text=text:sub(nl+1, #text)
	until text==""
	
	if insertNL then table.insert(result, "") end
	
	return result
end

contextutils.splitNL = splitNoGM --Eh, should I include this?

contextutils.getLineLength = function(text)
	text=tostring(text)
	text = text:gsub("\t", "  ") --TODO: Handle with logic instead
	local len = 0
	for str in text:gmatch("[^\n]+") do
		if #str>len then len = #str end
	end
	return len
end
contextutils.getLines = function(text)
	return #splitNoGM(text)
end

contextutils.reverseTextX = function(otext)
	otext=tostring(otext)
	local lines = splitNoGM(otext)
	local text=""
	for k, v in pairs(lines) do
		for i=#v, 1, -1 do
			text=text..v:sub(i,i)
		end
		text = text.."\n"
	end
	return text:sub(1, #text-1)
end

contextutils.ALIGN_LEFT = 0
contextutils.ALIGN_CENTER = 1
contextutils.ALIGN_RIGHT = 2
contextutils.align = function(text, mode, l, pad)
	text = tostring(text)
	--text = text:gsub("\t", "  ") --TODO: Handle with logic instead
	pad=pad or " "
	if mode==contextutils.ALIGN_LEFT then
		local ll=l or contextutils.getLineLength(text)
		local split = splitNoGM(text)
		local text = ""
		for i=1, #split do
			local paddingr = padrep(ll-#split[i])
			text=text..split[i]..paddingr.."\n"
		end
		return text:sub(1, #text-1)
	elseif mode==contextutils.ALIGN_CENTER then
		local ll=l or contextutils.getLineLength(text)
		local split = splitNoGM(text)
		local text = ""
		for i=1, #split do
			local paddingb = (ll-#split[i])/2
			local paddingl = (pad):rep(math.floor(paddingb))
			local paddingr = (pad):rep(math.ceil(paddingb))
			text=text..paddingl..split[i]..paddingr.."\n"
		end
		return text:sub(1, #text-1)
	elseif mode==contextutils.ALIGN_RIGHT then
		local ll=l or contextutils.getLineLength(text)
		local split = splitNoGM(text)
		local text = ""
		for i=1, #split do
			local paddingl = (pad):rep(ll-#split[i])
			text=text..paddingl..split[i].."\n"
		end
		return text:sub(1, #text-1)
	end
end