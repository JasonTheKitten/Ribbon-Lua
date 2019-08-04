local cplat = require()

local debugger = ...

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

debugger.error = function(data)
	put("[ERROR]: "..tostring(data))
end

debugger.warn = function(data)
	put("[WARN]: "..tostring(data))
end

debugger.info = function(data)
	put("[INFO]: "..tostring(data))
end

debugger.log = function(data)
	put("[LOG]: "..tostring(data))
end

debugger.setDebugFile = function(path)
    debugFile = cplat.resolvePath(path)
end
debugger.getDebugFile = function()
    return debugFile
end