local ribbon = require()

local fs = ribbon.require "filesystem"
local environment = ribbon.require "environment"

local isOC = environment.is("OC")

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
util.reverse = function(tbl, reversed)
	reversed = reversed or {}
	for k, v in pairs(tbl) do
		reversed[v] = k
	end
	return reversed
end

util.pairs = function(tbl)
	return pairs(util.copy(tbl))
end
util.ipairs = function(tbl)
	return ipairs(util.copy(tbl))
end
util.ripairs = function(tbl)
	local i=#tbl+1
	return function()
		if i>1 then
			i = i - 1
			return i, tbl[i]
		end
	end
end
util.findValue = function(tbl, val)
    local matches = {}
    for k, v in pairs(tbl) do
        if rawequal(v, val) then
            table.insert(matches, k)
        end
    end
    return matches
end
util.getHighestIndex = function(tbl)
    local high = 0
    for k, v in pairs(tbl) do
		if type(k) == "number" then
			high = math.max(high, k)
		end
	end
	return high
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
util.stringFindAny = function(part, pattern, index)
	if isOC then
		local fres
		for i=1, #pattern do --Avoid patterns, as they are slow on OC
			local res = part:find(pattern:sub(i, i), index)
			if res then
				fres = fres or res
				fres = (res<fres and res) or fres
			end
		end
		return fres
	else
		return part:find("["..pattern.."]", index)
	end
end
util.split = function(str, l)
    local split = {}
    for part in str:gmatch("([^%.]+)") do
        table.insert(split, part)
    end
    return split
end

util.merge = function(tbl1, tbl2)
    for k, v in pairs(tbl2) do tbl1[k] = v end
end
util.union = function(tbl1, tbl2)
    for k, v in ipairs(tbl2) do table.insert(tbl1, v) end
end
util.slice = function(tbl1, tbl2, index)
    if index>0 then
        while tbl1[index] do
            table.insert(tbl2, tbl1[index])
            table.remove(tbl1, index)
        end
    else
        --TODO
    end
end

util.unpack = function(tbl, pos)
    local str, pos, high = "return ", pos or 1, util.getHighestIndex(tbl)
    if high==#tbl then return table.unpack(tbl, pos) end
    for i=pos, high do
		str=str.."_["..tostring(i).."],"
	end
    return loadstring(str:sub(1, -1), "t", "util<unpack>", {_=tbl})()
end
util.unpackNoNil = function(tbl, pos, value)
    local unpacked, pos, high = {}, pos or 1, util.getHighestIndex(tbl)
    if high==#tbl then return table.unpack(tbl, pos) end
	for i=pos, high do
		unpacked[i-pos+1] = tbl[i] or value or false
	end
	return table.unpack(unpacked)
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
	local i = 0
	local function q(...)
		qt[#qt+1] = {...}
	end
	q(...)
	while #qt>0 do
		local qtI = qt[#qt]
		qt[#qt] = nil
		if qtI and qtI[1] then
			qtI[1](q, util.unpackNoNil(qtI, 2))
		end
	end
end