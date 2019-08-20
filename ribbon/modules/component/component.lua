local ribbon = require()

local class = ribbon.require "class"
local ctx = ribbon.require "context"
local ctxu = ribbon.require "contextutils"
local debugger = ribbon.require "debugger"
local process = ribbon.require "process"
local util = ribbon.require "util"

local Size = ribbon.require("class/size").Size
local SizePosGroup = ribbon.require("class/sizeposgroup").SizePosGroup
local Position = ribbon.require("class/position").Position

local runIFN = util.runIFN

local component = ...
local Component = {}
component.Component = Component

Component.cparents = {class.Class}
function Component:__call(parent)
	class.checkType(parent, Component, 3, "Component")
	
	self:setParent(parent)
	
	self.children = {}
	self.attributes = {}
	self.handlers = {}
	self.eventSystem = process.createEventSystem()
	
	self.handlers.onclick = function(d)
		self.eventSystem.fireEvent("click", d)
		if self.attributes.onclick then self.attributes.onclick(d) end
		if self.parent and self.parent.handlers.onclick then
			self.parent.handlers.onclick(d)
		end
	end
end

function Component:removeChild(child)
	for k, v in pairs(self.children) do
		if rawequal(child, v) then
			v.parent = nil
			v.context = nil
			table.remove(self.children, k)
			break
		end
	end
end
function Component:removeChildren()
	for i=1, #self.children do
		self.children[i].parent = nil
		self.children[i].context = nil
	end
	self.children = {}
end
function Component:delete()
	if self.parent then
		self.parent:removeChild(self)
	end
end
function Component:setParent(parent)
	self:delete()
	if parent then
		self.parent = parent
		table.insert(parent.children, self)
	end
end

function Component:attribute(...)
	local args, updated = {...}, {}
	for k, v in pairs(args) do
		if k%2==1 then
			self.attributes[v] = args[k+1]
			updated[v] = true
		end
	end
	self:processAttributes(updated)
	return self
end
function Component:processAttributes(updated)
	self.color = self.attributes["background-color"]
	self.textColor = self.attributes["text-color"]
end
function Component:getAttribute(n)
	self:processAttributesReverse(n)
	return self.attributes[n]
end
function Component:processAttributesReverse(n)
	
end

function Component:addEventListener(e, f)
	self.eventSystem.addEventListener(e, f)
end

function Component:setDebugID(id)
	self.debugID = id or ("Component "..tostring(self):gsub(".+: ", ""))
end
function Component:debug(...)
	local str = self.debugID..": "
	for k, v in pairs({...}) do str=str..tostring(v) end
	debugger.log(str)
end

function Component:setSizePosGroup(spg)
	self.sizePosGroup = spg
end
function Component:setSizeAndLocation(size, ax, px, ay, py, ol, oh)
	self.sizeAndLocation = {size, ax, px, ay, py, size.width, ol, size.height, oh}
end
function Component:clearSizeOverrides()
	self.sizePosGroup = nil
	self.sizeAndLocation = nil
end

function Component:calcSize(size)
	if size then
		class.checkType(size, SizePosGroup, 3, "SizePosGroup", Size)
		if size:isA(Size) then
			size = class.new(SizePosGroup, size)
		end
	else
		size = class.new(SizePosGroup)
	end
	runIFN(self.calcSizeIFN, self, size)
end
function Component.calcSizeIFN(q, self, size)
	if not self.parent then return end

	self.context = self.parent.context
	if self.sizeAndLocation then
		local msize = self.sizeAndLocation[1]
		local x, y = ctxu.calcPos(self.parent.context, table.unpack(self.sizeAndLocation, 2))
		size = class.new(SizePosGroup, msize, class.new(Position, x, y), msize)
	else
		size = self.sizePosGroup or size
	end
	
	for k, v in util.ripairs(self.children) do
		if v.sizeAndLocation then q(v.calcSizeIFN, v, msize) end
	end
	for k, v in util.ripairs(self.children) do
		if not v.sizeAndLocation then q(v.calcSizeIFN, v, size) end
	end
end

function Component:draw(hbr)
	runIFN(self.drawIFN, self, hbr)
end
function Component.drawIFN(q, self)
	if not self.parent then return end

	local obg, ofg = self.context.getColors()
	local ocf = self.context.getClickFunction()
	self.context.setClickFunction(self.handlers.onclick)
	self.context.setColorsRaw(self.color or obg, self.textColor or ofg)
	q(function()
		self.context.setColorsRaw(obg, ofg)
		self.context.setClickFunction(ocf)
	end)
	for k, v in util.ripairs(self.children) do
		if not v.sizePosGroup then q(v.drawIFN, v) end
	end
end