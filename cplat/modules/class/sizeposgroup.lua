local cplat = require()

local class = cplat.require "class"

local Size = cplat.require("class/size").Size
local Position = cplat.require("class/position").Position

local sizeposgroup = ...
local SizePosGroup = {}
sizeposgroup.SizePosGroup = SizePosGroup

SizePosGroup.cparents = {class.Class}
function SizePosGroup:__call(size, pos, maxSize)
	if size then class.checkType(size, Size, 4, "Size") end
	if pos then class.checkType(pos, Position, 4, "Position") end
	if maxSize then class.checkType(maxSize, Size, 4, "Size") end
	
	self.size = size or class.new(Size, 0, 0)
	self.position = pos or class.new(Position, 0, 0)
	self.maxSize = maxSize or self.size:clone()
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

function SizePosGroup:incCursor(ew)
	self:fixSize()
	self.position.x=self.position.x+1
	if ew~=false and self.position.x>=self.size.width and not self:canExpandWidth() then
		self.position.x = 0
		self.position.y = self.position.y+1
		return true
	end
end
function SizePosGroup:incLine()
	self.position:incLine()
end

function SizePosGroup:canExpandWidth(inc)
	return self.size.width+(inc or 1) <= self.maxSize.width
end
function SizePosGroup:expandWidth(inc)
	inc = inc or 1
	if self:canExpandWidth(inc) then
		self.size.width = self.size.width + inc
		return true
	end
end

function SizePosGroup:fixSize()
	self.size.width = (self.size.width<(self.position.x+1) and self.position.x+1) or self.size.width
	self.size.height = (self.size.height<=(self.position.y+1) and self.position.y+1) or self.size.height
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
	self.maxSize = spg.maxSize
end

function SizePosGroup:clone()
	return class.new(SizePosGroup, self.size, self.position, self.maxSize)
end
function SizePosGroup:cloneAll()
	return class.new(SizePosGroup, self.size:clone(), self.position:clone(), self.maxSize:clone())
end