local cplat = require()

--local class = cplat.require "class"

local Component = cplat.require("component/component").Component

local runIFN = util.runIFN

local div = ...
local Div = {}
div.Div = Div

Div.cparents = {Component}
function Div:__call(parent)
	Component.__call(self, parent)
end