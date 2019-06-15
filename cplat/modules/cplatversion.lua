local cpv = ...

local mv,miv,pv = 0,0,0
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
	return mv,miv,pv
end
cpv.getVersionString = function()
	return tostring(mv).."."..tostring(miv).."."..tostring(pv)
end
cpv.getCodeName = function()
	return cn
end
cpv.getVersionDisplayString = function()
	local vs = "v"..cpv.getVersionString()
	if not cn then return "CPlat "..vs
	if cn:lower()=="alpha" or cn:lower()=="beta" then
		return "CPlat "..vs.." "..cn
	else
		"CPlat "..cn.." "..vs
	end
end