local cplat = require()

local class = cplat.require "class"
local ctx = cplat.require "context"
local ctxu = cplat.require "contextutils"
local debugger = cplat.require "debugger"
local process = cplat.require "process"
local util = cplat.require "util"

local Size = cplat.require("class/size").Size
local SizePosGroup = cplat.require("class/sizeposgroup").SizePosGroup
local Position = cplat.require("class/position").Position

local runIFN = util.runIFN

local component = ...
local Component = {}
component.Component = Component

Component.cparents = {class.Class}
function Component:__call(parent)
	class.checkType(parent, Component, 4, "Component")
	
	self.parent = parent
	self.children = {}
	self.functions = {}
	self.eventSystem = process.createEventSystem()
	self.context = parent.context
	
	table.insert(parent.children, 1, self)
	
	parent.eventSystem.addEventListener(nil, function(d, e)
		debugger.log(e)
		--self.eventSystem.fireEvent(e, d) --TODO: Filter
	end)
end

function Component:removeChild(child)
	for k, v in pairs(self.children) do
		if rawequal(child, v) then
			table.remove(self.children, k)
			break
		end
	end
end
function Component:delete()
	if self.parent then
		self.parent:removeChild(self)
	end
end
function Component:setParent(parent)
	self:delete()
	if parent then
		self.parent = parent
		table.insert(parent.children, 1, self)
	end
end

function Component:setTextColor(c)
	self.textColor = c
end
function Component:setColor(c)
	self.color = c
end

function Component:onClick(f)
	self.functions.onclick = f
end
function Component:getOnClick()
	return self.functions.onclick
end

function Component:setSizePosGroup(spg)
	self.sizePosGroup = spg
end
function Component:setSizeAndLocation(size, ax, px, ay, py, ol, oh)
	self.sizeAndLocation = {size, ax, px, ay, py, size.width, ol, size.height, oh}
end
function Component:clearSizeOverrides()
	self.sizePosGroup = nil
	self.sizeAndLocation = nil
end

function Component:calcSize(size)
	if size then
		class.checkType(size, SizePosGroup, 3, "SizePosGroup", Size)
		if size:isA(Size) then
			size = class.new(SizePosGroup, size)
		end
	else
		size = class.new(SizePosGroup)
	end
	runIFN(self.calcSizeIFN, self, size)
end
function Component.calcSizeIFN(q, self, size)
	if self.sizeAndLocation then
		local msize = self.sizeAndLocation[1]
		local x, y = ctxu.calcPos(self.parent.context, table.unpack(self.sizeAndLocation, 2))
		size = class.new(SizePosGroup, msize, class.new(Position, x, y), msize)
	else
		size = self.sizePosGroup or size
	end
	for k, v in ipairs(self.children) do
		if v.sizeAndLocation then q(v.calcSizeIFN, v, msize) end
	end
	for k, v in ipairs(self.children) do
		if not v.sizeAndLocation then q(v.calcSizeIFN, v, size) end
	end
end

function Component:draw(hbr)
	runIFN(self.drawIFN, self, hbr)
end
function Component.drawIFN(q, self, hbr)
	--hbr.add({x, y, l, h})
	local obg, ofg = self.context.getColors()
	local ocf = self.context.getClickFunction()
	self.context.setClickFunction(function(e, d)
		debugger.log(e)
		self.eventSystem.fireEvent(e, d)
		if self.functions.onclick then self.functions.onclick(e, d) end
	end)
	self.context.setColors(self.color, self.textColor)
	q(function()
		self.context.setColors(obg, ofg)
		self.context.setClickFunction(ocf)
	end)
	for k, v in ipairs(self.children) do
		if not v.sizePosGroup then q(v.drawIFN, v) end
	end
end

function Component:ezDraw()
	self:calcSize(class.new(SizePosGroup))
	self:draw(nil)
end