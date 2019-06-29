local cplat = require()

local class = cplat.require "class"
local gui = cplat.require "gui"
local process = cplat.require "process"

local baseComponent = class.new(cplat.require("component/base").BaseComponent, gui.getDefaultContext(), process)
local apppaneComponent = class.new(cplat.require("component/apppane.lua"))