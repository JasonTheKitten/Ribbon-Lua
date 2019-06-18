local cplat = require()
local environment = cplat.require "environment"

local natives = environment.getNatives()

local isCC = environment.is("CC")
local isOC = environment.is("OC")

local websocket = {}