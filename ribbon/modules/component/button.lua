--TODO: Align components on top
local ribbon = require()

local class = ribbon.require "class"

local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent
local Label = ribbon.require("component/label").Label

local button = ...
local Button = {}
button.Button = Button

Button.cparents = {BlockComponent}
function Button:__call(parent, text)
	BlockComponent.__call(self, parent)
	
	self.label = class.new(Label, self, text)
end