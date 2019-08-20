local ribbon = require()

local util = require "util"

local asset = ...

local groups = {}
asset.load = function(g, f)
	local data
	if type(f) == "table" then
		data = f
	else
		data = util.unserialize(util.inf(f))
	end
	
	g = g or {}
	if type(g) ~="table" then
		groups[g] = {}
		g = groups[g]
	end
	for k, v in pairs(data) do
		g[k] = v
	end
	return g
end
asset.get = function(g)
	return groups[g]
end
asset.save = function(g, f)
	if type(g) == "string" then
		return util.outf(f, util.serialize(groups[g]))
	else
		return util.outf(f, util.serialize(g))
	end
end