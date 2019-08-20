local ribbon = require()
local environment = ribbon.require "environment"

local natives = environment.getNatives()

local isCC = environment.is("CC")
local isOC = environment.is("OC")

local websocket = {}