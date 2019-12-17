--TODO: Timed macros
local ribbon = require()

local eventtracker = ribbon.require "eventtracker"
local process = ribbon.require "process"

local keyboard = eventtracker.keyboard

local macroapi = ...

macroapi.createMacroSystem = function()
    local macro, mr, id, pid = {}, {}, -1, nil
    
    macro.install = function()
        if pid then return end
        pid = process.addEventListener("key_down", function()
            for k, v in pairs(mr) do
                if macro.check(v[1]) then
                    v[2](v[1])
                end
            end
        end)
    end
    
    macro.cleanup = function()
        process.unregister(pid)
        pid = nil
    end
    
    macro.check = function(keys)
        for k, v in pairs(keys) do
            if not keyboard[v] then return false end
        end
        return true
    end
    
    macro.register = function(macro, f, ido)
        local mid = ido
        if not mid then
            while mr[id] do
                id=id+1
                if id>=math.huge then id = 0 end
            end
            mid = id
        end
        mr[mid] = {macro, f}
        return mid
    end
    macro.unregister = function(id)
        mr[id] = nil
    end
    
    macro.install()
    
    return macro, function(obj)
        for k, v in pairs(macro) do obj[k] = v end
    end
end

local macroo, installer = macroapi.createMacroSystem()
installer(macroapi)