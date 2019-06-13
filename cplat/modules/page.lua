--[[
local cplat = require()
local environment = cplat.require "environment"

local natives = environment.getNatives()

local isCP = environment.is("CP")
local isCC = environment.is("CC")
local isOC = environment.is("OC")

local page = {}
page.create = function(parent, x, y, l, h)
    local pg = {
        parent = parent,
        x = x,
        y = y,
        length = l,
        height = h
    }
    setmetatable(pg, {__index = function(t, k)
        if (k=="width") then k = "length" end
        return rawget(pg, k)
    end})
    
    page.setHook = function(m, h)
        if m=="open" then
        
        elseif m=="close" then
        
        elseif m=="active" then
        
        elseif m=="background" then
        
        end
    end
    
    return pg
end
]]