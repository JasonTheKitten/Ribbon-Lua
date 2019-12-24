local ribbon = require()

local process = ribbon.require "process"
local debugger = ribbon.require "debugger"

local eventtracker = ...

local keyboard = {}
eventtracker.keyboard = keyboard

process.addEventListener("key_down", function(e, d)
    keyboard[d.code] = true
end)
process.addEventListener("key_up", function(e, d)
    keyboard[d.code] = false
end)