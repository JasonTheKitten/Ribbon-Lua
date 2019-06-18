local cplat = require()

local environment = ... --{}
local envn = cplat.installGlobals({})

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

environment.getDefault = function()
    return _ENV or _G
end

environment.getNatives = function()
    return envn
end

if environment.is("CP") then
	error("Nesting CPlat applications is not supported at this time; Please use the \"shell\" module instead.", -1)
end

--return environment