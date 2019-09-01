local ribbon = require()

local class = ribbon.require "class"
local sctx = ribbon.require "subcontext"
local ctxu = ribbon.require "contextutils"
local debugger = ribbon.require "debugger"
local process = ribbon.require "process"
local util = ribbon.require "util"

local Size = ribbon.require("class/size").Size
local SizePosGroup = ribbon.require("class/sizeposgroup").SizePosGroup
local Position = ribbon.require("class/position").Position

local Component = ribbon.require("component/component").Component

local runIFN = util.runIFN

local blockcomponent = ...
local BlockComponent = {}
blockcomponent.BlockComponent = BlockComponent

BlockComponent.cparents = {Component}
function BlockComponent:__call(parent)
	if parent then class.checkType(parent, Component, 3, "Component") end
	
	Component.__call(self, parent)
	
	self.size = class.new(Size, 0, 0)
	self.autoSize = {}
end

function BlockComponent:setParent(parent)
	Component.setParent(self, parent)
	if parent and parent.context then
		self.context = sctx.getContext(parent.context, 0, 0, 0, 0)
	end
end

function BlockComponent:getSize()
	return self.size
end
function BlockComponent:setSize(size)
	class.checkType(size, Size, 3, "Size")
	self.size = size
	self.useCustomSize = not not size
end

function BlockComponent:setPreferredSize(size)
	if size then class.checkType(size, Size, 3, "Size") end
	self.preferredSize = size
end
function BlockComponent:getPreferredSize()
	return self.preferredSize
end

function BlockComponent:setMinSize(size)
	if size then class.checkType(size, Size, 3, "Size") end
	self.minSize = size
end
function BlockComponent:getMinSize()
	return self.minSize
end

function BlockComponent:setMaxSize(size)
	if size then class.checkType(size, Size, 3, "Size") end
	self.maxSize = size
end
function BlockComponent:getMaxSize()
	return self.maxSize
end

function BlockComponent:forceSize(size)
	class.checkType(size, Size, 3, "Size")
	self:setMinSize(size)
	self:setMaxSize(size)
	self:setPreferredSize(size)
	self:setSize(size)
end

--IFN functions
function BlockComponent:setContextInternal()
	self.dockcontext = (self.attributes["dock"] and self.attributes["dock"].context) or self.parent.childcontext
	self.context = self.context or sctx.getContext(self.dockcontext, 0, 0, 0, 0)
	self.context.parent = self.dockcontext
	self.childcontext = self.context
end
function BlockComponent.calcSizeIFN(q, self, size)
	if not self.parent then return end
	
	if self.attributes["dock"] then
		size = self.attributes["dock"].spg
	end
	self.spg = size
	
	self:setContextInternal()
	
	self.size = (self.preferredSize and self.preferredSize:clone()) or class.new(Size, 0, 0)
	if self.attributes["width"] then
		if not self.maxSize then self.maxSize = class.new(Size, 0, 1/0) end
		self.size.width = size.size.width*(self.attributes.width[1] or 0) + (self.attributes.width[2] or 0)
		self.maxSize.width = self.size.width
	end
	if self.attributes["height"] then
		if not self.maxSize then self.maxSize = class.new(Size, 1/0, 0) end
		self.size.height = size.size.height*(self.attributes.height[1] or 0) + (self.attributes.height[2] or 0)
		self.maxSize.height = self.size.height
	end
	
	if self.location then
		local l, oldPos = self.location, size.position
		size.position = class.new(Position, 
			ctxu.calcPos(self.dockcontext, l[2], l[1], l[4], l[3], self.size.width, l[5], self.size.height, l[6])
		)
		q(function() size.position = oldPos end)
	end
	
	self.position = size.position:clone()
	
	local msize = class.new(
		SizePosGroup, self.size, nil, 
		self.maxSize or size.maxSize:clone():subtractLH(self.position.x, self.position.y))
	
	for k, v in util.ripairs(self.children) do
		if v.location then q(v.calcSizeIFN, v, msize) end
	end
	q(function()
		if self.preferredSize then self.size:set(self.size:max(self.preferredSize)) end
		if self.minSize then self.size:set(self.size:max(self.minSize)) end
		if self.maxSize then self.size:set(self.size:min(self.maxSize)) end
		
		size:add(self.size)
		
		size:fixCursor(true)
		
		self.context.setPosition(self.position.x, self.position.y)
		self.context.setDimensions(self.size.width, self.size.height) --TODO: This is totally broken
	end)
	for k, v in util.ripairs(self.children) do
		if not v.location then q(v.calcSizeIFN, v, msize) end
	end
end
function BlockComponent.drawIFN(q, self, hbr)
	if not self.parent then return end
	
	local obg, ofg = self.context.getColors()
	local dbg, dfg = self.parent.context.getColors()
	local of = self.context.getFunctions()
	self.context.setFunction("onclick", self.handlers.onclick)
	self.context.setFunction("ondrag", self.handlers.ondrag)
	self.context.setFunction("onrelease", self.handlers.onrelease)
	self.context.setColorsRaw(self.color or dbg, self.textColor or dfg)
	self.context.startDraw()
	q(function()
		self.context.endDraw()
		self.context.setColorsRaw(obg, ofg)
		self.context.setFunctions(of)
	end)
	
	self.context.clear()
	
	for k, v in util.ripairs(self.children) do
		q(v.drawIFN, v, size)
	end
end