local cplat = require()

--local bctx = cplat.require "bufferedcontext"
local class = cplat.require "class"
local ctx = cplat.require "context"
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
	self.context = ctx.getContext(parent.context, 0, 0, 0, 0)
	
	self.size = class.new(SizePosGroup, class.new(Size, 0, 0))
	
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

function BlockComponent:setPreferredSize(size)
	if size then class.checkType(size, Size, 3, "Size") end
	self.preferredSize = size
end
function BlockComponent:getPreferredSize()
	return self.preferredSize
end

--IFN functions
function BlockComponent.calcSizeIFN(q, self, size)
	q(function()
		if self.minSize then self.size = self.size:max(self.minSize) end
		if self.maxSize then self.size = self.size:min(self.maxSize) end
		size:add(self.size)
	end)
	for k, v in ipairs(self.children) do
		q(v.calcSizeIFN, v, self.size)
	end
end
function BlockComponent.drawIFN(q, self, hbr)
	--Ensure we draw within bounds
	local size = self.size:toSize()
	self.context.setDimensions(size.width, size.height)
	
	self.context.startDraw()
	q(function()
		self.context.endDraw()
	end)
	
	--Test: draw random color
	self.context.clear(math.random(0, 15))
	
	for k, v in ipairs(self.children) do
		q(v.drawIFN, v, size)
	end
end