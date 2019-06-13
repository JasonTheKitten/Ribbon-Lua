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