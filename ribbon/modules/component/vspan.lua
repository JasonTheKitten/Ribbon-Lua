--TODO: Align components on side
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