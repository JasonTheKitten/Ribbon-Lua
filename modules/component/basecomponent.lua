local ribbon = require()

local bctx = ribbon.require "bufferedcontext"
local class = ribbon.require "class"
local contextapi = ribbon.require "context"
local displayapi = ribbon.require "display"
local process = ribbon.require "process"

local Size = ribbon.require("class/size").Size
local SizePosGroup = ribbon.require("class/sizeposgroup").SizePosGroup

local BufferedComponent = ribbon.require("component/bufferedcomponent").BufferedComponent
local Component = ribbon.require("component/component").Component

local basecomponent = ...
local BaseComponent = {}
basecomponent.BaseComponent = BaseComponent

BaseComponent.cparents = {Component}
function BaseComponent:__call(ctx, es)
	Component.__call(self)
	self.context = ctx
	self.childcontext = ctx
	self.eventSystem = process
	self.defaultComponent = class.new(BufferedComponent, self):attribute(
		"background-color", 0, 
		"text-color", 15,
		"width", {1, 0},
		"height", {1, 0}
	)
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

function BaseComponent:render()
	self:update()
	local size = class.new(Size, self.context.width, self.context.height)
	self.spg = class.new(SizePosGroup, size, nil, size)
	self.defaultComponent:calcSize(self.spg)
	self.defaultComponent:draw()
end
function BaseComponent:renderGraphics()
	self.defaultComponent:draw()
end

function basecomponent.execute(func)
	local cctx = {}
	local ok, err = pcall(func, function(display)
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
	if not ok then error(err, -1) end
end