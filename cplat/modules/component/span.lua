--TODO: Align components on top
local cplat = require()

--local class = cplat.require "class"

local BlockComponent = cplat.require("component/blockcomponent").BlockComponent

local span = ...
local Span = {}
span.Span = Span

Span.cparents = {BlockComponent}
function Span:__call(parent)
	BlockComponent.__call(self, parent)
end