local ribbon = require()

local class = ribbon.require "class"

local Component = ribbon.require("component/component").Component

local runIFN = util.runIFN

local div = ...
local Div = {}
div.Div = Div

Div.cparents = {Component}
function Div:__call(parent)
    if parent then class.checkType(parent, Component, 3, "Component") end
	Component.__call(self, parent)
end