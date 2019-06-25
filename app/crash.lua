local err1, err2 = ...
print(err1)
print(err2)

local cplat = require()
local debugger = cplat.require("debugger")
debugger.error(err1)
debugger.error(err2)