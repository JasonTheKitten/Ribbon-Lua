local ribbon = require()

local environment = ...
local envn = ribbon.installGlobals({})

--Compatibility
local mrequire = envn.require or function()
	error("Require is not supported")
end

environment.is = function(m)
    m=m:lower()
    if (m=="ribbon" or m=="rb") and pcall(mrequire, "") then
        return true
    elseif (m=="computercraft" or m=="cc") and envn.fs then
        return true
    elseif (m=="opencomputers" or m=="oc") and pcall(mrequire, "filesystem") then
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

if environment.is("RB") then
	error("Nesting Ribbon applications is not supported at this time; Please use the \"shell\" module instead.", -1)
end