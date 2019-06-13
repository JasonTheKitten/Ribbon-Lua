local cplat = require()
local environment = cplat.require "environment"

local natives = environment.getNatives()

local isCP = environment.is("CP")
local isCC = environment.is("CC")
local isOC = environment.is("OC")

if isCP then
    return natives.require().require "filesystem"
end

local nfs = (isOC and natives.require("filesystem")) or (isCC and natives.fs)

local filesystem = {}

filesystem.combine = function(a, b)
    if isCC then
        return nfs.combine(a, b)
    elseif isOC then
        return nfs.canonical(a).."/"..nfs.canonical(b)
    end
end

filesystem.list = function(dir)
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

filesystem.exists = (isOC and nfs.exists) or (isCC and nfs.exists)
filesystem.isDir = (isOC and nfs.isDirectory) or (isCC and nfs.isDir)

filesystem.isFile = function(f)
	return filesystem.exists(f) and not filesystem.isDir(f)
end


local handleMethods = {
	"close",
	"flush",
	"lines",
	"read",
	"setvbuf",
	"seek",
	"write"
}
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

--TODO: MOUNTING/LINKING/DISKS/FREESPACE/DELETE/MOVE/ETC

return filesystem