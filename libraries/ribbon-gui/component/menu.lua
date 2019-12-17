--TODO: Fix handling of selected-*-color

local ribbon = require()

local class = ribbon.require "class"
local statics = ribbon.require "statics"

local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent
local Break = ribbon.require("component/break").Break
local Button = ribbon.require("component/button").Button
local Component = ribbon.require("component/component").Component
--local Label = ribbon.require ("component/label").Label

local COLORS = statics.get("colors")

local menu = ...
local Menu = {}
menu.Menu = Menu

Menu.cparents = {BlockComponent}
function Menu:__call(parent)
	if parent then class.checkType(parent, Component, 3, "Component") end
	BlockComponent.__call(self, parent)

	if parent then self:attribute(
		"parent", parent:getBaseComponent():getDefaultComponent(),
		"dock", parent:getBaseComponent():getDefaultComponent(),
		"background-color", COLORS.LIGHTGRAY,
		"text-color", COLORS.BLACK,
		"depth", {}
	) end
	self:addEventListener("external_click", function()
		self:delete()
	end)
end
function Menu:processAttributes(updated)
	Component.processAttributes(self, updated)

	if updated["options"] then
		self:removeChildren()
		for k, v in ipairs(self.attributes["options"]) do
			if type(v) == "string" then v = {v} end
			local itemComponent = (type(v[1]) == "string" and class.new(Button, nil, v[1])) or v[1]
			if not v[2] then
				itemComponent:attribute("parent", self, "onclick", nil)
			elseif type(v[2]) == "function" then
				itemComponent:attribute(
					"parent", self,
					"onclick", function(e)
						if e.button == 1 then
							self:delete()
							v[2]()
						end
					end
				)
			elseif type(v[2]) == "table" then
				itemComponent:attribute(
					"parent", self,
					"onclick", function(e)
						if e.button == 1 then
							class.new(Menu, self):attribute(
								"parent", self,
								"options", v[2],
								"location", {0, self.position.x+self.size.width, 0, e.y}
							)
						end
					end
				)
			end

			class.new(Break, self)
		end
	end
	if updated["selected-text-color"] or updated["selected-background-color"] then
            
	end
end