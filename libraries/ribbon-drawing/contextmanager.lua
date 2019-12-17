local ribbon = require()

local contextapi = ribbon.require "context"
local displayapi = ribbon.require "display"

local contextmanager = ...

--TODO: Should support showing background pixels

local cachedGD
function contextmanager.inContextManager(func, ...)
    if cachedGD then error("An instance of the context manager is already running!", 2) end
	contextmanager.running = true
    local cctx = {}
	cachedGD = function(display)
		display = display or displayapi.getDefaultDisplayID()
		if type(display) == "number" then
			display = displayapi.getDisplay(display)
		end

		local octx = cctx[display] or contextapi.getNativeContext(display)
		octx.startDraw()

		cctx[display] = octx

		return octx
	end
	local res = {pcall(func, ...)}
    for k, v in pairs(cctx) do v.endDraw() end
    cachedGD, contextmanager.running = nil, false
    if not res[1] then error(res[2], -1) end

    return table.unpack(res)
end
contextmanager.getDisplayContext = function(...)
	if not cachedGD then error("An instance of the context manager must be running!", 2) end
	return cachedGD(...)
end
contextmanager.running = false