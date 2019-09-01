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
	if parent then
		class.checkType(parent, Component, 3, "Component")
		self:setParent(parent)
	end
	
	self.children = {}
	self.attributes = {}
	self.handlers = {}
	self.eventSystem = process.createEventSystem()
	
	self.attributes["enabled"] = true
	
	local function regH(t, enableRequired)
        self.handlers["on"..t] = function(d, e)
    		self.eventSystem.fireEvent(t, d)
    		if self.attributes["on"..t] and (not enableRequired or self.attributes.enabled) then self.attributes["on"..t](d, self) end
    		if self.parent and self.parent.handlers["on"..t] then
    			self.parent.handlers["on"..t](d, self)
    		end
    		for k, v in util.ripairs(self.children) do
    			if not rawequal(v, e) and v.handlers["onexternal"..t] then
    				v.handlers["onexternal"..t](d)
    			end
    		end
    	end
    	self.handlers["onexternal"..t] = function(d)
    		--TODO: Handle arg "d" better
    		self.eventSystem.fireEvent("external_"..t, d)
    		if self.attributes["onexternal"..t] then self.attributes["onexternal"..t](d, self) end
    		for k, v in util.ripairs(self.children) do
    			if v.handlers["onexternal"..t] then
    				v.handlers["onexternal"..t](d)
    			end
    		end
    	end
	end
	regH("click", true)
	regH("drag", true)
	regH("release", true)
	self.handlers.onupdate = function()
		self.eventSystem.fireEvent("component_update", nil)
		if self.attributes.onupdate then self.attributes.onupdate(nil) end
		if self.parent and self.parent.handlers.onupdate then
			self.parent.handlers.onupdate(nil, self)
		end
	end
	
	local function setActiveEvent(n, e)
		if e.button == 1 and self.attributes["enabled"] then
            self:attribute("hover", true)
            self:fireUpdateEvent()
        end
	end
	local function setUnhoverEvent(n, e)
		if e.button == 1 and self.attributes["enabled"] then
            self:attribute("hover", false)
            self:fireUpdateEvent()
        end
	end
	
	self:addEventListener("click", setActiveEvent)
	self:addEventListener("external_click", setUnhoverEvent)
	self:addEventListener("drag", setActiveEvent)
	self:addEventListener("release", setUnhoverEvent)
	self:addEventListener("external_drag", setUnhoverEvent)
end

function Component:delete()
	if self.parent then
		self.parent:removeChild(self)
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
	self:fireUpdateEvent()
end
function Component:removeChildren()
	for i=1, #self.children do
		self.children[i].parent = nil
		self.children[i].context = nil
	end
	self.children = {}
	self:fireUpdateEvent()
end
function Component:addChild(child)
    class.checkType(child, Component, 2, "Component")
    child:delete()
    child.parent = self
	table.insert(self.children, child)
	self:fireUpdateEvent()
end
function Component:setParent(parent)
	class.checkType(parent, Component, 2, "Component")
	if parent then parent:addChild(self) end
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
	self.location = self.attributes["location"]
	if updated["parent"] then
	   self:setParent(self.attributes["parent"])
	end
	if updated["children"] then
		self:removeChildren()
		for k, v in ipairs(self.attributes["children"] or {}) do
			v:setParent(self)
		end
	end
	if updated["background-color"] or updated["text-color"] 
        or updated["hover-background-color"] or updated["hover-text-color"]
		or updated["hover"] then
        
        self.color = (self.attributes.hover and self.attributes["hover-background-color"]) or 
            self.attributes["background-color"]
        self.textColor = (self.attributes.hover and self.attributes["hover-text-color"]) or 
            self.attributes["text-color"]
    end
	self:fireUpdateEvent()
end
function Component:getAttribute(n)
	self:processAttributesReverse(n)
	return self.attributes[n]
end
function Component:processAttributesReverse(n)
	self.attributes["parent"] = self.parent
end

function Component:addEventListener(e, f)
	self.eventSystem.addEventListener(e, f)
end

function Component:debug(...)
	local str = (self.attributes["debugID"] or ("Component "..tostring(self):gsub(".+: ", "")))..":"
	for k, v in pairs({...}) do str=str..tostring(v) end
	debugger.log(str)
end
function Component:customDebug(logfunc, ...)
	local str = (self.attributes["debugID"] or ("Component "..tostring(self):gsub(".+: ", "")))..":"
	for k, v in pairs({...}) do str=str..tostring(v) end
	logfunc(str)
end

function Component:getBaseComponent()
	return (not self.parent and self) or self.parent:getBaseComponent()
end
function Component:getComponentByID(id)
	local rtn
	util.runIFN(self.getComponentByID_IFN, self, id, function(v)
		rtn = v
	end)
	return rtn
end
function Component.getComponentByID_IFN(q, self, id, s)
    if self.attributes["id"] == id then
        s(self)
    end
	for k, v in util.ripairs(self.children) do
        q(v.getComponentByID_IFN, v, id, s)	
	end
end

function Component:fireUpdateEvent()
    self.handlers.onupdate()
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
	
	if self.attributes["dock"] then
		size = self.attributes["dock"].spg
	end
	self.spg = size
	
	self.context = self.parent.childcontext
	self.dockcontext = (self.attributes["dock"] and self.attributes["dock"].context) or self.context
	self.childcontext = self.dockcontext
	
	if self.location then
		local l, oldPos = self.location, size.position
		size.position = class.new(Position, 
			ctxu.calcPos(self.dockcontext, l[2], l[1], l[4], l[3], 0, l[5], 0, l[6])
		)
		q(function() size.position = oldPos end)
	end
	q(function() size:fixCursor(self.enableWrap) end)
	
	for k, v in util.ripairs(self.children) do
		if v.location then q(v.calcSizeIFN, v, size) end
	end
	for k, v in util.ripairs(self.children) do
		if not v.location then q(v.calcSizeIFN, v, size) end
	end
end

function Component:draw(hbr)
	runIFN(self.drawIFN, self, hbr)
end
function Component.drawIFN(q, self)
	if not self.parent then return end
	
	if not self.dockcontext then return end

	local of = self.dockcontext.getFunctions()
	self.dockcontext.setFunction("onclick", self.handlers.onclick)
	self.dockcontext.setFunction("ondrag", self.handlers.ondrag)
	self.dockcontext.setFunction("onrelease", self.handlers.onrelease)
	
	local dbg, dfg = self.context.getColors()
	local obg, ofg = self.dockcontext.getColors()
	self.dockcontext.setColorsRaw(self.color or obg, self.textColor or ofg)
	q(function()
		self.dockcontext.setColorsRaw(obg, ofg)
		self.dockcontext.setFunctions(of)
	end)
	for k, v in util.ripairs(self.children) do
		if not v.sizePosGroup then q(v.drawIFN, v) end
	end
end