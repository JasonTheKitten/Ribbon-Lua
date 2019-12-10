--TODO: Support shared styles
--TODO: Keyboard selection
--TODO: Copy/Paste?

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
	end
	
	self.children = {}
	self.handlers = {}
	self.triggers = {}
	self.eventSystem = process.createEventSystem()
	
	self.attributes = {
	    ["enabled"] = true,
	    ["enable-wrap"] = true,
	    ["enable-child-wrap"] = true
	}
	self.enableChildWrap = true
	
	local function regH(t, enableRequired)
		self.triggers["on"..t] = function(e, d)
			local d = util.copy(d)
			d.element = self
			
			local clicked = {}
			local pel = self
			repeat
				clicked[pel] = true
				pel = pel.parent
			until not pel.parent
			
			for k, v in pairs(pel:query()) do
				if clicked[v] then
					v.handlers["on"..t](e, d)
				else
					v.handlers["onexternal"..t](e, d)
				end
			end
		end
        self.handlers["on"..t] = function(e, d)
			self.eventSystem.fireEvent(t, d)
    		if self.attributes["on"..t] and (not enableRequired or self.attributes.enabled) then self.attributes["on"..t](d, self) end
    	end
    	self.handlers["onexternal"..t] = function(e, d)
    		self.eventSystem.fireEvent("external_"..t, d)
    		if self.attributes["onexternal"..t] then self.attributes["onexternal"..t](d, self) end
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
	self.handlers.ongraphicsupdate = function()
		self.eventSystem.fireEvent("component_graphics_update", nil)
		if self.attributes.ongraphicsupdate then self.attributes.ongraphicsupdate(nil) end
		if self.parent and self.parent.handlers.ongraphicsupdate then
			self.parent.handlers.ongraphicsupdate(nil, self)
		end
	end
	
	local function setSelectedEvent(n, e)
		if e.button == 1 and self.attributes["enabled"] then
            self:attribute("selected", true)
            self:fireUpdateEvent()
        end
	end
	local function setUnselectedEvent(n, e)
		if e.button == 1 and self.attributes["enabled"] then
            self:attribute("selected", false)
            self:fireUpdateEvent()
        end
	end
	
	self:addEventListener("click", setSelectedEvent)
	self:addEventListener("external_click", setUnselectedEvent)
	self:addEventListener("drag", setSelectedEvent)
	self:addEventListener("external_drag", setUnselectedEvent)
	self:addEventListener("release", setUnselectedEvent)
	self:addEventListener("external_release", setUnselectedEvent)
	
	if parent then self:setParent(parent) end
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
	self.depth = self.attributes["depth"]
	if updated["parent"] then
	   self:setParent(self.attributes["parent"])
	end
	if updated["children"] then
		self:removeChildren()
		for k, v in ipairs(self.attributes["children"] or {}) do
			v:setParent(self)
		end
	end
	self.color = (self.attributes.selected and self.attributes["selected-background-color"]) or 
		self.attributes["background-color"]
	self.textColor = (self.attributes.selected and self.attributes["selected-text-color"]) or 
		self.attributes["text-color"]

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
function Component:query(qf)
	local q, final = {self}, {}
	while #q>0 do
		local curi = q[#q]; q[#q] = nil
		if not qf or qf(curi) then table.insert(final, curi) end
		for k, v in pairs(curi.children) do
			table.insert(q, v)
		end
	end
	return final
end
function Component:getComponentByID(id)
	return self:query(function(comp) return comp.attributes["id"] == id end)[1]
end
function Component:getComponentsByType(ctype)
	return self:query(function(comp) return comp:isA(ctype) end)
end
function Component:getComponentsByName(name)
	return self:query(function(comp) return comp.attributes["name"] == name end)
end

function Component:fireUpdateEvent()
    self.handlers.onupdate()
end
function Component:fireGraphicsUpdateEvent()
    self.handlers.ongraphicsupdate()
end

function Component:setContextInternal()
    self.context = self.parent.childcontext
	self.dockcontext = (self.attributes["dock"] and self.attributes["dock"].context) or self.context
	self.childcontext = self.dockcontext
end
function Component:queueChildrenCalcSize(q, size)
    for k, v in util.ripairs(self.children) do
		if v.location then q(v.calcSizeIFN, v, size) end
	end
	for k, v in util.ripairs(self.children) do
		if not v.location then q(v.calcSizeIFN, v, size) end
	end
end
function Component:mCalcSize(q, size)
    self.enableWrap = self.parent.enableChildWrap and self.attributes["enable-wrap"]
    self.enableChildWrap = self.parent.enableChildWrap and self.attributes["enable-child-wrap"]
    
    if self.location then
		local l, oldPos = self.location, size.position
		size.position = class.new(Position, 
			ctxu.calcPos(self.dockcontext, l[2], l[1], l[4], l[3], 0, l[5], 0, l[6])
		)
		q(function() size.position = oldPos end)
	end
	self.position = size.position:clone()
	
    if not (self.attributes["location"] or self.attributes["dock"]) then
		q(function() size:fixCursor(self.enableWrap) end)
	end
	
	self:queueChildrenCalcSize(q, size)
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
	
	self:setContextInternal()
	self:mCalcSize(q, size)
end

function Component:draw()
	runIFN(self.drawIFN, self)
end
function Component.drawIFN(q, self)
	if not self.parent then return end
	
	if not self.dockcontext then return end

	local of = self.dockcontext.getFunctions()
	self.dockcontext.setFunction("onclick", self.triggers.onclick)
	self.dockcontext.setFunction("ondrag", self.triggers.ondrag)
	self.dockcontext.setFunction("onrelease", self.triggers.onrelease)
	
	local dbg, dfg = self.context.getColors()
	local obg, ofg = self.dockcontext.getColors()
	self.dockcontext.setColorsRaw(self.color or obg, self.textColor or ofg)
	q(function()
		self.dockcontext.setColorsRaw(obg, ofg)
		self.dockcontext.setFunctions(of)
	end)
	for k, v in util.ripairs(self.children) do
		q(v.drawIFN, v)
	end
end