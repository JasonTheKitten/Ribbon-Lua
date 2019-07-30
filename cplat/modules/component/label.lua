local cplat = require()

--local bctx = cplat.require "bufferedcontext"
local class = cplat.require "class"
local ctx = cplat.require "context"
local process = cplat.require "process"
local util = cplat.require "util"

local Size = cplat.require("class/size").Size

local Component = cplat.require("component/component").Component

local runIFN = util.runIFN

local label = ...
local Label = {}
label.Label = Label

Label.cparents = {Component}
function Label:__call(parent, text)
	class.checkType(parent, Component, 3, "Component")
	
	self.children = {}
	self.eventSystem = process.createEventSystem()
	self.context = parent.context
	
	self.text = text
	
	table.insert(parent.children, 1, self)
	
	parent.eventSystem.addEventListener(nil, function(d, e)
		self.eventSystem.fire(e, d) --TODO: Filter
	end)
end

--IFN functions
function Label.calcSizeIFN(q, self, size)
	self.position = size.position:clone()

	size:add(class.new(Size, #self.text, 0))
	for k, v in pairs(self.children) do
		q(v.calcSizeIFN, v, size)
	end
end
function Label.drawIFN(q, self, hbr)
	self.context.drawText(self.position.x, self.position.y, self.text, 0, 15)
end