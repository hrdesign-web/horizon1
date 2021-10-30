--@class IOScheduler

--[[
Custom IO scheduler to deal with limited data packet size
and tick rate of screen send/recieve. IOScheduler.defaultData
will send as fast as possible, while IOScheduler.queueData()
will interrupt default send and to send queued data.
--]]

IOScheduler = (function()
    local self = {}
    
    self.defaultData = nil
    self.currentTask = nil
    self.taskQueue = {}
    function self.queueData(data)
         table.insert(self.taskQueue, data)
    end
    --Send queued data to screen
    function self.send(T)
        output = screen.getScriptOutput()
        screen.clearScriptOutput()
        if output ~= "ack" then
            if output ~= "" then
                handleOutput.Read(output)
            end
            coroutine.yield()
            self.send(T)
        else
            screen.setScriptInput(serialize(T))
        end
    end
    --Queue data to send or send self.defaultData
    function self.runQueue()
        if #self.taskQueue == 0 then
            --Send default table
            if self.defaultData ~= nil then
                   self.currentTask = coroutine.create(function()
                       self.send(self.defaultData)
                   end)
            coroutine.resume(self.currentTask)
            end
        else
            --Iterate over self.taskQueue and send each to screen
            self.currentTask = coroutine.create(function()
                for i=1, #self.taskQueue do
                    local data = self.taskQueue[i]
                    if type(data) == "table" then
                        self.send(data)
                    end
                    table.remove(self.taskQueue,i)
                end
            end)
            coroutine.resume(self.currentTask)
        end
    end
    
    --Add to system.update()
    function self.update()
        if self.currentTask then
            if coroutine.status(self.currentTask) ~= "dead" then
                coroutine.resume(self.currentTask)
            else
                self.runQueue()
            end
        else
            self.runQueue()
        end
    end
    
    return self
end)()

HandleOutput = (function()
    local self = {}
    function self.Read(output)
        --system.print("handleOutput.Read(): "..output)
        if output ~= nil and output ~= "" then
            if type(output) == "string" then
                --system.print(output)
                local s = deserialize(output)

                if s.dataType == "config" then
                    config = s
                    stats.data.target = config.targetAlt
                    self.Execute()
                elseif s.updateReq then
                    ioScheduler.queueData(config)
                else
                    system.print(tostring(s))
                end
            end
            
        end
    end

    function self.Execute()
        ship.baseAltitude = helios:closestBody(ship.customTarget):getAltitude(ship.customTarget)
        
        ship.altitudeHold = config.targetAlt
        
        if config.estop then
            
            ship.altitudeHold = 0
            config.targetAlt = 0
            ship.verticalLock = false
            ship.elevatorActive = false
            ship.brake = true
            ship.stateMessage = "EMERGENCY STOP"
            system.print(ship.stateMessage)
            ioScheduler.queueData(config)
        else
            ship.brake = false
        end
        if ship.altitudeHold ~= 0 then
            ship.elevatorActive = true
            system.print("Alt diff: "..(config.targetAlt - ship.baseAltitude))
            ship.targetDestination = moveWaypointZ(ship.customTarget, config.targetAlt - ship.baseAltitude)
        end
        if config.setBaseReq then
            setBase()
            config.setBaseReq = false
            ioScheduler.queueData(config)
        end
        --if config.updateReq then
        --    config.updateReq = false
        --    ioScheduler.queue(config)
        --end
        manualControlSwitch()
    end

    return self
end)()

ioScheduler = IOScheduler
handleOutput = HandleOutput