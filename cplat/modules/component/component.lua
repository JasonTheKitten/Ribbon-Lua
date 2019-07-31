local cplat = require()

--local bctx = cplat.require "bufferedcontext"
local class = cplat.require "class"
local ctx = cplat.require "context"
local process = cplat.require "process"
local util = cplat.require "util"

local Size = cplat.require("class/size").Size
local SizePosGroup = cplat.require("class/sizeposgroup").SizePosGroup

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
		self.eventSystem.fire(e, d) --TODO: Filter
	end)
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
	for k, v in ipairs(self.children) do
		q(v.calcSizeIFN, v, size)
	end
end

function Component:draw(hbr)
	runIFN(self.drawIFN, self, hbr)
end
function Component.drawIFN(q, self, hbr)
	--hbr.add({x, y, l, h})
	for k, v in ipairs(self.children) do
		q(v.drawIFN, v, size)
	end
end

function Component:ezDraw()
	self:calcSize(class.new(SizePosGroup))
	self:draw(nil)
end