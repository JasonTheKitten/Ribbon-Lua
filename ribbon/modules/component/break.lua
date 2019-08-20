local ribbon = require()

--local bctx = ribbon.require "bufferedcontext"
local class = ribbon.require "class"
local ctx = ribbon.require "context"
local process = ribbon.require "process"
local util = ribbon.require "util"

local Size = ribbon.require("class/size").Size

local Component = ribbon.require("component/component").Component

local runIFN = util.runIFN

local breakc = ...
local Break = {}
breakc.Break = Break

Break.cparents = {Component}
function Break:__call(parent)
	class.checkType(parent, Component, 3, "Component")
	
	Component.__call(self, parent)
end

--IFN functions
function Break.calcSizeIFN(q, self, size)
	size.position:incLine()
	Component.calcSizeIFN(q, self, size)
end