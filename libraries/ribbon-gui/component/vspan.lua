local ribbon = require()

local class = ribbon.require "class"

local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent
local Component = ribbon.require("component/component").Component

local vspan = ...
local VSpan = {}
vspan.VSpan = VSpan

VSpan.cparents = {BlockComponent}
function VSpan:__call(parent)
    if parent then class.checkType(parent, Component, 3, "Component") end
	BlockComponent.__call(self, parent)
end

function VSpan:queueChildrenCalcSize(q, size)
    for k, v in util.ripairs(self.children) do
		if not v.location then
			q(function()
				if size.position.x > 0 then size:incLine() end
                v.calcSizeIFN(q, v, size)
			end)
		else
			values.processingQueue[#values.processingQueue+1] = {v, size}
		end
	end
end