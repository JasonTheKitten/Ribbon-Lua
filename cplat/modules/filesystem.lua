local cplat = require()
local environment = cplat.require "environment"

local natives = environment.getNatives()

local isCC = environment.is("CC")
local isOC = environment.is("OC")

local nfs = (isOC and natives.require("filesystem")) or (isCC and natives.fs)

local filesystem = {}

filesystem.exists = (isOC and nfs.exists) or (isCC and nfs.exists)
filesystem.isDir = (isOC and nfs.isDirectory) or (isCC and nfs.isDir)
filesystem.isFile = function(f) return filesystem.exists(f) and not filesystem.isDir(f) end

filesystem.combine = function(a, b)
    if isCC then
        return nfs.combine(a, b)
    elseif isOC then
        return nfs.canonical(a).."/"..nfs.canonical(b)
    end
end

filesystem.list = function(dir)
	dir = "/"..dir
    if isCC then
        return nfs.list(dir)
    elseif isOC then
        local flist = {}
        local it = nfs.list(dir)
        for nf in it do
            table.insert(flist, nf)
        end
        return flist
    end
end
filesystem.listRecursive = function(f, typ)
	f="/"..f
	if not filesystem.exists(f) then return false, "File does not exist" end
	local list = {}
	local queue = {f}
	while #queue>0 do
		local cf = queue[1]
		table.remove(queue, 1)
		if filesystem.isFile(cf) then
			if typ=="file" or typ=="all" or not typ then table.insert(list, cf) end
		else
			if typ=="folder" or typ=="all" or not typ then table.insert(list, cf) end
			for k, v in pairs(filesystem.list(cf)) do
				table.insert(queue, cf.."/"..v)
			end
		end
	end
	
	return list
end

local handleMethods = {"close", "flush", "lines", "read", "setvbuf", "seek", "write"}
filesystem.open = function(file, mode)
	if not mode then error("filemode not set", 2) end
    local mio = io.open("/"..file, mode)
    local handle = {}
    for k, v in pairs(handleMethods) do 
        if type(mio[v]) == "function" then
			local fname=v
            handle[v] = function(...) return mio[fname](mio, ...) end 
        end
    end
    if handle.read then
        handle.readAll = function()
            return handle.read("*a")
        end
    end
	if handle.lines then
		handle.readLine = function()
			return handle.lines()()
		end
	end
    
    return handle
end

filesystem.delete = function(f, re)
	local ok, err
	if isCC then
		ok, err = pcall(nfs.delete, f)
	else
		ok, err = nfs.remove("/"..f)
	end
	if not (ok or ree) then error(err, 2) end
	return ok, ree
end
filesystem.copy = function(f, d, re)
	f="/"..f
	local list, err = gfr(f)
	if not list then 
		if re then return false, err end
		error(err, 2)
	end
	
	local ok = true
	if isCC then
		ok, err = pcall(nfs.copy, f, d)
	else
		for k, v in pairs(filesystem.listRecursive(f, "files")) do
			local r = v:gsub(f, d)
			local ok2, err2 = nfs.rename(v, r)
			ok = ok and ok2
			err = err or err2
		end
	end
	if not (ok or re) then error(err, 2) end
	return ok, err
end
filesystem.move = function(f, d, re)
	local ok, err = pcall(filesystem.copy, f, d, true)
	if ok then filesystem.delete("/"..f) end
	if not (ok or re) then error(err, 2) end
	return ok, err
end

--TODO: MOUNTING/LINKING/DISKS/FREESPACE/ETC

return filesystem