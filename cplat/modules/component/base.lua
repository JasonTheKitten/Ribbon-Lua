local cplat = require()

local process = cplat.require "process"
local class = cplat.require "class"

local component = cplat.require "component/component"

local basec = ...
local basecc = {}

basec.BaseComponent = basecc

basecc.cparents = {component.Component}
function basecc:__call(ctx, es)
	self.context = ctx
	self.eventSystem = process.createEventSystem()
	es.addEventListener(nil, function(d, e)
		self.eventSystem.fire(e, d) --TODO: Filter
	end)
end