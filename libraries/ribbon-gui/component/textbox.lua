local ribbon = require()

local class = ribbon.require "class"
local eventtracker = ribbon.require "eventtracker"
local macro = ribbon.require "macro" --TODO: Move to basecomponent
local process = ribbon.require "process" --TODO: Testing only, move to component event listener
local statics = ribbon.require "statics"

local debugger = ribbon.require "debugger"

local Size = ribbon.require("class/size").Size

local BlockComponent = ribbon.require("component/blockcomponent").BlockComponent
local Component = ribbon.require("component/component").Component

local KEYS = statics.get("keys")

local textbox = ...
local TextBox = {}
textbox.TextBox = TextBox

TextBox.cparents = {BlockComponent}
function TextBox:__call(parent)
    if parent then class.checkType(parent, Component, 3, "Component") end
    BlockComponent.__call(self, parent)

    self.data = {
        lines={},
        cursors={{x=1,y=1}},
        insert = true
    }

    self.preferredSize = class.new(Size, 20, 5)

    self.macroSystem = macro.createMacroSystem()

    --TODO: Move most of these event handlers into callable functions
    --TODO: click, click+shift, click+alt
    process.addEventListener("char", function(e, d)
        for i=1, #self.data.cursors do
            local mcursor = self.data.cursors[i]
            for i2=1, #self.data.cursors do
                if self.data.cursors[i2].y == mcursor.y and self.data.cursors[i2].x > mcursor.x then
                    self.data.cursors[i2].x = self.data.cursors[i2].x + 1
                end
            end
			local line = self.data.lines[mcursor.y] or ""
            self.data.lines[mcursor.y] =
                line:sub(1, mcursor.x-1)..d.char..
                line:sub(mcursor.x+((self.data.insert and 0) or 1), #line)
			
			mcursor.x=mcursor.x+1
        end
        self:fireGraphicsUpdateEvent()
    end)

    self.macroSystem.register(KEYS.INSERT, function()
        self.data.insert = not self.data.insert
		self:fireGraphicsUpdateEvent()
    end, "insert")
    self.macroSystem.register(KEYS.ENTER, function()
        for i=1, #self.data.cursors do
            local mcursor = self.data.cursors[i]
            for i2=1, #self.data.cursors do
                if self.data.cursors[i2].y > mcursor.y or
                    (self.data.cursors[i2].y == mcursor.y and self.data.cursors[i2].x > mcursor.x) then

                    self.data.cursors[i2].y = self.data.cursors[i2].y + 1
                end
            end
			local line = self.data.lines[mcursor.y] or ""
			for my = #self.data.lines, mcursor.y+1, -1 do
				self.data.lines[my+1] = self.data.lines[my]
			end
			local nl = line:sub(mcursor.x, #line)
            self.data.lines[mcursor.y] = line:sub(1, mcursor.x-1)
			self.data.lines[mcursor.y+1] = nl
			mcursor.x, mcursor.y = 1, mcursor.y+1
        end
        self:fireGraphicsUpdateEvent()
    end, "enter")
	self.macroSystem.register(KEYS.BACKSPACE, function()
        for i=1, #self.data.cursors do
            local mcursor = self.data.cursors[i]
			if mcursor.x == 1 then
				if mcursor.y>1 then
					mcursor.y = mcursor.y-1
					mcursor.x = #self.data.lines[mcursor.y]+1
					self.data.lines[mcursor.y] = self.data.lines[mcursor.y]..self.data.lines[mcursor.y+1]
					table.remove(self.data.lines, mcursor.y+1)
				end
			else
				for i2=1, #self.data.cursors do
					if self.data.cursors[i2].y > mcursor.y or
						(self.data.cursors[i2].y == mcursor.y and self.data.cursors[i2].x > mcursor.x) then

						self.data.cursors[i2].y = self.data.cursors[i2].y - 1
					end
				end
				local line = self.data.lines[mcursor.y] or ""
				self.data.lines[mcursor.y] = line:sub(1, mcursor.x-2)..line:sub(mcursor.x, #line)

				mcursor.x=mcursor.x-1
			end
			self:fixCursor(mcursor)
        end
        self:fireGraphicsUpdateEvent()
    end, "backspace")
    self.macroSystem.register(KEYS.PAUSE, function()
        self.data.cursors = {self.data.cursors[1]}
        self:fireGraphicsUpdateEvent()
    end, "pause")

    self.macroSystem.register(KEYS.LEFT, function() --TODO: CTRL should jump a word
        for i=1, #self.data.cursors do
			local mcursor = self.data.cursors[i]
			mcursor.x = mcursor.x-1
			if mcursor.x<1 then
				mcursor.y = mcursor.y-1
				if mcursor.y<1 then
					mcursor.x, mcursor.y = 1, 1
				else
					mcursor.x = (#self.data.lines[mcursor.y] or 0)+1
				end
			end
        end
        self:mergeEquivalentCursors()

        self:fireGraphicsUpdateEvent()
    end, "left")
    self.macroSystem.register(KEYS.RIGHT, function()
        for i=1, #self.data.cursors do
			local mcursor = self.data.cursors[i]
			mcursor.x = mcursor.x+1
			if mcursor.x>#(self.data.lines[mcursor.y] or "")+1 then
				if mcursor.y<#self.data.lines then
					mcursor.x, mcursor.y = 1, mcursor.y+1
				else
					mcursor.x = mcursor.x-1
				end
			end
        end
        self:mergeEquivalentCursors()

        self:fireGraphicsUpdateEvent()
    end, "right")

    self.macroSystem.register(KEYS.UP, function()
        for i=1, #self.data.cursors do
            local mcursor = self.data.cursors[i]
            if mcursor.y>1 then
				mcursor.preferredX = mcursor.x --TODO: Remember X value
                mcursor.x, mcursor.y = mcursor.preferredX, mcursor.y-1
                self:fixCursor(mcursor)
            end
        end
        self:mergeEquivalentCursors()

        self:fireGraphicsUpdateEvent()
    end, "up")
    self.macroSystem.register(KEYS.DOWN, function()
        for i=1, #self.data.cursors do
			local mcursor = self.data.cursors[i]
            mcursor.preferredX = mcursor.x --TODO: Remember X value
            if mcursor.y<#self.data.lines then
                mcursor.x, mcursor.y = mcursor.preferredX, mcursor.y+1
                self:fixCursor(mcursor)
            end
        end
        self:mergeEquivalentCursors()

        self:fireGraphicsUpdateEvent()
    end, "down")
    self.macroSystem.register(KEYS.PAGE_UP, function() end, "page_up")
    self.macroSystem.register(KEYS.PAGE_DOWN, function() end, "page_down")

    self.macroSystem.register(KEYS.HOME, function()
        if eventtracker.keyboard[KEYS.LSHIFT] or eventtracker.keyboard[KEYS.RSHIFT] then
            self.data.cursors = {{x=1, y=1}}
        else
            for i=1, #self.data.cursors do
                self.data.cursors[i].x = 1
            end
            self:mergeEquivalentCursors()
        end

        self:fireGraphicsUpdateEvent()
    end, "home")
    self.macroSystem.register(KEYS.END, function()
        if eventtracker.keyboard[KEYS.LSHIFT] or eventtracker.keyboard[KEYS.RSHIFT] then
            self.data.cursors = {{x=#self.data.lines[#self.data.lines], y=#self.data.lines+1}}
        else
            for i=1, #self.data.cursors do
                self.data.cursors[i].x = #(self.data.lines[self.data.cursors[i].y] or "")+1
            end
            self:mergeEquivalentCursors()
        end

        self:fireGraphicsUpdateEvent()
    end, "end")
end

function TextBox:mergeEquivalentCursors()
    local c = {}
    for i=#self.data.cursors, 1, -1 do
        local mcursor = self.data.cursors[i]
        c[mcursor.y] = c[mcursor.y] or {}
        if c[mcursor.y][mcursor.x] then
            table.remove(self.data.cursors, i)
        else
            c[mcursor.y][mcursor.x] = true
        end
    end
end
function TextBox:fixCursor(mcursor)
    if mcursor.y<1 then
        mcursor.x, mcursor.y = 1, 1
    end
	if mcursor.x<1 then
        mcursor.x = 1
    end
    if mcursor.x>#(self.data.lines[mcursor.y] or "")+1 then
        mcursor.x = #(self.data.lines[mcursor.y] or "")+1
    end
end
function TextBox:focusCursor(id)
    local mcursor = {}
    if id then
        mcursor = self.data.cursors[id]
    else

    end
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
	for y=1, #self.data.lines do --TODO: Only draw lines on screen (will be complicated)
		local col = self.data.lines[y]
		for x=1, #self.data.lines[y] do --Maybe just drawText?
			local char = col:sub(x, x)
			self.dockcontext.drawPixel(size.position.x, size.position.y, nil, (char~="\t" and char) or " ")
			size.position.x = size.position.x+1
		end
		size:incLine()
	end
	for i=1, #self.data.cursors do
		local mcursor = self.data.cursors[i]
		self.dockcontext.drawPixel(mcursor.x-1, mcursor.y-1, nil, (self.data.insert and "|") or "_")
	end
end