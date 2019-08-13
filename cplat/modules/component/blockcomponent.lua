local cplat = require()

local class = cplat.require "class"
local sctx = cplat.require "subcontext"
local ctxu = cplat.require "contextutils"
local debugger = cplat.require "debugger"
local process = cplat.require "process"
local util = cplat.require "util"

local Size = cplat.require("class/size").Size
local SizePosGroup = cplat.require("class/sizeposgroup").SizePosGroup
local Position = cplat.require("class/position").Position

local Component = cplat.require("component/component").Component

local runIFN = util.runIFN

local blockcomponent = ...
local BlockComponent = {}
blockcomponent.BlockComponent = BlockComponent

BlockComponent.cparents = {Component}
function BlockComponent:__call(parent)
	class.checkType(parent, Component, 3, "Component")
	
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

function BlockComponent:setAutoSize(w, ow, h, oh)
	self.autoSize = {w, ow, h, oh}
end

--IFN functions
function BlockComponent.calcSizeIFN(q, self, size)
	if not self.parent then return end

	self.context = self.context or sctx.getContext(self.parent.context, 0, 0, 0, 0)
	self.context.parent = self.parent.context
	
	self.position = size.position:clone()
	
	local osize = size
	if self.sizeAndLocation then
		local msize = self.sizeAndLocation[1]
		local x, y = ctxu.calcPos(self.parent.context, table.unpack(self.sizeAndLocation, 2))
		size = class.new(SizePosGroup, msize:clone(), nil, msize:clone())
		self.position = class.new(Position, x, y)
		self.size = size.size
		self.maxSize = size.maxSize
	elseif self.sizePosGroup then
		size = self.sizePosGroup:cloneAll()
		self.size = size.size
		self.position = size.position
	elseif not self.useCustomSize then
		if self.preferredSize then
			self.size = self.preferredSize:clone()
		else
			self.size = class.new(Size, 0, 0)
		end
	end
	if self.autoSize[1] or self.autoSize[2] then
		if not self.maxSize then self.maxSize = class.new(Size, 0, 1/0) end
		self.size.width = osize.size.width*(self.autoSize[1] or 0) + (self.autoSize[2] or 0)
		self.maxSize.width = self.size.width
	end
	if self.autoSize[3] or self.autoSize[4] then
		if not self.maxSize then self.maxSize = class.new(Size, 1/0, 0) end
		self.size.height = osize.size.height*(self.autoSize[3] or 0) + (self.autoSize[4] or 0)
		self.maxSize.height = self.size.height
	end
	
	local msize = class.new(
		SizePosGroup, self.size, nil, 
		self.maxSize or size.maxSize:clone():subtractLH(self.position.x, self.position.y))
	
	for k, v in util.ripairs(self.children) do
		if v.sizeAndLocation then q(v.calcSizeIFN, v, msize) end
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
		if not v.sizeAndLocation then q(v.calcSizeIFN, v, msize) end
	end
end
function BlockComponent.drawIFN(q, self, hbr)
	if not self.parent then return end
	
	local obg, ofg = self.context.getColors()
	local dbg, dfg = self.parent.context.getColors()
	local ocf = self.context.getClickFunction()
	self.context.setClickFunction(self.handlers.onclick)
	self.context.setColorsRaw(self.color or dbg, self.textColor or dfg)
	self.context.startDraw()
	q(function()
		self.context.endDraw()
		self.context.setColorsRaw(obg, ofg)
		self.context.setClickFunction(ocf)
	end)
	
	self.context.clear(self.color)
	
	for k, v in util.ripairs(self.children) do
		q(v.drawIFN, v, size)
	end
end