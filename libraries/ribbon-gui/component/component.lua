--TODO: Bounding boxes for graphic updates
--TODO: Internal and external component stylesheets (important)
--TODO: Internal children slots (children invisible to applications)
--TODO: Keyboard selection (Tab-Focus)
--TODO: Disable stuff when dragging items
--TODO: Copy/Paste?
--TODO: Optimize size calculation (Don't calculate preceding siblings upon tree modification)
--TODO: Store whether or not the component's parents were all enabled (for drawing purposes)

local ribbon = require()

local class = ribbon.require "class"
local ctx = ribbon.require "context"
local ctxu = ribbon.require "contextutils"
local debugger = ribbon.require "debugger"
local process = ribbon.require "process"
local ribbonos = ribbon.require "ribbonos"
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

	local function regH(t, enableRequired, qualifier)
		self.triggers["on"..t] = function(e, d)
			local d = util.copy(d)
			d.element = self

			local clicked = {}
			local pel = self
			repeat
				clicked[pel] = true
				pel = pel.parent
			until not pel.parent

			local q = pel:queryAbrupt(function(el)
				if not el.attributes["enabled"] then return false end
				return true --TODO: Check dragging element
			end)
			
			for i=1, #q do
				local v = q[i]
				if clicked[v] then
					v.handlers["on"..t](e, d)
				else
					v.handlers["onexternal"..t](e, d)
				end
			end
		end
        self.handlers["on"..t] = function(e, d)
			if (not enableRequired or self.attributes.enabled) and (not qualifier or qualifier(e, d)) then
				self.eventSystem.fireEvent(t, d)
				if self.attributes["on"..t] then
					self.attributes["on"..t](d, self)
				end
			end
    	end
    	self.handlers["onexternal"..t] = function(e, d)
    		self.eventSystem.fireEvent("external_"..t, d)
    		if self.attributes["onexternal"..t] then self.attributes["onexternal"..t](d, self) end
    	end
	end
	local function cursorDataQualifier(e, d)
		local cursordata = ribbonos.receive("CURSORDATA")
		if not cursordata.clipboardtype then return true end
		if self.attributes["cursor-qualifier"] then
			return self.attributes["cursor-qualifier"](cursordata)
		end
		return false
	end
	regH("click", true, cursorDataQualifier)
	regH("drag", true, cursorDataQualifier)
	regH("release", true, cursorDataQualifier)
	
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
	
	self:addEventListener("component_delete", function(e, d)
		if self.attributes["ondelete"] then self.attributes["ondelete"](d, self) end
	end)

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
			self.children[k].eventSystem.fireEvent("component_delete")
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
		self.children[i].eventSystem.fireEvent("component_delete")
	end
	self.children = {}
	self:fireUpdateEvent()
end
function Component:addChild(child, i)
    class.checkType(child, Component, 2, "Component")
    child:delete()
    child.parent = self
	if i and i~=#self.children+1 then
		table.insert(self.children, i, child)
	else
		self.children[#self.children+1] = child
	end
	self:fireUpdateEvent()
end
function Component:insertBefore(sibling)
	class.checkType(sibling, Component, 2, "Component")
	if not sibling.parent then error("Attempt to insert where there is no tree", 2) end
	local children = sibling.parent.children
	for i=1, #children do
		if rawequal(children[i], sibling) then
			sibling.parent:addChild(self, i)
			break
		end
	end
end
function Component:insertAfter(sibling)
	class.checkType(sibling, Component, 2, "Component")
	if not sibling.parent then error("Attempt to insert where there is no tree", 2) end
	local children = sibling.parent.children
	for i=1, #children do
		if rawequal(children[i], sibling) then
			sibling.parent:addChild(self, i+1)
			break
		end
	end
end
function Component:insertAfter()

end
function Component:setParent(parent)
	class.checkType(parent, Component, 2, "Component")
	if parent then parent:addChild(self) end
end

function Component:attribute(...)
	local args, updated = {...}, {}
	if type(args[1])=="table" then args=args[1] end
	for k, v in pairs(args) do
		if k%2==1 then
			for opt in v:gmatch("[^&]+") do
				self.attributes[opt] = args[k+1]
				updated[opt] = true
			end
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
		if not qf or qf(curi) then final[#final+1] = curi end
		for i=1, #curi.children do
			q[#q+1]=curi.children[i]
		end
	end
	return final
end
function Component:queryAbrupt(qf)
	local q, final = {self}, {}
	while #q>0 do
		local curi = q[#q]; q[#q] = nil
		local res = not qf or qf(curi)
		if res then
			if res~=2 then final[#final+1] = curi end
			for i=1, #curi.children do
				q[#q+1]=curi.children[i]
			end
		end
	end
	return final
end
function Component:queryShallow(qf)
	local final = {}
	for i=1, #self.children do
		if not qf or qf(self.children[i]) then final[#final+1] = self.children[i] end
	end
	return final
end
function Component:childOf(p, inclusive)
	local parent = (inclusive and self) or self.parent
	while parent do
		if rawequal(parent, p) then return true end
		parent = parent.parent
	end
	return false
end
function Component:getComponentByID(id)
	return self:query(function(comp) return comp.attributes["id"] == id end)[1]
end
function Component:getComponentsByClass(class)
	return self:query(function(comp) return comp.attributes["class"] == class end)
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
function Component:queueChildrenCalcSize(q, size, values)
	for k, v in util.ripairs(self.children) do
		if not v.location then
			q(v.calcSizeIFN, v, size, values)
		else
			values.processingQueue[#values.processingQueue+1] = {v, size}
		end
	end
end
function Component:mCalcSize(q, size, values)
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

	self:queueChildrenCalcSize(q, size, values)
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

	local values = {processingQueue = {{self, size}}}

	local i = 0
	while #values.processingQueue>i do
		i=i+1
		local cv = values.processingQueue[i]
		runIFN(cv[1].calcSizeIFN, cv[1], cv[2], values)
	end
end
function Component.calcSizeIFN(q, self, size, values)
	if not self.parent then return end

	if self.attributes["dock"] then
		size = self.attributes["dock"].spg
	end
	self.spg = size

	self:setContextInternal()
	self:mCalcSize(q, size, values)
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