local Data = {}

function SetElementData(element,key,value)
    if IsElement(element) and key ~= nil then 
        if type(Data[element]) ~= "table" then 
            Data[element] = {}
        end
        local success = Data[element][key] ~= value
        local old = Data[element][key]
        Data[element][key] = value
        if success then 
            triggerEvent("onClientGTMLElementDataChange",element,key,old,value)
        end
    end
end

function GetElementData(element,key)
    if IsElement(element) and key ~= nil then 
        if type(Data[element]) == "table" then 
            return Data[element][key]
        end
    end
end

function RemoveElementData(element,key)
    if IsElement(element) and key ~= nil then 
        if type(Data[element]) == "table" then
            triggerEvent("onClientGTMLElementDataRemove",element,key) 
            Data[element][key] = nil
            collectgarbage()
        end
    end
end

function ClearElementData(element)
    if IsElement(element) then 
        if type(Data[element]) == "table" then 
            triggerEvent("onClientGTMLElementDataClear",element)
            Data[element] = nil
            collectgarbage()
        end
    end
end