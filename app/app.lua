local cplat = require()

local process = cplat.require "process"
local class = cplat.require "class"
local debugger = cplat.require "debugger"
local statics = cplat.require "statics"
local util = cplat.require "util"

local Size = cplat.require("class/size").Size
local SizePosGroup = cplat.require("class/sizeposgroup").SizePosGroup
local Position = cplat.require("class/position").Position

local BaseComponent = cplat.require("component/basecomponent").BaseComponent
local BlockComponent = cplat.require("component/blockcomponent").BlockComponent
local Break = cplat.require("component/break").Break
local Button = cplat.require("component/button").Button
local Label = cplat.require("component/label").Label
local HSpan = cplat.require("component/hspan").HSpan

local COLORS = statics.get("colors")


local running, doRefresh, menuOpen, doMenuOpen = true, true, false, false
BaseComponent.execute(function(gd)
	local baseContext = gd(0)
	
	local basecomponent = class.new(BaseComponent, baseContext, process)
	local viewport = basecomponent:getDefaultComponent()
	local contentpane = class.new(BlockComponent, viewport)
	local titlebar = class.new(HSpan, contentpane)
	local hamburgerIcon = class.new(Button, titlebar, "=")
	class.new(Label, titlebar, " ")
	local title = class.new(Label, titlebar, "CPlat File Explorer")
	local xButton = class.new(Button, titlebar, "X")
	
	--Hamburger Menu
	local menuTitle = " Quick Start "
		
	local sidebar = class.new(BlockComponent, viewport)
	sidebar:delete()
	sidebar:setSizeAndLocation(class.new(Size, #menuTitle, 1), 0, 0, 1, 0)
	sidebar:setAutoSize(nil, nil, 1, -1)
	sidebar:setColor(COLORS.GREEN)
	
	class.new(Break, sidebar)
	class.new(Label, sidebar, menuTitle):setTextColor(COLORS.WHITE)
	--End
	
	contentpane:setAutoSize(1, 0, 1, 0)
	contentpane:setColor(COLORS.WHITE)
	contentpane:onClick(function()
		menuOpen = doMenuOpen
		if doMenuOpen then 
			sidebar:setParent(viewport)
		else
			sidebar:delete()
		end
		doRefresh, doMenuOpen = true, false
	end)
	
	titlebar:setAutoSize(1)
	titlebar:setColor(COLORS.LIME)
	titlebar:setTextColor(COLORS.WHITE)
	
	hamburgerIcon:setColor(COLORS.CYAN)
	hamburgerIcon:onClick(function()
		if not menuOpen then doMenuOpen = true end
	end)
	
	xButton:setColor(COLORS.RED)
	xButton:setSizeAndLocation(class.new(Size, 1, 1), -1, 1, 0, 0)
	xButton:onClick(function() running = false end)
	
	basecomponent:ezDraw()
	
	while running do
		coroutine.yield()
		doRefresh = doRefresh or basecomponent:update()
		if doRefresh then 
			basecomponent:ezDraw()
			doRefresh = false
		end
	end
	baseContext.clear(COLORS.BLACK)
end) 