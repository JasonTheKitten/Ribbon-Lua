--TODO: Align components on top
local ribbon = require()

local class = ribbon.require "class"

local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent
local Component = ribbon.require("component/component").Component

local hspan = ...
local HSpan = {}
hspan.HSpan = HSpan

HSpan.cparents = {BlockComponent}
function HSpan:__call(parent)
    if parent then class.checkType(parent, Component, 3, "Component") end
	BlockComponent.__call(self, parent)
end