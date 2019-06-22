local cplat = require()

local process = cplat.require "process"
local gui = cplat.require "gui"
local bctx = cplat.require "bufferedcontext"
local ctxu = cplat.require "contextutils"
local statics = cplat.require "statics"

local COLORS = statics.get("colors")

local display = gui.getDisplay(gui.getDefaultDisplayID())
local octx = gui.getNativeContext(display)
local ctx = bctx.getContext(octx, 0, 0, nil, nil, process)

octx.startDraw()
ctx.startDraw()

local timerLabel = " CPlat Timer "
local ttime = ""

local function draw(t, rst, c)
	octx.update()
	ctx.update()
	
	local titlePosX, titlePosY = ctxu.calcPos(ctx, 0, .5, 0, .3, #timerLabel, -.5, 1, 0)
	local timePosX, timePosY = ctxu.calcPos(ctx, 0, .5, 0, .6, 5, -.5, 1, 0)
	
	if rst then
		ctx.clear(COLORS.BLUE)
		ctx.drawEmptyRect(0, 0, ctx.WIDTH or ctx.PREFERRED_WIDTH, ctx.HEIGHT or ctx.PREFERRED_HEIGHT, COLORS.LIGHTBLUE, "%", COLORS.GREEN)
		ctx.drawText(titlePosX, titlePosY, timerLabel, COLORS.PINK, COLORS.WHITE)
	end
	local timeW0 = ctxu.align(t or "OUT", ctxu.ALIGN_RIGHT, 3, c or "0")
	local timePadded = ctxu.align(timeW0, ctxu.ALIGN_CENTER, 5)
	ctx.drawText(timePosX, timePosY, timePadded, COLORS.PINK, COLORS.WHITE)
	
	ctx.drawBuffer()
end

draw("", true, "X")
process.addEventListener("char", function(e)
	if ("1234567890"):find(e.char) then
		ttime = ttime..e.char
		draw(ttime, nil, "X")
		if #ttime == 3 then
			process.setInterruptsEnabled(false)
		end
	end
end)
while process.getInterruptsEnabled() do
	coroutine.yield()
end
sleep(1)
for i=0, tonumber(ttime) do
	draw(i)
	sleep(1)
	i=i+1
end
draw()
sleep(5)

ctx.endDraw()
octx.endDraw()
