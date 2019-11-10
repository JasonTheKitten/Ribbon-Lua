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
end

function BlockComponent:setParent(parent)
	Component.setParent(self, parent)
	if parent and parent.context then
		self:setContextInternal()
	end
end

--Scroll
function BlockComponent:scrollY(n)
	self.context.adjustScroll(0, n)
	if self.context.scroll.y>self.scrollableSize.height-self.context.height then
		self.context.scroll.y=self.scrollableSize.height-self.context.height
	end
	if self.context.scroll.y<0 then self.context.scroll.y = 0 end
	self:fireUpdateEvent()
end

--IFN functions
function BlockComponent:mCalcSize(q, size)
    self.enableWrap = self.parent.enableChildWrap and self.attributes["enable-wrap"]
    self.enableChildWrap = self.attributes["enable-child-wrap"]
    
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
    
	local maxsize = self.maxSize or (size.maxSize and size.maxSize:clone():subtractLH(self.position.x, self.position.y)) or nil
	local msize = class.new(SizePosGroup, self.size, nil, maxsize)
	
	q(function()
		self.scrollableSize = self.size:clone()
		if self.minSize then self.size:set(self.size:max(self.minSize)) end
		if self.maxSize then self.size:set(self.size:min(self.maxSize)) end
		
		if not (self.attributes["location"] or self.attributes["dock"]) then
			size:add(self.size)
			size:fixCursor(self.enableWrap)
		else
			--TODO: Alternate logic
		end
		
		self.context.setPosition(self.position.x, self.position.y)
		self.context.setDimensions(self.size.width, self.size.height)
	end)
	self:queueChildrenCalcSize(q, msize)
end
function BlockComponent:setContextInternal()
	self.dockcontext = (self.attributes["dock"] and self.attributes["dock"].childcontext) or self.parent.childcontext
	self.context = self.context or sctx.getContext(self.parent.childcontext, 0, 0, 0, 0)
	self.context.setParent(self.dockcontext)
	self.childcontext = self.context
end
function BlockComponent.drawIFN(q, self)
	if not self.parent then return end
	
	local obg, ofg = self.context.getColors()
	local dbg, dfg = self.parent.context.getColors()
	local of = self.context.getFunctions()
	self.context.setFunction("onclick", self.triggers.onclick)
	self.context.setFunction("ondrag", self.triggers.ondrag)
	self.context.setFunction("onrelease", self.triggers.onrelease)
	self.context.setColorsRaw(self.color or dbg, self.textColor or dfg)
	self.context.startDraw()
	q(function()
		self.context.endDraw()
		self.context.setColorsRaw(obg, ofg)
		self.context.setFunctions(of)
	end)
	
	self.context.clear()
	
	for k, v in util.ripairs(self.children) do q(v.drawIFN, v) end
end