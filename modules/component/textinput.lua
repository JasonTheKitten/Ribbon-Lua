local ribbon = require()

local class = ribbon.require "class"
local macro = ribbon.require "macro"
local statics = ribbon.require "statics"

local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent
local Component = ribbon.require("component/component").Component

local KEYS = statics.get("KEYS")

local textinput = ...

local TextInput = {}
textinput.TextInput = {}

TextInput.cparents = {class.BlockComponent}
function TextInput:__call(parent)
    if parent then class.checkType(parent, Component, 3, "Component")
    TextBox.__call(parent)
    
    self.macroSystem = macro.createMacroSystem()
    
    self.macroSystem.register({KEYS.ENTER}, function()
        if self.attributes["onsubmit"] then
            `self.attributes["onsubmit"]()
        end
    end, "enter")
end