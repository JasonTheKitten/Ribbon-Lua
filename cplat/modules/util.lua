--TODO: util.reverse
local util = ...

util.copy = function(val)
	if type(val) == "table" then
		local copy = {}
		for k, v in pairs(val) do copy[k] = v end
		return copy
	else
		return val
	end
end

util.pairs = function(tbl)
	return pairs(util.copy(tbl))
end
util.ipairs = function(tbl)
	return ipairs(util.copy(tbl))
end

util.stringToTable = function(s, r)
	local tbl = {}
	for i=1, #s do
		if r then 
			tbl[s:sub(i, i)] = i
		else
			tbl[i] = s:sub(i, i)
		end
	end
	return tbl
end