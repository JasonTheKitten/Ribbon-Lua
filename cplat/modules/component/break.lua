local cplat = require()

--local bctx = cplat.require "bufferedcontext"
local class = cplat.require "class"
local ctx = cplat.require "context"
local process = cplat.require "process"
local util = cplat.require "util"

local Size = cplat.require("class/size").Size

local Component = cplat.require("component/component").Component

local runIFN = util.runIFN

local breakc = ...
local Break = {}
breakc.Break = Break

Break.cparents = {Component}
function Break:__call(parent)
	class.checkType(parent, Component, 3, "Component")
	
	self.children = {}
	self.eventSystem = process.createEventSystem()
	self.context = parent.context
	
	table.insert(parent.children, 1, self)
	
	parent.eventSystem.addEventListener(nil, function(d, e)
		self.eventSystem.fire(e, d) --TODO: Filter
	end)
end

--IFN functions
function Break.calcSizeIFN(q, self, size)
	size.position:incLine()
	for k, v in pairs(self.children) do
		q(v.calcSizeIFN, v, size)
	end
end