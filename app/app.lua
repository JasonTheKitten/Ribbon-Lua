local cplat = require()

local process = cplat.require "process"
local class = cplat.require "class"
local statics = cplat.require "statics"

local Size = cplat.require("class/size").Size
local SizePosGroup = cplat.require("class/sizeposgroup").SizePosGroup
local Position = cplat.require("class/position").Position

local BaseComponent = cplat.require("component/basecomponent").BaseComponent
local BlockComponent = cplat.require("component/blockcomponent").BlockComponent
--local Break = cplat.require("component/break").Break
local Button = cplat.require("component/button").Button
local Label = cplat.require("component/label").Label
local Span = cplat.require("component/span").Span

local COLORS = statics.get("colors")

BaseComponent.execute(function(gd)
	local rootpane = class.new(BaseComponent, gd(0), process):getDefaultComponent()
	local titlebar = class.new(Span, rootpane)
	local hamburgerIcon = class.new(Button, titlebar, "=")
	class.new(Label, titlebar, " ")
	local title = class.new(Label, titlebar, "CPlat File Explorer")
	local xButton = class.new(Button, titlebar, "X")
	
	titlebar:setSize(class.new(Size, 51, 1))
	titlebar:setColor(COLORS.LIME)
	titlebar:setTextColor(COLORS.WHITE)
	
	hamburgerIcon:setColor(COLORS.CYAN)
	
	xButton:setColor(COLORS.RED)
	xButton:setSizeAndLocation(class.new(Size, 1, 1), -1, 1, 0, 0)
	
	rootpane:ezDraw()
	
	while true do coroutine.yield() end
end) 