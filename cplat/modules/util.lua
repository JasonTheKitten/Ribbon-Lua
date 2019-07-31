local cplat = require()

local fs = cplat.require "filesystem"

--TODO: util.reverse
local util = ...

--Tables
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

util.unpackNoNil = function(tbl, pos)
	local unpacked, pos, high = {}, pos-1, 0
	for k, v in pairs(tbl) do
		if type(k) == "number" and k>pos then
			unpacked[k-pos] = v
			
			high = math.max(high, k-pos)
		end
	end
	for i=1, high do
		unpacked[i] = unpacked[i] or false
	end
	return table.unpack(unpacked)
end

util.stringToTable = function(s, r, t)
	t = t or {}
	for i=1, #s do
		if r then 
			t[s:sub(i, i)] = i
		else
			t[i] = s:sub(i, i)
		end
	end
	return t
end

--File ops
util.inf = function(f)
	local ok, h = pcall(fs.open, f, "r")
	if ok and h then
		local c = h.readAll()
		h.close()
		return c
	end
end
util.outf = function(f, c)
	local ok, h = pcall(fs.open, f, "wb")
	if ok and h then
		h.write(c)
		h.close()
		return true
	end
end
util.appf = function(f, c)
	local ok, h = pcall(fs.open, f, "ab")
	if ok and h then
		h.write(c)
		h.close()
		return true
	end
end

-- Table <--> String
local q = "\""
local serializeTable, serializeTableJSON
local function formatString(str)
	return "\""..
		str:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\f", "\\f")
	.."\""
end
local function formatValue(v, d)
	d = not d
	if type(v) == "string" then
		return formatString(v)
	elseif type(v) == "number" then
		return tostring(v):gsub("inf", "1/0"):gsub("nan", "0/0")
	elseif type(v) == "table" and d then
		return serializeTable(v)
	elseif v == util.EMPTY_ARRAY and not d then
		return "[]"
	elseif type(v) == "table" then
		return serializeTableJSON(v)
	elseif type(v) == "function" and d then
		return "load("..formatString(string.dump(v))..")"
	elseif type(v) == "thread" and d then
		return "coroutine.create(function() end)"
	elseif type(v) == "nil" and d then
		return "nil"
	elseif type(v) == "nil" then
		return "undefined"
	else
		local ok, r = pcall(tostring, v)
		return (ok and formatString(r)) or (d and "nil") or "undefined"
	end
end
local sandbox = {
	load = function(s) return load(s, "<chunk>", "tb", {}) end,
	coroutine = {
		create = coroutine.create,
	},
}

serializeTable = function(d)
	local tbl, r = "{", {}
	for k, v in ipairs(d) do
		r[k] = true
		tbl=tbl..formatValue(v)..","
	end
	for k, v in pairs(d) do
		if not r[k] then
			tbl=tbl.."["..formatValue(k).."]="..formatValue(v)..","
		end
	end
	return tbl.."}"
end
serializeTableJSON = function(d)
	local a, r = (#d>0) or d[0], {[0] = true}
	for k, v in ipairs(d) do
		r[k] = true
	end
	for k, v in pairs(d) do
		if not r[k] then
			a = false
			break
		end
	end
	if a then
		local tbl = "["
		for i=0, #d do
			tbl = tbl..formatValue(d[i], true)..","
		end
		return tbl.."]"
	end
	local tbl = "{"
	for k, v in pairs(d) do
		if not r[k] then
			tbl=tbl.."["..formatValue(k, true).."]:"..formatValue(v, true)..","
		end
	end
	return tbl.."}"
end
util.EMPTY_ARRAY = {}
util.serialize = function(d)
	return formatValue(d)
end
util.unserialize = function(d)
	local ok, e = pcall(load, "return "..d, "<chunk>", "tb", sandbox)
	if not (ok and e) then return end
	ok, e = pcall(e)
	if ok and e then return e end
end
util.serializeJSON = function(d)
	return formatValue(d, true)
end

--TODO: Include a JSON parser

util.serialise = util.serialize
util.unserialise = util.unserialize
util.serialiseJSON = util.serializeJSON

--Helper functions
util.runIFN = function(...)
	--Run ISomething FSomething NSomething
	--This is why we need better function names (:
	--Maybe change the name on a major version update someday?
	local qt = {}
	local function q(...)
		table.insert(qt, 1, {...})
	end
	q(...)
	while #qt>0 do
		local qt1 = qt[1]
		table.remove(qt, 1)
		if qt1 and qt1[1] then
			qt1[1](q, util.unpackNoNil(qt1, 2))
		end
	end
end