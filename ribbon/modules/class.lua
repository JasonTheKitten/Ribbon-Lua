local class = ...

class.new = function(class, ...)
	if not class then error("No class provided", 2) end
	function class:__index(key)
		local queue = {self}
		while #queue>0 do
			if rawget(queue[1], key) then
				return rawget(queue[1], key)
			end
			for i=#queue[1].cparents, 1, -1 do
				table.insert(queue, 2, queue[1].cparents[i])
			end
			table.remove(queue, 1)
		end
	end
	
	local rtn = {cparents = {class}}
	setmetatable(rtn, class)
	
	if class.__call then
		rtn(...)
	end
	
	return rtn
end

--Class
local Class = {}
Class.cparents = {}
Class.__eq = rawequal
function Class:isA(class)
	local queue = {self}
	local p=0
	while #queue>p do
		p=p+1
		if rawequal(queue[p], class) then
			return true
		end
		for i=#queue[p].cparents, 1, -1 do
			table.insert(queue, queue[p].cparents[i])
		end
	end
	return false
end
class.Class = Class

class.checkType = function(c, e, t, m, ...)
	local args = {...}
	table.insert(args, e)
	local o = (type(c) == "table") and c.isA
	if o then 
		o = false
		for k, v in pairs(args) do
			o = o or (c:isA(v) and c~=v)
		end
	end
	if t and not o then
		local _, err = pcall(error, "", t or 2)
		local msg = ((m and "Expected "..m.." Class, got other value")  or "Incorrect Value Passed").."\n\tat "..err:sub(1, -3)
		error(msg, (t or 0)+1)
	end
end