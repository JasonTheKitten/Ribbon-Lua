--TODO: Align components on top
local cplat = require()

local class = cplat.require "class"

local BlockComponent = cplat.require("component/blockcomponent").BlockComponent
local Label = cplat.require("component/label").Label

local button = ...
local Button = {}
button.Button = Button

Button.cparents = {BlockComponent}
function Button:__call(parent, text)
	BlockComponent.__call(self, parent)
	
	self.label = class.new(Label, self, text)
end