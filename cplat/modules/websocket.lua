local cplat = require()
local environment = cplat.require "environment"

local natives = environment.getNatives()

local isCP = environment.is("CP")
local isCC = environment.is("CC")
local isOC = environment.is("OC")

if isCP then
    return natives.require().require "websocket"
end

local websocket = {}