--TODO: Bounce off of walls

local ribbon = require()

local class = ribbon.require "class"
local statics = ribbon.require "statics"
local debugger = ribbon.require "debugger"

local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent
local Break = ribbon.require("component/break").Break
local Button = ribbon.require("component/button").Button
local Component = ribbon.require("component/component").Component
local Label = ribbon.require ("component/label").Label

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
		"background-color",  COLORS.LIGHTGRAY,
		"text-color", COLORS.BLACK
	) end
end
function Menu:delete()
	Component.delete(self)
	self:purgeMenuChildren()
end
function Menu:purgeMenuChildren()
	for i=#self.children, 1, -1 do
		if self.children[i]:isA(Menu) then
			self.children[i]:delete()
		end
	end
end

function Menu:processAttributes(updated)
	Component.processAttributes(self, updated)

	if updated["options"] then
		self:removeChildren()
		local maxWidth, padding = 0, (" "):rep(self.attributes["padding"] or 1)
		for k=1, #self.attributes["options"] do
			local v=self.attributes["options"][k]
			if type(v) == "string" then v = {v} end
			local padded = v[1]..padding
			maxWidth = (maxWidth>#padded and maxWidth) or #padded
			local itemComponent = ((v[2] and class.new(Button, nil, v[1])) or class.new(Label, nil, v[1].."\n")):attribute("width", {1})
			itemComponent:attribute(
				"onclick&ondrag", function(e)
					if e.button == 1 then
						self:purgeMenuChildren()
					end
				end
			)
			if not v[2] or v[2]==true then
				itemComponent:attribute("parent", self)
			elseif type(v[2]) == "function" then
				itemComponent:attribute(
					"parent", self,
					"onrelease", function(e) --TODO: Drag+Click
						if e.button == 1 then
							self:delete()
							v[2]()
						end
					end
				)
			elseif type(v[2]) == "table" then
				itemComponent:attribute(
					"parent", self,
					"onclick&ondrag", function(e)
						if e.button == 1 then
							self:purgeMenuChildren()
							class.new(Menu, self):attribute(
								"parent", self,
								"options", v[2],
								"location", {0, self.position.x+self.size.width, 0, e.y},
								"background-color", self.attributes["background-color"] or COLORS.LIGHTGRAY,
								"text-color", self.attributes["text-color"] or COLORS.BLACK,
								"selected-background-color", self.attributes["selected-background-color"],
								"selected-text-color", self.attributes["selected-text-color"]
							)
						end
					end
				)
			end

			--class.new(Break, self)
		end
		self.attributes["width"] = {0, maxWidth}
	end
	
	self.color = self.attributes["background-color"]
	self.textColor = self.attributes["text-color"]
	
	if updated["selected-background-color"] then
		for i=1, #self.children do
			local child = self.children[i]
			if not child:isA(Label) then
				child:attribute(
					"selected-background-color", self.attributes["selected-background-color"]
				)
			end
		end
	end
	if updated["selected-text-color"] then
		for i=1, #self.children do
			local child = self.children[i]
			if not child:isA(Label) then
				child:attribute(
					"selected-text-color", self.attributes["selected-text-color"]
				)
			end
		end
	end
end