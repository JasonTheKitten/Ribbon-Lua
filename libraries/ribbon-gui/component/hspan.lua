local ribbon = require()

local class = ribbon.require "class"
local util = ribbon.require "util"

local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent
local Component = ribbon.require("component/component").Component

local hspan = ...
local HSpan = {}
hspan.HSpan = HSpan

HSpan.cparents = {BlockComponent}
function HSpan:__call(parent)
    if parent then class.checkType(parent, Component, 3, "Component") end
	BlockComponent.__call(self, parent)
	
	self.attributes["enable-child-wrap"] = false
end

function HSpan:queueChildrenCalcSize(q, size, values)
    for k, v in util.ripairs(self.children) do
		if not v.location then 
			q(function()
				size.position.y = 0
				v.calcSizeIFN(q, v, size, values)
			end)
		else
			values.processingQueue[#values.processingQueue+1] = {v, size}
		end
	end
end