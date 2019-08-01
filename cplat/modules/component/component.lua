local cplat = require()

local class = cplat.require "class"
local ctx = cplat.require "context"
local ctxu = cplat.require "contextutils"
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
	
	self.children = {}
	self.eventSystem = process.createEventSystem()
	self.context = parent.context
	
	table.insert(parent.children, 1, self)
	
	parent.eventSystem.addEventListener(nil, function(d, e)
		self.eventSystem.fireEvent(e, d) --TODO: Filter
	end)
end

function Component:setTextColor(c)
	self.textColor = c
end
function Component:setColor(c)
	self.color = c
end

function Component:setSizePosGroup(spg)
	self.sizePosGroup = spg
end
function Component:setSizeAndLocation(size, ax, px, ay, py, ol, oh)
	local x, y = ctxu.calcPos(self.context.parent.parent.parent, ax, px, ay, py, size.width, ol, size.height, oh)
	self:setSizePosGroup(class.new(SizePosGroup, size, class.new(Position, x, y), size))
end

function Component:calcSize(size)
	if self.sizePosGroup then
		size = self.sizePosGroup:cloneAll()
	elseif size then
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
	for k, v in ipairs(self.children) do
		q(v.calcSizeIFN, v, size)
	end
end

function Component:draw(hbr)
	runIFN(self.drawIFN, self, hbr)
end
function Component.drawIFN(q, self, hbr)
	--hbr.add({x, y, l, h})
	local obg, ofg = self.context.getColors()
	self.context.setColors(self.color, self.textColor)
	q(function()
		self.context.setColors(obg, ofg)
	end)
	for k, v in ipairs(self.children) do
		q(v.drawIFN, v)
	end
end

function Component:ezDraw()
	self:calcSize(class.new(SizePosGroup))
	self:draw(nil)
end