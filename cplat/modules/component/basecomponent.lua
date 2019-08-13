local cplat = require()

local bctx = cplat.require "bufferedcontext"
local class = cplat.require "class"
local contextapi = cplat.require "context"
local displayapi = cplat.require "display"
local process = cplat.require "process"

local Size = cplat.require("class/size").Size
local SizePosGroup = cplat.require("class/sizeposgroup").SizePosGroup

local BufferedComponent = cplat.require("component/bufferedcomponent").BufferedComponent
local Component = cplat.require("component/component").Component

local basec = ...
local BaseComponent = {}
basec.BaseComponent = BaseComponent

BaseComponent.cparents = {Component}
function BaseComponent:__call(ctx, es)
	self.context = ctx
	self.children = {}
	self.handlers = {}
	self.functions = {}
	self.eventSystem = process
	self.defaultComponent = class.new(BufferedComponent, self)
	self.defaultComponent:setAutoSize(1, 0, 1, 0)
	self.defaultComponent:setColor(0)
	self.defaultComponent:setTextColor(15)
	self:update()
end

function BaseComponent:setParent() end

function BaseComponent:getDefaultComponent()
	return self.defaultComponent
end
function BaseComponent:update()
	local oldWidth, oldHeight = self.context.width, self.context.height
	self.context.endDraw()
	self.context.startDraw()
	local doRedraw = self.context.width~=oldWidth or self.context.height~=oldHeight
	return doRedraw
end

function BaseComponent:ezDraw()
	self:update()
	self.defaultComponent:calcSize(class.new(SizePosGroup, class.new(Size, self.context.width, self.context.height)))
	self.defaultComponent:draw()
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