local class = ...

--Flags
class.useMethodCache = true
class.useFieldCache = false

--Class
local Class = {}
class.Class = Class

Class.cparents = {}
--Class.__eq = rawequal
function Class:isA(class)
	local queue = {self}
	local p=0
	while #queue>p do
		p=p+1
		if rawequal(queue[p], class) then
			return true
		end
		for i=#queue[p].cparents, 1, -1 do
			queue[#queue+1] = queue[p].cparents[i]
		end
	end
	return false
end

--class
class.new = function(nclass, ...)
	if not nclass then error("No class provided", 2) end
	if not class.useMultiParent then
    	function nclass:__index(key)
    		local rtn = rawget(self, "cparents")[1]
    		while rtn do
                local res = rtn[key]
                if res then
                    if (class.useMethodCache and class.useFieldCache) or
                        (class.useMethodCache and type(res) == "function") or
                        (class.useFieldCache and type(res) ~= "function") then
                        self[key] = res
                    end
                    return res
                end
				if not rtn.cparents then error("cparents field missing", 2) end
                rtn=rtn.cparents[1]
    	    end
        end
    else
        function nclass:__index(key)
            local queue = {self}
    		local p=0
    		while #queue>p do
    			p=p+1
    			local res = rawget(queue[p], key)
    			if res then
                    if (class.useMethodCache and class.useFieldCache) or
                        (class.useMethodCache and type(res) == "function") or
                        (class.useFieldCache and type(res) ~= "function") then
                        self[key] = res
                    end
    				return res
    			end
    			for i=#queue[p].cparents, 1, -1 do
    				queue[#queue+1]=queue[p].cparents[i]
    			end
    		end
        end
    end
	
	local rtn = {cparents = {nclass}}
	setmetatable(rtn, nclass)
	
	if nclass.__call then
		rtn(...)
	end
	
	return rtn
end

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