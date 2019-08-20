--TODO: Align components on top
local ribbon = require()

--local class = ribbon.require "class"

local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent

local hspan = ...
local HSpan = {}
hspan.HSpan = HSpan

HSpan.cparents = {BlockComponent}
function HSpan:__call(parent)
	BlockComponent.__call(self, parent)
end