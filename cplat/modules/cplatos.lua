--TODO: Cursor, notifications, icons, etc

--This file is used for passing data and action calls between 
--a host application and guest application

--View the metadata formatting standards at <insert_url_here>
--The metadata creation utility can be found at <insert_url_here>

local cplat = require()

local environment = cplat.require "environment"

local natives = environment.getNatives()

local cplatos = ...

local host = natives.CPLATHOST
cplatos.getHost = function()
	return host
end
cplatos.send = host.receive or function(g, d)

end
cplatos.receive = host.send or function(g)

end
cplatos.onHostEvent = function()

end
cplatos.set = function(g, d)

end
cplatos.get = function(g, d)

end