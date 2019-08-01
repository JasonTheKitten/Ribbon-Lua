local cplat = require()

local class = cplat.require "class"
local bctx = cplat.require "bufferedcontext"
local process = cplat.require "process"
local util = cplat.require "util"

local Size = cplat.require("class/size").Size
local SizePosGroup = cplat.require("class/sizeposgroup").SizePosGroup

local Component = cplat.require("component/component").Component

local runIFN = util.runIFN

local blockcomponent = ...
local BlockComponent = {}
blockcomponent.BlockComponent = BlockComponent

BlockComponent.cparents = {Component}
function BlockComponent:__call(parent)
	class.checkType(parent, Component, 3, "Component")
	
	self.children = {}
	self.eventSystem = process.createEventSystem()
	self.context = bctx.getContext(parent.context, 0, 0, 0, 0, self.eventSystem)
	
	self.size = class.new(Size, 0, 0)
	
	table.insert(parent.children, 1, self)
	
	parent.eventSystem.addEventListener(nil, function(d, e)
		self.eventSystem.fireEvent(e, d) --TODO: Filter
	end)
end

function BlockComponent:getSize()
	return self.size
end
function BlockComponent:setSize(size)
	class.checkType(size, Size, 3, "Size")
	self.size = size
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

--IFN functions
function BlockComponent.calcSizeIFN(q, self, size)
	size = self.sizePosGroup or size
	if self.size.width==0 or self.size.height==0 then
		if self.preferredSize then
			self.size = self.preferredSize:clone()
		else
			self.size = class.new(Size, 0, 0)
		end
	end
	self.position = size.position:clone()
	q(function()
		if self.preferredSize then self.size:set(self.size:max(self.preferredSize)) end
		if self.minSize then self.size:set(self.size:max(self.minSize)) end
		if self.maxSize then self.size:set(self.size:min(self.maxSize)) end
		size:add(self.size)
	end)
	local msize = class.new(SizePosGroup, self.size, nil, size.size)
	for k, v in ipairs(self.children) do
		q(v.calcSizeIFN, v, msize)
	end
end
function BlockComponent.drawIFN(q, self, hbr)
	--Ensure we draw within bounds
	local size = self.size
	local position = self.position
	self.context.setPosition(position.x, position.y)
	self.context.setDimensions(size.width, size.height)
	
	local obg, ofg = self.context.getColors()
	local dbg, dfg = self.context.parent.getColors()
	self.context.setColors(self.color or dbg, self.textColor or dfg)
	self.context.startDraw()
	q(function()
		self.context.drawBuffer()
		self.context.endDraw()
		self.context.setColors(obg, ofg)
	end)
	
	self.context.clear()
	
	for k, v in ipairs(self.children) do
		q(v.drawIFN, v, size)
	end
end