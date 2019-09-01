--TODO: Timed macros
local ribbon = require "ribbon"

local eventtracker = ribbon.require "eventtracker"
local process = ribbon.require "process"

local keyboard = eventtracker.keyboard

local macro = ...

macro.check = function(keys)
    for k, v in pairs(keys) do
        if not keyboard[v] then return false end
    end
    return true
end

local mr, id = {}, -1
macro.register = function(macro, f)
    while mr[id] do id=(id+1)%math.huge end
    mr[id] = {macro, f}
    return id
end
macro.unregister = function(id)
    mr[id] = nil
end

process.addEventListener("key_down", function()
    for k, v in pairs(mr) do
        if macro.check(v[1]) then
            v[2](v[1])
        end
    end
end)