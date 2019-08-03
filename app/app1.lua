local cplat = require()
local process = cplat.require "process"
local context = cplat.require "context"
local display = cplat.require "display"
local bctx = cplat.require "bufferedcontext"

local display = display.getDisplay(display.getDefaultDisplayID())
local octx = context.getNativeContext(display)
local octx2 = context.getContext(octx, 0, 0)
local ctx = bctx.getContext(octx2, 0, 0, nil, nil, process)

octx.startDraw()
octx2.startDraw()
ctx.startDraw()

octx2.update()
ctx.update()
while true do
	for y = 0, ctx.height-1 do
		for x = 0, ctx.width-1 do
			ctx.drawPixel(x, y, math.random(0, 15), string.char(math.random(31, 255)), math.random(0, 15))
		end
	end

	ctx.drawBuffer()
end

ctx.endDraw()
octx2.endDraw()
octx.endDraw()