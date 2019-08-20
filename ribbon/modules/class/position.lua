local ribbon = require()

local class = ribbon.require "class"

local Size = ribbon.require("class/size").Size

local position = ...
local Position = {}
position.Position = Position

Position.cparents = {class.Class}
function Position:__call(x, y)
	self.x, self.y = x, y
end

function Position:add(vec)
	class.checkType(vec, Position, 3, "Position", Size)
	if vec:isA(Position) then
		self.x, self.y = self.x+vec.x, self.y+vec.y
	elseif vec:isA(Size) then
		self.x, self.y = self.x+vec.width, self.y+vec.height-1
	end
	return self
end
function Position:__add(vec)
	return Position:clone():add(vec)
end

function Position:incLine()
	self.x = 0
	self.y = self.y+1
end

function Position:clone()
	return class.new(Position, self.x, self.y)
end
function Position:set(pos)
	self.x, self.y = pos.x, pos.y
	return self
end