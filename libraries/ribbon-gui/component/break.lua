--TODO: Probably something from another file, but BlockComponents of full width seem to auto-wrap, which may not be intended.
--Ribbon needs a good, solid cleaning (:
local ribbon = require()

local Component = ribbon.require("component/component").Component

local breakc = ...
local Break = {}
breakc.Break = Break

Break.cparents = {Component}
Break.__call = Component.__call

function Break.calcSizeIFN(q, self, size, values)
	size.position:incLine()
	Component.calcSizeIFN(q, self, size, values)
end