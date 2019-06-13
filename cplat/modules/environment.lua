local cplat = require()

local environment = ... --{}
local envn = cplat.installGlobals({})

local function getRoot()
	local plat = cplat
	while plat.require("environment").is("CP") do
		plat = plat.require("environment").getNatives().require()
	end
	
	return plat
end

environment.is = function(m)
    m=m:lower()
    if (m=="cplat" or m=="cp") and pcall(envn.require, "") then
        return true
    elseif (m=="computercraft" or m=="cc") and envn.fs then
        return true
    elseif (m=="opencomputers" or m=="oc") and pcall(envn.require, "filesystem") then
        return true
    end
    
    return false
end
environment.isNP = function(m)
	return getRoot().is(m)
end

environment.isRoot = function()
	return getRoot()==cplat
end

environment.getDefault = function()
    return _ENV
end

environment.getNatives = function()
    return envn
end
environment.getNativesRoot = function()
	return getRoot().require("environment").getNatives()
end

--return environment