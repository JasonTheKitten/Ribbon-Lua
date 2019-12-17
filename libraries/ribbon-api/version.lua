local cpv = ...

local mv,miv,pv = 0,1,0
local cn = "ALPHA"

cpv.getMajorVersion = function()
	return mv
end
cpv.getMinorVersion = function()
	return miv
end
cpv.getPatchVersion = function()
	return pv
end
cpv.getVersions = function()
	return mv,miv,pv,cn
end
cpv.getVersionString = function()
	return tostring(mv).."."..tostring(miv).."."..tostring(pv)
end
cpv.getCodeName = function()
	return cn
end
cpv.getVersionDisplayString = function()
	local vs = "v"..cpv.getVersionString()
	if not cn then return "Ribbon "..vs
	if cn:lower()=="alpha" or cn:lower()=="beta" then
		return "Ribbon "..vs.." "..cn
	else
		"Ribbon "..cn.." "..vs
	end
end