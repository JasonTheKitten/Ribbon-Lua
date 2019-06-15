local cplat = require()

local debugger = ...

local function put(data)
	local dbgf = "${DEBUGFILE}"
	local res = cplat.resolvePath(dbgf)
	if res ~= dbgf then
		local h, e = io.open(res, "a")
		if h then
			h:write(data.."\n")
			h:close()
		end
	end
end

debugger.error = function(data)
	put("[ERROR]: "..data)
end

debugger.warn = function(data)
	put("[WARN]: "..data)
end

debugger.info = function(data)
	put("[INFO]: "..data)
end

debugger.log = function(data)
	put("[LOG]: "..data)
end