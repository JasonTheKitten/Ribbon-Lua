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
	while #queue>0 do
		if queue[1] == class then
			return true
		end
		for i=#queue[1].cparents, 1, -1 do
			table.insert(queue, 2, queue[1].cparents[i])
		end
		table.remove(queue, 1)
	end
	return false
end
class.Class = Class