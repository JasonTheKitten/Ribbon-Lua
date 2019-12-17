local ribbon = require()

local environment = ribbon.require "environment"

local isCC = environment.is("CC")

local natives = environment.getNatives()

local device = ...

local bannedNamesCCR = {"left", "right", "top", "bottom", "back", "front"}
local bannedNamesCC = {}
for k, v in pairs(bannedNamesCCR) do
    bannedNamesCC[v] = true
end

device.enableSideNames = false

local genericDevices = {

}

device.getDevice = function(name)
    if bannedNamesCC[name] and not device.enableSideNames then
        error(
            "Indexing devices by side names has been disabled, as it may not be compatible with both OC and CC.\n"+
            "Please set `device.enableSideNames` to `true` if you need this functionality.", 2)
    end
    if isCC then
        return peripheral.wrap(name), "ComputerCraft"
    elseif isOC then

    end
end

device.getGenericDevice = function()
    if bannedNamesCC[name] and not device.enableSideNames then
        error(
            "Indexing devices by side names has been disabled, as it may not be compatible with both OC and CC.\n"+
            "Please set `device.enableSideNames` to `true` if you need this functionality.", 2)
    end
    if isCC then
        return genericDevices[name](peripheral.wrap(name), "ComputerCraft")
    elseif isOC then

    end
end