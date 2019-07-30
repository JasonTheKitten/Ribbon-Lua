local cplat = require()

local class = cplat.require "class"

local Size = cplat.require("class/size").Size
local Position = cplat.require("class/position").Position

local sizeposgroup = ...
local SizePosGroup = {}
sizeposgroup.SizePosGroup = SizePosGroup

SizePosGroup.cparents = {class.Class}
function SizePosGroup:__call(size, pos)
	if size then class.checkType(size, Size, 4, "Size") end
	if position then class.checkType(pos, Position, 4, "Position") end
	
	self.size = size or class.new(Size, 0, 0)
	self.position = pos or class.new(Position, 0, 0)
end

function SizePosGroup:add(size)
	class.checkType(size, Size, 3, "Size", Position, SizePosGroup)
	if size:isA(SizePosGroup) then size = size.size end
	if (size:isA(Size)) then
		self.position:add(size)
		self:fixSize()
	elseif size:isA(Position) then
		self.position:set(self.position+size)
		self:fixSize()
	end
	return self
end
function SizePosGroup:__add(size)
	return self:cloneAll():add(size)
end

function SizePosGroup:fixSize()
	self.size.width = (self.size.width<self.position.x and self.position.x) or self.size.width
	self.size.height = (self.size.height<self.position.y and self.position.y) or self.size.height
end

function SizePosGroup:toSize()
	return self.size
end
function SizePosGroup:toPosition()
	return self.position
end

function SizePosGroup:set(spg)
	self.size = spg.size
	self.position = spg.position
end

function SizePosGroup:clone()
	return class.new(SizePosGroup, self.size, self.position)
end
function SizePosGroup:cloneAll()
	return class.new(SizePosGroup, self.size:clone(), self.position:clone())
end