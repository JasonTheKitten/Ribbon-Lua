local cplat = require()

local class = cplat.require "class"
local util = cplat.require "util"

local Size = cplat.require("class/size").Size

local BlockComponent = cplat.require("component/blockcomponent").BlockComponent

local runIFN = util.runIFN

local span = ...
local Span = {}
span.Span = Span

Span.cparents = {BlockComponent}
function Span:__call(parent)
	BlockComponent.__call(self, parent)
	self.color = 5
end