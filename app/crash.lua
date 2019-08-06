local err1, err2 = ...
print(err1)
print(err2)

if (err2:lower() ~= "user terminated application") and (err2:lower() ~= "interrupted") then
	local cplat = require()
	local debugger = cplat.require("debugger")
	debugger.error(err1)
	debugger.error(err2)
end