local ribbon = require()

local class = ribbon.require "class"
local macro = ribbon.require "macro"
local statics = ribbon.require "statics"

local Component = ribbon.require("component/component").Component
local TextBox = ribbon.require("component/textbox").TextBox

local KEYS = statics.get("KEYS")

local textfield = ...

local TextField = {}
textfield.TextField = TextField

TextField.cparents = {TextBox}
function TextField:__call(parent)
    if parent then class.checkType(parent, Component, 3, "Component")
    TextBox.__call(selff, parent)
    
    self.macroSystem.unregister("enter")
    self.macroSystem.register({KEYS.ENTER}, function()
        if self.attributes["onsubmit"] then
            self.attributes["onsubmit"]()
        end
    end, "enter")
end