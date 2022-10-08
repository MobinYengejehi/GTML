function UpdateElementStyle(element)
    if IsElement(element) then
        
    end
end

function SetElementStyleProperty(element,property,value)
    if IsElement(element) and type(property) == "string" then
        local style = GetElementStyle(element)
        if type(style) == "table" then
            local last = style[property]
            style[property] = value
            if value ~= last then
                TriggerEvent("onClientGTMLElementStylePropertyChange",element,property,last,value)
                UpdateElementStyle(element)
            end
        end
    end
end

function GetElementStyleProperty(element,property)
    if IsElement(element) and type(property) == "string" then 
        local style = GetElementStyle(element)
        if type(style) == "table" then
            return style[property]
        end
    end
end

function SetElementStyle(element,data)
    if IsElement(element) and type(data) == "table" then 
        for property,value in pairs(data) do 
            SetElementStyleProperty(element,property,value)
        end
    end
end

function GetElementStyle(element)
    if IsElement(element) then 
        return GetElementData(element,"style")
    end
end