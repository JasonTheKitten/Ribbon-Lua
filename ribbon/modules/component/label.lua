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
function Label:__call(parent, text, enableWrap)
	if parent then class.checkType(parent, Component, 3, "Component") end
	Component.__call(self, parent, text)
	
	self.text = text
	self.enableWrap = true--enableWrap or false
end

--IFN functions
local function internalSizeProc(self, size, f)
	local text, lastSpaceBroke = self.text, false
	size:fixCursor(self.enableWrap)
	for i=1, #text do
		local char = text:sub(i, i)
		if char == "\n" then
			lastSpaceBroke = false
			size:incLine(self.enableWrap)
		elseif char == " " then
			if not lastSpaceBroke then
				local done = (text:sub(2, #text).." "):find(" ")
				local needed = done-size.size.width
				if needed >= 0 and not size:expandWidth(needed) then
					lastSpaceBroke = true
					size:incLine(self.enableWrap)
				else
					if f then f(" ") end
					size:incCursor(self.enableWrap)
				end
			end
		else
			if f then f(char) end
			lastSpaceBroke = size:incCursor(self.enableWrap)
		end
	end
end

function Label.calcSizeIFN(q, self, size)
	size:fixCursor()
	
	self.context = self.parent.context
	self.size = size:cloneAll()
	
	internalSizeProc(self, size)
	
	for k, v in pairs(self.children) do
		q(v.calcSizeIFN, v, size)
	end
end
function Label.drawIFN(q, self)
	Component.drawIFN(q, self)
	
	local size = self.size:cloneAll()
	internalSizeProc(self, size, function(char)
		self.context.drawPixel(size.position.x, size.position.y, nil, (char~="\t" and char) or " ")
	end)
end