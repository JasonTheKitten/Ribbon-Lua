local cplat = require()

local bctx = cplat.require "bufferedcontext"
local class = cplat.require "class"
local contextapi = cplat.require "context"
local displayapi = cplat.require "display"
local process = cplat.require "process"

local Component = cplat.require("component/component").Component

local basec = ...
local BaseComponent = {}
basec.BaseComponent = BaseComponent

BaseComponent.cparents = {Component}
function BaseComponent:__call(ctx, es)
	self.context = bctx.getContext(ctx, 0, 0, nil, nil, process)
	self.children = {}
	self.eventSystem = process.createEventSystem()
	
	es.addEventListener(nil, function(d, e)
		self.eventSystem.fire(e, d) --TODO: Filter
	end)
end

function BaseComponent.drawIFN(q, self, hbr)
	self.context.startDraw()
	q(function()
		self.context.endDraw()
		self.context.drawBuffer()
	end)
	Component.drawIFN(q, self, hbr)
end

function BaseComponent.execute(func)
	local cctx = {}
	func(function(display)
		display = display or displayapi.getDefaultDisplayID()
		if type(display) == "number" then
			display = displayapi.getDisplay(display)
		end
		
		local octx = cctx[display] or contextapi.getNativeContext(display)
		octx.startDraw()
		
		cctx[display] = octx
		
		return octx
	end)
	for k, v in pairs(cctx) do v.endDraw() end
end