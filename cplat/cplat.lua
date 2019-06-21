--CPlat Core
local cplat = {}

--Execution environment header
local env = {}

--App Info
local nAPP = {
	PATHS={},
	TYPE = "",
	CONTEXT = nil
}
local APP = {}
for k, v in pairs(nAPP) do APP[k] = v end
cplat.setAppInfo = function(inf)
    APP = inf
	APP.TYPE = APP.TYPE or nAPP.TYPE
    
    return cplat
end
cplat.getAppInfo = function()
    return APP
end

--OC/CC
local isOC = not not pcall(require, "term")

--Paths
cplat.setPaths = function(paths)
    if not paths then
        appInfo.PATHS = {}
    else
        for k, v in pairs(paths) do
            if type(k)~="string" then
                appInfo.PATHS[v] = nil
            else
                appInfo.PATHS[k] = v
            end
        end
    end
end
cplat.resolvePath = function(path, ftable, maxTries)
    if path:sub(1, 1) == "!" then return path:sub(2, #path) end
    if path:sub(1, 1) == "#" then path = path:sub(2, #path) end
    
	maxTries = maxTries or APP.PATHRESOLUTIONTRIES or 50

    local pathreps = {}
    for k, v in pairs(APP.PATHS) do pathreps[k] = v end
    for k, v in pairs(ftable or {}) do pathreps[k] = v end
    
	--We must resolve multiple times, as some paths may reference others
	local oldpath, tries = "", 0
	while oldpath~=path do
		if tries>maxTries and maxTries>0 then error("Path resolve failed", 2) end
		tries=tries+1
		oldpath = path
		for k, v in pairs(pathreps) do path = path:gsub("${"..k.."}", v) end
	end
    return path:gsub("$#", "$")
end

--Require CPlat modules
local required = {}
cplat.require = function(p)
    if required[p] then
        return required[p]
    end
    required[p] = {}
	local m, err=env.loadfile(cplat.resolvePath(
        "${CPLAT}/modules/${module}.lua", {module=p}
    ), "t", env)
	if not m then error("Failed to load module \""..p.."\" because:\n"..err, 2) end
	local extramethods=m(required[p])
	
	--I can not decide if I should deprecate this
	--A bit of a hacky solution, does not support pairs
	setmetatable(required[p], {
		__index=extramethods
	})
	
    return required[p]
end

--Execute
cplat.execute = function(path, ...)
	--Cache certain modules
	cplat.require("cplatos")

	--Execute
	if not path then error("No path supplied", 2) end
	local func, err = env.loadfile(cplat.resolvePath(path), "t", env)
	if not func then error(err, 2) end
	cplat.require("process").execute(func, ...)
end

--Arg passing
local passArgs = {}
cplat.getPassArgs = function()
	local mpa = passArgs
	passArgs = {}
	return env.table.unpack(mpa)
end
cplat.setPassArgs = function(...)
	passArgs = {...}
end

--Other stuff
cplat.installGlobals = function(tbl)
    (tbl or env)._G = _ENV or _G
    return (tbl or env)._G
end

--Functions for env
local nloadfile = loadfile
local function loadfile(f, m, e)
    if type(m) == "table" then e=m m="t" end
    if fs then return nloadfile(f, e)
    else return nloadfile(f, m, e)
    end
end
local function sleep(t)
	local proc = cplat.require("process")
	local ev = cplat.require "environment"
	--local ie = proc.getInterruptsEnabled()
	--proc.setInterruptsEnabled(false)
	local time = os.clock()+t
	while os.clock()<time do
		coroutine.yield()
	end
	--proc.setInterruptsEnabled(ie)
end
local rawlen = rawlen or function(v)
    return #v
end
local dofile = dofile --TODO
local mos = {}
for k, v in pairs(os) do mos[k] = v end

--Execution environment
env._ENV = env
env._VERSION = _VERSION or "Lua 5.2"
env.assert = assert
env.collectgarbage = collectgarbage or function() end
env.dofile = dofile
env.error = error
env.getmetatable = getmetatable
env.ipairs = ipairs
env.load = load
env.loadfile = loadfile
env.next = next
env.pairs = pairs
env.pcall = pcall
env.print = print
env.rawequal = rawequal
env.rawget = rawget
env.rawlen = rawlen
env.rawset = rawset
env.read = function() return io.read() end
env.select = select
env.setmetatable = setmetatable
env.sleep = sleep
env.tonumber = tonumber
env.tostring = tostring
env.type = type
env.xpcall = xpcall

--TODO: Sandbox these, install/fix missing/outdated functions
env.bit32 = bit32
env.coroutine = coroutine
env.debug = debug
env.io = io
env.math = math
env.os = mos
env.string = string
env.table = table

env.table.unpack = table.unpack or unpack

local package = {
    loaded = {},
    config = "/\n;\n?\n!\n-",
    path = "?;?.lua;",
    preload = {}
}
env.package = package
env.require = function(arg)
    if (not arg) or (arg=="") then
        return cplat
    end
    if package.loaded[arg] then 
        return package.loaded[arg] 
    end
    --TODO: Require
end
--TODO: Package

--Fix time
if isOC then
	local nc = os.clock
	mos.clock = function()
		return nc()*20
	end
end


--Return functions
return cplat