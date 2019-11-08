local ribbon = require()

local environment = ribbon.require "environment"

local isCC = environment.is("CC")

local natives = environment.getNatives()

local bannedNamesCCR = {"left", "right", "top", "bottom", "back", "front"}
local bannedNamesCC = {}
for k, v in pairs(bannedNamesCCR) do
    bannedNamesCC[v] = true
end

device.getDevice = function(name)
    if isCC and bannedNamesCC[name] then
        error(
            "Indexing devices by the side name has been disabled.\n"+
            "Please use `require().require(\"environment\").getNatives().peripheral` if you need this functionality.", 2)
    end
end