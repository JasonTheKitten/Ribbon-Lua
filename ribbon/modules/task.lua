local task = ...

--TODO: Integration with process module

task.createTaskSystem = function()
    local tasko, tasks, taskFuncs, id, curID, running = {}, {}, {}, -1, 0, true
    
    tasko.register = function(f)
        while taskFuncs[id] do id=(id+1)%math.huge end
        taskFuncs[id] = f
        task[id] = coroutine.create(f)
        return id
    end
    tasko.unregister = function(id)
        tasks[id] = nil
        taskFuncs[id] = nil
    end
    
    tasko.setCurrentTask = function(id)
        curID = id
        coroutine.yield()
    end
    tasko.getCurrentTask = function() return curID end
    tasko.reset = function(id)
        id = id or curID
        tasks[id] = coroutine.create(taskFuncs[id])
    end
    
    tasko.execute = function(id)
        local ok, err
        running, curID = true, id or curID
        while running and tasks[curID] and coroutine.status(tasks[curID])~="dead" do
            ok, err = coroutine.resume(tasks[curID])
            coroutine.yield()
        end
        if not ok then error(err, -1) end
    end
    tasko.continue = function(id)
        curID = id or curID
        local ok, err = coroutine.resume(tasks[curID])
        if not ok then error(err, -1) end
    end
    tasko.continueAll = function(e)
        for k, v in pairs(tasks) do
            local ok, err = coroutine.resume(tasks[curID])
            if e and not ok then e(err, -1) end
        end
    end
    tasko.purgeDead = function()
        for k, v in pairs(tasks) do
			if coroutine.status(v) == "dead" then
				tasks[k] = v
				taskFuncs[k] = v
			end
        end
    end
	tasko.checkEmpty = function()
        for k, v in pairs(tasks) do return false end
		return true
    end
	
    tasko.quit = function()
        running = false
        coroutine.yield()
    end
    
    return tasko
end

for k, v in pairs(task.createTaskSystem()) do
    task[k] = v
end