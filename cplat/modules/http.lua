local cplat = require()
local environment = cplat.require "environment"

local natives = environment.getNatives()

local isCP = environment.is("CP")
local isCC = environment.is("CC")
local isOC = environment.is("OC")

if isCP then
    return natives.require().require "http"
end

local http = {}
http.available = function()
    return not not ((isCC and natives.http) or (isOC and pcall(natives.request, "internet")))
end

http.request = function()
    
end

return http