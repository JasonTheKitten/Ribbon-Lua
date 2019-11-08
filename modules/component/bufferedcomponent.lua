local ribbon = require()

local class = ribbon.require "class"
local bctx = ribbon.require "bufferedcontext"
local ctxu = ribbon.require "contextutils"
local debugger = ribbon.require "debugger"
local util = ribbon.require "util"

local Size = ribbon.require("class/size").Size
local SizePosGroup = ribbon.require("class/sizeposgroup").SizePosGroup
local Position = ribbon.require("class/position").Position

local Component = ribbon.require("component/component").Component
local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent

local runIFN = util.runIFN

local bufferedcomponent = ...
local BufferedComponent = {}
bufferedcomponent.BufferedComponent = BufferedComponent

BufferedComponent.cparents = {BlockComponent}
BufferedComponent.__call = BlockComponent.__call

function BufferedComponent:setParent(parent)
	Component.setParent(self, parent)
	if parent and parent.context then
		self:setContextInternal()
	end
end

--IFN functions
function BufferedComponent:setContextInternal()
	self.dockcontext = (self.attributes["dock"] and self.attributes["dock"].context) or self.parent.childcontext
	self.context = self.context or bctx.getContext(self.parent.context, 0, 0, 0, 0, self.parent.eventSystem)
	self.context.setParent(self.dockcontext)
	self.childcontext = self.context
end
function BufferedComponent.drawIFN(q, self, hbr)
	if not self.parent then return end
	
	local of = self.context.getFunctions()
	self.context.setFunction("onclick", self.handlers.onclick)
	self.context.setFunction("ondrag", self.handlers.ondrag)
	self.context.setFunction("onrelease", self.handlers.onrelease)
	
	local obg, ofg = self.context.getColors()
	local dbg, dfg = self.parent.context.getColors()
	self.context.setColorsRaw(self.color or dbg, self.textColor or dfg)
	self.context.startDraw()
	
	q(function()
		self.context.endDraw()
		self.context.setColorsRaw(obg, ofg)
		self.context.setFunctions(of)
		
		local ofp
		if self.dockcontext.setFunction then
			ofp = self.dockcontext.getFunctions()
			self.dockcontext.useFunctions(self.context.triggers)
		end
		self.context.drawBuffer()
		if ofp then
			self.dockcontext.setFunctions(ofp)
		end
	end)
	
	self.context.clear()
	
	for k, v in util.ripairs(self.children) do
		q(v.drawIFN, v, size)
	end
end