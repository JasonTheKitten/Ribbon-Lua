local cplat = require()

local class = cplat.require "class"
local util = cplat.require "util"

local Size = cplat.require("class/size").Size

local Component = cplat.require("component/component").Component

local runIFN = util.runIFN

local label = ...
local Label = {}
label.Label = Label

Label.cparents = {Component}
function Label:__call(parent, text, enableWrap)
	class.checkType(parent, Component, 3, "Component")
	Component.__call(self, parent, text)
	
	self.text = text
	self.enableWrap = true--enableWrap or false
end

--IFN functions
local function internalSizeProc(self, size, f)
	local text, lastSpaceBroke = self.text, false
	for i=1, #text do
		local char = text:sub(i, i)
		if char == "\n" then
			lastSpaceBroke = false
			size:incLine(self.enableWrap)
		elseif char == " " then
			if not lastSpaceBroke then
				local done = (text:sub(2, #text).." "):find(" ")
				local needed = done+size.position.x-size.size.width
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
	self.size = size:cloneAll()
	
	internalSizeProc(self, size)
	
	for k, v in pairs(self.children) do
		q(v.calcSizeIFN, v, size)
	end
end
function Label.drawIFN(q, self, hbr)
	Component.drawIFN(q, self, hbr)
	
	local size = self.size:cloneAll()
	internalSizeProc(self, size, function(char)
		self.context.drawPixel(size.position.x, size.position.y, nil, (char~="\t" and char) or " ")
	end)
end