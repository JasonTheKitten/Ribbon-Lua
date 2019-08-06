--TODO: Align components on top
local cplat = require()

--local class = cplat.require "class"

local BlockComponent = cplat.require("component/blockcomponent").BlockComponent

local hspan = ...
local HSpan = {}
hspan.HSpan = HSpan

HSpan.cparents = {BlockComponent}
function HSpan:__call(parent)
	BlockComponent.__call(self, parent)
end