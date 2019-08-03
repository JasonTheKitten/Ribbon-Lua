local cplat = require()

local class = cplat.require "class"
local bctx = cplat.require "bufferedcontext"
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
	
	self.parent = parent
	self.children = {}
	self.functions = {}
	self.eventSystem = process.createEventSystem()
	self.context = bctx.getContext(parent.context, 0, 0, 0, 0, parent.eventSystem)
	
	self.size = class.new(Size, 0, 0)
	
	table.insert(parent.children, 1, self)
	
	parent.eventSystem.addEventListener(nil, function(d, e)
		debugger.log(e)
		--self.eventSystem.fireEvent(e, d) --TODO: Filter
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
	if self.sizeAndLocation then
		local msize = self.sizeAndLocation[1]:clone()
		local x, y = ctxu.calcPos(self.parent.context, table.unpack(self.sizeAndLocation, 2))
		size = class.new(SizePosGroup, msize, class.new(Position, x, y), msize)
		self.size = size.size:clone()
	elseif self.sizePosGroup then
		size = self.sizePosGroup.size
	end
	if self.size.width==0 or self.size.height==0 then
		if self.preferredSize then
			self.size = self.preferredSize:clone()
		else
			self.size = class.new(Size, 0, 0)
		end
	end
	self.position = size.position:clone()
	local msize = class.new(SizePosGroup, self.size, nil, size.size)
	
	for k, v in ipairs(self.children) do
		if v.sizeAndLocation then q(v.calcSizeIFN, v, msize) end
	end
	q(function()
		if self.preferredSize then self.size:set(self.size:max(self.preferredSize)) end
		if self.minSize then self.size:set(self.size:max(self.minSize)) end
		if self.maxSize then self.size:set(self.size:min(self.maxSize)) end
		size:add(self.size)
		
		self.context.setPosition(self.position.x, self.position.y)
		self.context.setDimensions(self.size.width, self.size.height)
	end)
	for k, v in ipairs(self.children) do
		if not v.sizeAndLocation then q(v.calcSizeIFN, v, msize) end
	end
end
function BlockComponent.drawIFN(q, self, hbr)
	local obg, ofg = self.context.getColors()
	local dbg, dfg = self.context.parent.getColors()
	local ocf = self.context.getClickFunction()
	self.context.setClickFunction(self.functions.onclick)
	self.context.setColors(self.color or dbg, self.textColor or dfg)
	self.context.startDraw()
	q(function()
		self.context.drawBuffer()
		self.context.endDraw()
		self.context.setColors(obg, ofg)
		self.context.setClickFunction(ocf)
	end)
	
	self.context.clear()
	
	for k, v in ipairs(self.children) do
		q(v.drawIFN, v, size)
	end
end