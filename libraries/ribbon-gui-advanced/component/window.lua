local ribbon = require()

local class = ribbon.require "class"
local contextutils = ribbon.require "contextutils"
local ribbonos = ribbon.require "ribbonos"
local statics = ribbon.require "statics"

local Component = ribbon.require("component/component").Component
local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent
local Button = ribbon.require("component/button").Button
local HSpan = ribbon.require("component/hspan").HSpan
local Label = ribbon.require("component/label").Label

local COLORS = statics.get("colors")

local window = ...
local Window = {}
window.Window = Window

Window.cparents = {BlockComponent}
function Window:__call(parent, title, x, y, l, h)
	if parent then class.checkType(parent, Component, "Component") end
	BlockComponent.__call(self, parent)
	
	self:attribute(
		"location", {0, x or 5, 0, y or 5},
		"width", {0, l or 15},
		"height", {0, h or 7},
		"background-color", COLORS.YELLOW,
		"text-color", COLORS.BLACK,
		"onclick", function(e)
			if e.button==1 then
				self:setParent(self.parent)
			end
		end
	)
	
	local lx, ly
	local function handleClick(e)
		if e.button==1 then
			ribbonos.send("CURSORDATA", {clipboardtype="internal_window", clipboarddata={element=self}})
			lx, ly = e.x, e.y
		end
	end
	local function handleDrag(e)
		if e.button==1 and lx then
			self.location[2] = self.location[2]+(e.x-lx)
			self.location[4] = self.location[4]+(e.y-ly)
			lx, ly= e.x, e.y
			self:setParent(self.parent)
		end
	end
	local function handleRelease(e)
		if e.button == 1 then
			lx, ly = nil, nil
			self:setParent(self.parent)
		end
	end
	local function handleExternalRelease(e)
		if e.button == 1 then
			lx, ly = nil, nil
		end
	end
	
	class.new(HSpan, self):attribute(
		"background-color", COLORS.RED,
		"text-color", COLORS.WHITE,
		"width", {1},
		"onclick", handleClick,
		"ondrag&onexternaldrag", handleDrag,
		"onrelease", handleRelease,
		"onexternalrelease", handleExternalRelease,
		"cursor-qualifier", function(d)
			return d.clipboarddata.element==self and d.clipboardtype=="internal_window"
		end,
		"children", {
			class.new(Label, nil, " "..(title or "<New Window>")),
			class.new(Button, nil, "X"):attribute(
				"background-color", COLORS.RED,
				"selected-background-color", COLORS.ORANGE,
				"location", {1, -1},
				"onrelease", function(e)
					if e.button==1 then
						self:delete()
					end
				end
			)
		}
	)
	self.pane = class.new(BlockComponent, self):attribute(
		"width", {1},
		"height", {1, -1},
		"location", {0, 0, 0, 1}
	)
end