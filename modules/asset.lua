local ribbon = require()

local util = ribbon.require "util"

local asset = ...

local groups = {}
asset.load = function(g, f)
    local unserialize = util.unserialize

	local data
	if type(f) == "table" then
		data = f
	else
		data = unserialize(util.inf(f))
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
asset.save = function(g, f, json)
    local serialize = (json and util.serializeJSON) or util.serialize
	if type(g) == "string" then
		return util.outf(f, serialize(groups[g]))
	else
		return util.outf(f, serialize(g))
	end
end