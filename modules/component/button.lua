local ribbon = require()

local class = ribbon.require "class"

local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent
local Component = ribbon.require("component/component").Component
local Label = ribbon.require("component/label").Label

local button = ...
local Button = {}
button.Button = Button

Button.cparents = {BlockComponent}
function Button:__call(parent, text)
    if parent then class.checkType(parent, Component, 2, "Component") end
	BlockComponent.__call(self, parent)
	self.label = class.new(Label, self, text)
end