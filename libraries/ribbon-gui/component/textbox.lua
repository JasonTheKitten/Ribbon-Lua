local ribbon = require()

local class = ribbon.require "class"
local macro = ribbon.require "macro"
local statics = ribbon.require "statics"

local Size = ribbon.require("class/size").Size

local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent
local Component = ribbon.require("component/component").Component

local KEYS = statics.get("keys")

local process = ribbon.require "process" --TODO: Testing only, move to component event listener

local textbox = ...
local TextBox = {}
textbox.TextBox = TextBox

TextBox.cparents = {BlockComponent}
function TextBox:__call(parent)
    if parent then class.checkType(parent, Component, 3, "Component") end
    BlockComponent.__call(self, parent)

    self.lines={}
    self.cursors={{x=1,y=1}}
    self.insert = true

    self.preferredSize = class.new(Size, 20, 5)

    self.macroSystem = macro.createMacroSystem()

    process.addEventListener("char", function(e, d)
        for i=1, #self.cursors do
            local mcursor = self.cursors[i]
            for i2=1, #self.cursors do
                if self.cursors[i2].y == mcursor.y and self.cursors[i2].x > mcursor.x then
                    self.cursors[i2].x = self.cursors[i2].x + 1
                end
            end
			local line = self.lines[mcursor.y] or ""
            self.lines[mcursor.y] =
                line:sub(1, mcursor.x-1)..d.char..
                line:sub(mcursor.x+((not self.insert and 1) or 0), #line)
				
			mcursor.x = mcursor.x+1
        end
        self:fireGraphicsUpdateEvent()
    end)
    self.macroSystem.register({KEYS.ENTER}, function()
        for i=1, #self.cursors do
            local mcursor = self.cursors[i]
            for i2=1, #self.cursors do
                if self.cursors[i2].y > mcursor.y or
                    (self.cursors[i2].y == mcursor.y and self.cursors[i2].x > mcursor.x) then

                    self.cursors[i2].y = self.cursors[i2].y + 1
                end
            end
			local line = self.lines[mcursor.y] or ""
			for my = #self.lines, mcursor.y+1, -1 do
				self.lines[my+1] = self.lines[my]
			end
			local nl = line:sub(mcursor.x, #line)
            self.lines[mcursor.y] = line:sub(1, mcursor.x-1)
			self.lines[mcursor.y+1] = nl
			mcursor.x, mcursor.y = 1, mcursor.y+1
        end
        self:fireGraphicsUpdateEvent()
    end, "enter")
	self.macroSystem.register({KEYS.BACKSPACE}, function()
        for i=1, #self.cursors do
            local mcursor = self.cursors[i]
            for i2=1, #self.cursors do
                if self.cursors[i2].y > mcursor.y or
                    (self.cursors[i2].y == mcursor.y and self.cursors[i2].x > mcursor.x) then

                    self.cursors[i2].y = self.cursors[i2].y - 1
                end
            end
			local line = self.lines[mcursor.y] or ""
            self.lines[mcursor.y] = line:sub(1, mcursor.x-2)..line:sub(mcursor.x, #line)
			
			mcursor.x=mcursor.x-1
        end
        self:fireGraphicsUpdateEvent()
    end, "backspace")
    self.macroSystem.register({KEYS.ESCAPE}, function()
        self.cursors = {self.cursors[1]}
        self:fireGraphicsUpdateEvent()
    end, "escape")
    self.macroSystem.register({KEYS.LEFT}, function()
        for i=1, #self.cursors do
			local mcursor = self.cursors[i]
			mcursor.x = mcursor.x-1
			if mcursor.x<1 then
				mcursor.y = mcursor.y-1
				if mcursor.y<1 then mcursor.y = 1 end
				mcursor.x = (#self.lines[mcursor.y] or 0)+1
			end
        end
        self:fireGraphicsUpdateEvent()
    end, "left")
end

function TextBox.calcSizeIFN(q, self, size)
	if not self.parent then return end

	Component.calcSizeIFN(q, self, size)

    self.lastsize = self.spg:cloneAll()
end
function TextBox.drawIFN(q, self)
	if not self.parent then return end

	BlockComponent.drawIFN(q, self)

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