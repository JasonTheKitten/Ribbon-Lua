local cplat = require()

local process = cplat.require "process"
local gui = cplat.require "gui"
local bufferedContext = cplat.require "bufferedcontext"
local class = cplat.require "class"

local Size = cplat.require("class/size").Size

local component = ...
local Component = {}
component.Component = Component

function Component:getSize()
	return self.size
end
function Component:setSize(size)
	
end

function Component:setPreferredSize()
	return self.preferredSize
end

function Component:getMinimumSize()

end