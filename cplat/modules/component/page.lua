local cplat = require()

local process = require "process"
local gui = require "gui"
local bufferedContext = require "bufferedcontext"
local advancedDrawing = require "advanceddrawing"

local component = require "component/component"

local page = {}
page.create = function(parentContext, parentProcess, x, y, l, h)
    local pg = {
        INTERNALS = {
            parentContext = parentContext,
    		parentProcess = parentProcess
        },
        x = x,
        y = y,
        width = l,
        height = h
    }
    
    pg.context = gui.createContext(parentContext, x, y, l, h)
    
    return pg
end