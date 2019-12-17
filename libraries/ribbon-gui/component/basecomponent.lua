local ribbon = require()

local class = ribbon.require "class"
local contextmanager = ribbon.require "contextmanager"
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
    if not (ctx or contextmanager.running) then error("Either a context must be specified, or the context manager must be running.", 2) end

    Component.__call(self)
    ctx = ctx or contextmanager.getDisplayContext()
	self.context = ctx
	self.childcontext = ctx
	self.eventSystem = es or process
	self.defaultComponent = class.new(BufferedComponent, self):attribute(
		"width", {1, 0},
		"height", {1, 0}
	)
    self:update()

    self.updated, self.graphicsUpdated = false, false
    self:addEventListener("component_update", function() self.updated = true end)
    self:addEventListener("component_graphics_update", function() self.graphicsUpdated = true end)
end

function BaseComponent:setParent() end

function BaseComponent:getDefaultComponent()
	return self.defaultComponent
end
function BaseComponent:getComponents()
    return self, self.defaultComponent
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

function BaseComponent:renderUpdated()
    if self.updated or self:update() then
        self:render()
        self.updated, self.graphicsUpdated = false, false
    elseif self.graphicsUpdated then
        self:renderGraphics()
        self.graphicsUpdated = false
    end
end

basecomponent.execute = contextmanager.inContextManager --TODO: deprecated alias