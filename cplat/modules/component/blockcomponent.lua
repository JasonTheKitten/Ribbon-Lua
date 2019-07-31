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
	self.color = 0
	
	table.insert(parent.children, 1, self)
	
	parent.eventSystem.addEventListener(nil, function(d, e)
		self.eventSystem.fire(e, d) --TODO: Filter
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
	if self.size.width==0 or self.size.height==0 then
		if self.preferredSize then
			self.size = self.preferredSize:clone()
		else
			self.size = class.new(Size, 0, 0)
		end
	end
	q(function()
		if self.minSize then self.size = self.size:max(self.minSize) end
		if self.maxSize then self.size = self.size:min(self.maxSize) end
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
	self.context.setDimensions(size.width, size.height)
	
	self.context.startDraw()
	q(function()
		self.context.drawBuffer()
		self.context.endDraw()
	end)
	
	--Test: draw random color
	if self.color then self.context.clear(self.color) end
	
	for k, v in ipairs(self.children) do
		q(v.drawIFN, v, size)
	end
end