local ribbon = require()

local class = ribbon.require "class"
local debugger = ribbon.require "debugger"
local util = ribbon.require "util"

local Size = ribbon.require("class/size").Size

local Component = ribbon.require("component/component").Component

local runIFN = util.runIFN

local label = ...
local Label = {}
label.Label = Label

Label.cparents = {Component}
function Label:__call(parent, text)
	if parent then class.checkType(parent, Component, 3, "Component") end
	Component.__call(self, parent, text)
	
	self:attribute("text", text, "enable-wrap", true)
end

--IFN functions
local function internalSizeProc(self, size, f)
	local lines = {""}
	
	local incLine = size.incLine
	local incCursor = size.incCursor
	local enableWrap = self.enableWrap
	
	self.text = (self.attributes["text"] or ""):gsub("[\128-\255]", "?") --TODO: Newer CC versions support these characters
	local text, lastSpaceBroke = self.text.." ", false
	size:fixCursor(self.enableWrap)
	for i=1, #text-1 do
		local char = text:sub(i, i)
		if char~="\n" and char~=" " then lines[#lines]=lines[#lines]..char end
		if char == "\n" then
			lastSpaceBroke = false
			incLine(size)
			lines[#lines+1] = ""
		elseif char == " " then
			if not lastSpaceBroke then
				local done = text:find(" ", i+1) - i
				local needed = size.position.x+done-size.size.width
				if needed > 0 and not size:expandWidth(needed) then
					if enableWrap then
						incLine(size)
						lines[#lines+1] = ""
					else
						lines[#lines]=lines[#lines].." "
					end
				elseif incCursor(size, enableWrap) then
					lines[#lines+1] = ""
				else
					lines[#lines]=lines[#lines].." "
				end
			else
				lastSpaceBroke = false
			end
		else
			lastSpaceBroke = false
			if #text>0 then
				if incCursor(size, enableWrap) then
					lastSpaceBroke = true
					lines[#lines+1] = ""
				end
			else
				incCursor(size, false)
			end
		end
	end
	
	return lines
end


function Label.calcSizeIFN(q, self, size, values)
	if not self.parent then return end

	Component.calcSizeIFN(q, self, size, values)
	
	self.lastsize = self.spg:cloneAll()
	self.lines = internalSizeProc(self, size)
end
function Label.drawIFN(q, self)
	if not self.parent then return end
	
	Component.drawIFN(q, self)
	
	local size = self.lastsize:cloneAll()
	for y=1, #self.lines do --TODO: Only draw lines on screen (will be complicated)
		local col = self.lines[y]
		for x=1, #self.lines[y] do --Maybe just drawText?
			local char = col:sub(x, x)
			self.dockcontext.drawPixel(size.position.x, size.position.y, nil, (char~="\t" and char) or " ")
			size.position.x = size.position.x+1
		end
		size:incLine()
	end
end