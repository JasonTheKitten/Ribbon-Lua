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
function Size:set(size)
	self.width, self.height = size.width, size.height
	return self
end

function Size.min(size1, size2)
	return class.new(Size, 
		(size1.width<size2.width and size1.width) or size2.width,
		(size1.height<size2.height and size1.height) or size2.height)
end
function Size.max(size1, size2)
	return class.new(Size, 
		(size1.width>size2.width and size1.width) or size2.width,
		(size1.height>size2.height and size1.height) or size2.height)
end