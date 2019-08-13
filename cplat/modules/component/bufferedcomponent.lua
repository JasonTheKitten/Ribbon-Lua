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
local BlockComponent = cplat.require("component/blockcomponent").BlockComponent

local runIFN = util.runIFN

local bufferedcomponent = ...
local BufferedComponent = {}
bufferedcomponent.BufferedComponent = BufferedComponent

BufferedComponent.cparents = {BlockComponent}
function BufferedComponent:__call(parent)
	class.checkType(parent, Component, 3, "Component")
	
	Component.__call(self, parent)
	
	self.size = class.new(Size, 0, 0)
	self.autoSize = {}
end

function BufferedComponent:setParent(parent)
	Component.setParent(self, parent)
	if parent and parent.context then
		self.context = bctx.getContext(parent.context, 0, 0, 0, 0, parent.eventSystem)
	end
end

--IFN functions
function BufferedComponent.calcSizeIFN(q, self, size)
	if not self.parent then return end

	self.context = self.context or bctx.getContext(self.parent.context, 0, 0, 0, 0, self.parent.eventSystem)
	self.context.parent = self.parent.context
	
	local osize = size
	if self.sizeAndLocation then
		local msize = self.sizeAndLocation[1]:clone()
		local x, y = ctxu.calcPos(self.parent.context, table.unpack(self.sizeAndLocation, 2))
		size = class.new(SizePosGroup, msize, class.new(Position, x, y), msize)
		self.size = size.size:clone()
	elseif self.sizePosGroup then
		size = self.sizePosGroup
	end
	if self.size.width==0 or self.size.height==0 then
		if self.preferredSize then
			self.size = self.preferredSize:clone()
		else
			self.size = class.new(Size, 0, 0)
		end
	end
	if self.autoSize[1] or self.autoSize[2] then
		self.size.width = osize.size.width*(self.autoSize[1] or 0) + (self.autoSize[2] or 0)
	end
	if self.autoSize[3] or self.autoSize[4] then
		self.size.height = osize.size.height*(self.autoSize[3] or 0) + (self.autoSize[4] or 0)
	end
	
	self.position = size.position:clone()
	local msize = class.new(SizePosGroup, self.size, nil, size.size)
	
	for k, v in util.ripairs(self.children) do
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
	for k, v in util.ripairs(self.children) do
		if not v.sizeAndLocation then q(v.calcSizeIFN, v, msize) end
	end
end
function BufferedComponent.drawIFN(q, self, hbr)
	if not self.parent then return end
	
	local obg, ofg = self.context.getColors()
	local dbg, dfg = self.context.parent.getColors()
	local ocf = self.context.getClickFunction()
	self.context.setClickFunction(self.handlers.onclick)
	self.context.setColorsRaw(self.color or dbg, self.textColor or dfg)
	self.context.startDraw()
	q(function()
		self.context.endDraw()
		self.context.setColorsRaw(obg, ofg)
		self.context.setClickFunction(ocf)
		
		local ocfp
		if self.context.parent.setClickFunction then
			ocfp = self.context.parent.getClickFunction()
			self.context.parent.setClickFunction(self.context.triggers.onclick)
		end
		self.context.drawBuffer()
		if ocfp then
			self.context.parent.setClickFunction(ocfp)
		end
	end)
	
	self.context.clear()
	
	for k, v in util.ripairs(self.children) do
		q(v.drawIFN, v, size)
	end
end