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
	self.maxSize = maxSize
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

function SizePosGroup:fixCursor(ew)
	if ew~=false and self.position.x>=self.size.width and not self:canExpandWidth() then
		self.position:incLine()
		return true
	end
end
function SizePosGroup:incCursor(ew)
	self.position.x=self.position.x+1
	self:fixSize()
	return self:fixCursor(ew)
end
function SizePosGroup:incLine()
	self.position:incLine()
end

function SizePosGroup:canExpandWidth(inc)
	return not self.maxSize or (self.size.width+(inc or 1) <= self.maxSize.width)
end
function SizePosGroup:expandWidth(inc)
	inc = inc or 1
	if self:canExpandWidth(inc) then
		self.size.width = self.size.width + inc
		return true
	end
end

function SizePosGroup:fixSize()
	self.size.width = (self.size.width<=self.position.x and self.position.x) or self.size.width
	self.size.height = (self.size.height<=self.position.y and self.position.y+1) or self.size.height
	--if self.maxSize then self.size:set(self.size:min(self.maxSize)) end
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
	return class.new(SizePosGroup, self.size:clone(), self.position:clone(), (self.maxSize and self.maxSize:clone()) or nil)
end