--TODO
local ribbon = require()

local class = ribbon.require "class"

local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent
local Component = ribbon.require("component/component").Component

local grid = ...
local Grid = {}
grid.Grid = Grid

Grid.cparents = {BlockComponent}
function Grid:__call(parent)
    if parent then class.checkType(parent, Component, 3, "Component") end
	BlockComponent.__call(self, parent)
end