local Remotes = {}

addEventHandler("onPlayerQuit",getRootElement(),function()
    if type(Remotes[source]) == "table" then 
        Remotes[source] = nil
        collectgarbage("collect")
    end
end)

addEvent("GTML:DestroyElement",true)
addEventHandler("GTML:DestroyElement",getRootElement(),function(element)
    if type(element) == "table" then 
        if type(Remotes[source]) == "table" then 
            if type(Remotes[source][element]) == "table" then
                for key in pairs(Remotes[source][element]) do 
                    triggerEvent("GTML:RemoveFetchRemote",source,element,key)
                end
                Remotes[source][element] = nil
                collectgarbage("collect")
            end
        end
    end
end)

addEvent("GTML:FetchRemote",true)
addEventHandler("GTML:FetchRemote",getRootElement(),function(element,key,url,options,BandWidth,update)
    if type(element) == "string" and type(key) == "string" and type(url) == "string" then 
        if type(options) == "table" then 
            if type(Remotes[source]) ~= "table" then 
                Remotes[source] = {}
            end
            if type(Remotes[source][element]) ~= "table" then 
                Remotes[source][element] = {}
            end
            local remote = {
                done = false,
                options = options,
                key = key
            }
            local player = source
            remote.material = fetchRemote(url,options,function(buffer,info)
                triggerLatentClientEvent(player,"GTML:FetchRemoteCallback",BandWidth,player,element,key,buffer,info)
                remote.handler = GetLastLatentHandler(player)
                local last = 0
                Remotes[player][element][key].timer = setTimer(function()
                    local status = getLatentEventStatus(player,remote.handler)
                    if type(status) == "table" then
                        if last ~= status.percentComplete then
                            triggerClientEvent("GTML:UpdateFetchRemote",player,element,key,status)
                            last = status.percentComplete
                        end
                    else
                        remote.done = true
                        triggerEvent("GTML:RemoveFetchRemote",player,element,key)
                    end
                end,update*1000,0)
            end)
            Remotes[source][element][key] = remote
        end
    end
end)

addEvent("GTML:RemoveFetchRemote",true)
addEventHandler("GTML:RemoveFetchRemote",getRootElement(),function(element,key)
    if type(element) == "string" and type(key) == "string" then
        if type(Remotes[source]) == "table" then
            if type(Remotes[source][element]) == "table" then 
                if type(Remotes[source][element][key]) == "table" then
                    if not Remotes[source][element][key].done then
                        if Remotes[source][element][key].material then 
                            abortRemoteRequest(Remotes[source][element][key].material)
                        end
                    end
                    local handler = tonumber(Remotes[source][element][key].handler)
                    if handler then
                        if type(getLatentEventStatus(source,handler)) == "table" then 
                            cancelLatentEvent(source,handler)
                        end
                    end
                    if isTimer(Remotes[source][element][key].updater) then 
                        killTimer(Remotes[source][element][key].updater)
                    end
                    Remotes[source][element][key] = nil
                    collectgarbage("collect")
                end
            end
        end
    end
end)

function GetLastLatentHandler(player)
    if isElement(player) then 
        local latents = getLatentEventHandles(player)
        if type(latents) == "table" then
            return latents[#latents] 
        end
    end
end