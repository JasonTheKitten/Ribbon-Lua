local cplat = require()

local process = cplat.require "process"
local contextapi = cplat.require "context"
local displayapi = cplat.require "display"
local bctx = cplat.require "bufferedcontext"
local ctxu = cplat.require "contextutils"
local statics = cplat.require "statics"
local class = cplat.require "class"

local BaseComponent = cplat.require("component/basecomponent").BaseComponent
local BlockComponent = cplat.require("component/blockcomponent").BlockComponent
local Label = cplat.require("component/label").Label
local Break = cplat.require("component/break").Break

BaseComponent.execute(function(gd)
	local bc = class.new(BaseComponent, gd(), process)
	local bc2 = class.new(BlockComponent, bc)
	local lb = class.new(Label, bc2, "Text")
	local lb2 = class.new(Label, bc2, "-A-Thon")
	local br = class.new(Break, bc2)
	local lb3 = class.new(Label, bc2, "This is *totally* a test")
	bc:ezDraw()
end)

