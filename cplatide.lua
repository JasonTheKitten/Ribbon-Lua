--TODO: Support CPlat on other bios/OS
--TODO: Make CPlat yield during sleep in OC

--App Info
local APP = {
	TYPE = "GRAPHICAL",
	PATHS = {
		APP = "${PATH}/app",
		ASSETS = "${PATH}/assets",
		BIN = "${PATH}/bin",
		CMD = "${APP}/app.lua",
		DATA = "${APP}/data",
		ROOT = "/",
		
		PATH = nil,
		CPLAT = nil,
	},
	CONTEXT = nil,
	TITLE = "APPLICATION",
}

--Configs
--#@Configs

--Glue
local baseError = "App failed to launch!"
local results = {pcall(function(...)
	--Alt require
	local function prequire(file)
		local ok, rtn = pcall(require, file or "")
		if ok then return rtn end
	end
	
    --Check environment
	local shell = shell or prequire("shell")
	local process = process or prequire("process")
	local filesystem = filesystem or prequire("filesystem")
	if not loadfile or not ((shell and fs) or (shell and process and filesystem)) then
		error("Unsupported operating environment")
	end
	
	--Set shell name
	if multishell then
		sleep(0)
		multishell.setTitle(multishell.getFocus(), APP.TITLE)
	end
	
	--Config fallback
	local APP = APP or {}
	APP.PATHS = APP.PATHS or {}
	
	local paths = APP.PATHS

    --Resolve paths
    if not paths["PATH"] then
		paths["PATH"] = "./"
		if process then
    		paths["PATH"] = filesystem.concat(shell.resolve(process.info(1).path), "..")
    	elseif shell then
    		paths["PATH"] = fs.getDir(shell.getRunningProgram())
    	end
    end

	if not paths["CPLAT"] then
        paths["CPLAT"] = paths["PATH"].."/cplat"
	end
	
	--Load app
	local corePath = paths["CPLAT"].."/cplat.lua"
	local cplat, err = loadfile(corePath)
	if err then
		baseError = "Corrupt or Missing File!"
		error("FILE: "..corePath.."\nERROR: "..err)
	end
	
	--Setup CPlat
	baseError = "App failed to launch!"
	cplat = cplat()
	
	--Setup App
	cplat.setAppInfo(APP)
	
	--Execute app
	baseError = "Application crashed!"
	return cplat.execute(APP.PATHS.CMD, ...)
	
end, ...)}

--Error checking
if not results[1] then
    baseError = (type(baseError) == "string" and baseError) or 
        "A fatal error has occured!"
	local err = results[2] or ""
	error(baseError.."\n"..err, -1)
end

--Return results
return (unpack or table.unpack)(results, 2)