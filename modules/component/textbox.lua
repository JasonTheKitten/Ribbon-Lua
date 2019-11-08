local ribbon = require()

local class = ribbon.require "class"
local macro = ribbon.require "macro"
local statics = ribbon.require "statics"

local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent
local Component = ribbon.require("component/component").Component

local textbox = ...

local TextBox = {}
textbox.TextBox = {}

TextBox.cparents = {class.BlockComponent}
function TextBox:__call(parent)
    if parent then class.checkType(parent, Component, 3, "Component")
    BlockComponent.__call(parent)
end