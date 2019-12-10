local ribbon = require()
local environment = ribbon.require "environment"

local natives = environment.getNatives()

local isCC = environment.is("CC")
local isOC = environment.is("OC")

local component = natives.component

local http = {}
http.available = function()
    if isCC then
        return not not natives.http
	elseif isOC then
		return true
    end
end

http.request = function(url, post, headers)
    local handle
    if isCC then
        natives.http.request(url, post, headers)
    elseif isOC then
        local internet = component.proxy(component.list("gpu", true)())
    end
end

return http
