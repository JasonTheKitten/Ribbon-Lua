local cplat = require()
local environment = cplat.require "environment"

local natives = environment.getNatives()

local isCC = environment.is("CC")
local isOC = environment.is("OC")

local http = {}
http.available = function()
    return not not ((isCC and natives.http) or (isOC and pcall(natives.request, "internet")))
end

http.request = function()
    
end

return http