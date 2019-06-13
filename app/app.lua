local cplat = require()

--[[local process = cplat.require "process"
process.addEventListener("key_up", function() print("H") end)
while true do 
	coroutine.yield() 
end]]

local gui = cplat.require "gui"
local ctxu = cplat.require "contextutils"
local statics = cplat.require "statics"

local COLORS = statics.get("colors")

local display = gui.getDisplay(gui.getDefaultDisplayID())
local ctx = gui.getNativeContext(display)
ctx.startDraw()

local timerLabel = " CPlat Timer "

local function draw(t, rst)
	local titlePosX, titlePosY = ctxu.calcPos(ctx, 0, .5, 0, .3, #timerLabel, -.5, 1, 0)
	local timePosX, timePosY = ctxu.calcPos(ctx, 0, .5, 0, .6, 5, -.5, 1, 0)
	
	if rst then
		ctx.clear(COLORS.BLUE)
		ctx.drawEmptyRect(0, 0, ctx.WIDTH, ctx.HEIGHT, COLORS.LIGHTBLUE, "%", COLORS.GREEN)
		ctx.drawText(titlePosX, titlePosY, timerLabel, COLORS.PINK, COLORS.WHITE)
	end
	local timeW0 = ctxu.align(t or "OUT", ctxu.ALIGN_RIGHT, 3, "0")
	local timePadded = ctxu.align(timeW0, ctxu.ALIGN_CENTER, 5)
	ctx.drawText(timePosX, timePosY, timePadded, COLORS.PINK, COLORS.WHITE)
end

draw(0, true)
for i=0, 10 do
	draw(i)
	sleep(1)
	i=i+1
end
draw()
sleep(5)

ctx.endDraw()
