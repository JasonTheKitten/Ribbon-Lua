local cplat = require()

local process = cplat.require "process"
local class = cplat.require "class"

local Size = cplat.require("class/size").Size

local BaseComponent = cplat.require("component/basecomponent").BaseComponent
local BlockComponent = cplat.require("component/blockcomponent").BlockComponent
local Break = cplat.require("component/break").Break
local Label = cplat.require("component/label").Label
local Span = cplat.require("component/span").Span

BaseComponent.execute(function(gd)
	local rootpane = class.new(BaseComponent, gd(), process):getDefaultComponent()
	local titlebar = class.new(Span, rootpane)
	local title = class.new(Label, titlebar, ("CPlat "):rep(30))
	--\nWhen progressing through Terraria, many players can be confused about where they should go and what they should do next. Terraria is an open-ended game: you are not forced to go anywhere or do anything. You are free to set your own goals and follow through with them, whether you are a builder, fighter, explorer, collector, or whatever else. This walkthrough merely aims to provide a logical order of progression through Terraria’s many different biomes, generally in order of increasing difficulty. It is recommended, but there is certainly no requirement to visit each biome, or even in this order if you don't want to.")
	rootpane:ezDraw()
end) 