local cplat = require()
local process = cplat.require "process"
local gui = cplat.require "gui"
local bctx = cplat.require "bufferedcontext"

local display = gui.getDisplay(gui.getDefaultDisplayID())
local octx = gui.getNativeContext(display)
local octx2 = gui.getContext(octx, 0, 0)
local ctx = bctx.getContext(octx2, 0, 0, nil, nil, process)

octx.startDraw()
octx2.startDraw()
ctx.startDraw()

octx2.update()
ctx.update()
--while true do
	for y = 0, ctx.HEIGHT-1 do
		for x = 0, ctx.WIDTH-1 do
			ctx.drawPixel(x, y, math.random(0, 15), " ", 15)
		end
	end

	ctx.drawBuffer()
	coroutine.yield()
--end

ctx.endDraw()
octx2.endDraw()
octx.endDraw()