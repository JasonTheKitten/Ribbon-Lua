local ribbon = require()

local class = ribbon.require "class"
local util = ribbon.require "util"

local stylesheet = ...

local Stylesheet = {}
stylesheet.Stylesheet = stylesheet

Stylesheet.cparents = {class.Class}
function Stylesheet:__call(query)
    class.__call(self)
    self.sheet = {}
    self.query = query
end

function Stylesheet:query(query)
    local oquery = self.query
    if not query == self.NIL then
        self.query = query
    end
    return oquery
end

function Stylesheet:apply(...)
    local args = {...}
    if #args = 0 then
        self:applyExcluding()
    else
        if type(args[0])=="table" then args=args[0] end

    end
end
function Stylesheet:applyExcluding(...)
    local args = {...}
    if type(args[0])=="table" then args=args[0] end
    local unapplied = util.reverse(args)
    local applied = {}
    for k, v in pairs(self.sheet) do
        if not args[k] then applied[#applied+1] = k end
    end
end

function Stylesheet:set()

end

Stylesheet.IGNORE = {}
Stylesheet.CLEAR = {}
Stylesheet.NIL = {}