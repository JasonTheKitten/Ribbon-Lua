local cplat = require()

local class = cplat.require "class"

local size = ...
local Size = {}
size.Size = Size

Size.cparents = {class.Class}
function Size:__call(w, h)
	self.width, self.height = math.abs(w), math.abs(h)
end
function Size:getWidth()
	return self.width
end
function Size:getHeight()
	return self.height
end
function Size:clone()
	return class.new(Size, self.width, self.height)
end