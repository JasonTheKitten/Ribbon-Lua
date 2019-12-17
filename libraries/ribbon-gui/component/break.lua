local ribbon = require()

local Component = ribbon.require("component/component").Component

local breakc = ...
local Break = {}
breakc.Break = Break

Break.cparents = {Component}
Break.__call = Component.__call

function Break.calcSizeIFN(q, self, size)
	size.position:incLine()
	Component.calcSizeIFN(q, self, size)
end