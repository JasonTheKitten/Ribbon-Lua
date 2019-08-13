local cplat = require()

local debugger = ...

local inDebug = false

local debugFile
local function put(data)
	if debugFile then
		local h, e = io.open(debugFile, "a")
		if h then
			h:write(data.."\n")
			h:close()
		end
	end
end

debugger.error = function(data, inRelease)
	put("[ERROR]: "..tostring(data))
end

debugger.warn = function(data, inRelease)
	put("[WARN]: "..tostring(data))
end

debugger.info = function(data, inRelease)
	put("[INFO]: "..tostring(data))
end

debugger.log = function(data, inRelease)
	put("[LOG]: "..tostring(data))
end

debugger.setDebugFile = function(path)
    debugFile = cplat.resolvePath(path)
end
debugger.getDebugFile = function()
    return debugFile
end

debugger.setDebug = function(isInDebug)
	inDebug = isInDebug
end