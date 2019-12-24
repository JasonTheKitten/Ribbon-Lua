local ribbon = require()

local class = ribbon.require "class"
local debugger = ribbon.require "debugger"

local Size = ribbon.require("class/size").Size

local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent
local Component = ribbon.require("component/component").Component

local percentbar = ...
local PercentBar = {}
percentbar.PercentBar = PercentBar

PercentBar.cparents = {BlockComponent}
function PercentBar:__call(parent)
    if parent then class.checkType(parent, Component, 3, "Component") end
    BlockComponent.__call(self, parent)
	
	self.attributes["percent"] = 0

    self.preferredSize = class.new(Size, 8, 1)
end

function PercentBar.calcSizeIFN(q, self, size)
	if not self.parent then return end

	Component.calcSizeIFN(q, self, size)
end
function PercentBar.drawIFN(q, self)
	if not self.parent then return end

	BlockComponent.drawIFN(q, self)

	local size = self.size
	local position = self.position
	for x=0, math.ceil(size.width*self.attributes["percent"])-1 do
		self.dockcontext.drawPixel(position.x+x-1, position.y, self.attributes["bar-color"], " ")
	end
end