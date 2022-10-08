local DEFAULT_REMOTE_MODE = "server"
local DOCUMENT_DISPLAY_ELEMENT = "body"

local OpenReqeusts = {}

addEvent("RequestForLoadCode")
addEvent("onClientGTMLElementCreate")
addEvent("onClientGTMLElementDestroy")
addEvent("onClientGTMLElementDataChange")
addEvent("onClientGTMLElementDataRemove")
addEvent("onClientGTMLElementDataClear")
addEvent("onClientGTMLDocumentCreate")
addEvent("onClientGTMLElementStylePropertyChange")
addEvent("onClientGTMLElementIDChange")
addEvent("onClientGTMLElementClassListChange")
addEvent("onClientGTMLElementClassAdd")
addEvent("onClientGTMLElementClassRemove")
addEvent("onClientGTMLElementAttributeChange")
addEvent("onClientGTMLElementDisplayModeChange")
addEvent("onClientGTMLElementResourceChange")
addEvent("onClientGTMLElementTextureChange")
addEvent("onClientGTMLElementTextureUpdate")

addEvent("GTML:UpdateFetchRemote",true)
addEvent("GTML:FetchRemoteCallback",true)
addEvent("onClientGTMLElementRemoteCallback",true)

addEventHandler("onClientResourceStart",resourceRoot,function()
    local document = CreateDocument{
        src = "example/index.gtml",
        width = 300,
        height = 300
    }
    local texture = GetElementTexture(document)
    
    addEventHandler("onClientRender",getRootElement(),function()
        dxDrawImage(200,200,300,300,texture)
    end)
end)

addEventHandler("onClientElementDestroy",getRootElement(),function()
    if IsElement(source) then
        triggerEvent("onClientGTMLElementDestroy",source)
        local children = GetElementChildren(source)
        if type(children) == "table" then
            for i,child in ipairs(children) do 
                destroyElement(child)
            end
        end
        if type(OpenReqeusts[source]) == "table" then 
            triggerServerEvent("GTML:DestroyElement",getLocalPlayer(),tostring(source))
            OpenReqeusts[source] = nil
        end
        local requests = GetElementFetchRemotes(source)
        if type(requests) == "table" then 
            for key in pairs(requests) do 
                RemoveElementFetchRemote(source,key,true)
            end
        end
        DetachElement(element)
        ClearElementData(element)
    end
end)

addEventHandler("GTML:FetchRemoteCallback",getLocalPlayer(),function(element,key,buffer,info)
    if type(element) == "string" and type(key) == "string" then 
        for e in pairs(OpenReqeusts) do 
            if tostring(e) == element then 
                element = e
            end
        end
        if IsElement(element) then
            local request = GetElementFetchRemote(element,key)
            if type(request) == "table" then 
                TriggerEvent("onClientGTMLElementRemoteCallback",element,key,{
                    buffer = buffer,
                    info = info
                })
                RemoveElementFetchRemote(element,key,true)
            end
        end
    end
end)

function LoadElementDocumentCode(element,code)
    if IsElement(element) and type(code) == "string" then
        local document = xmlLoadString(code)
        if document then
            local children = GetElementChildren(element)
            if type(children) == "table" then 
                for i,child in pairs(children) do 
                    destroyElement(child)
                end
            end
            local attributes = xmlNodeGetAttributes(document)
            if type(attributes) == "table" then
                for attribute,value in pairs(attributes) do 
                    if attribute == "class" then 
                        SetElementClass(element,value)
                    elseif attribute == "id" then 
                        SetElementID(element,value)
                    else
                        SetElementAttribute(element,attribute,value)
                    end
                end
            end
            children = GetXMLNodeChildren(document)
            if type(children) == "table" then
                CreateElementChildren(element,children)
            end
            xmlUnloadFile(document)
        end
    end
end

function CreateElementChildren(element,children)
    if IsElement(element) and type(children) == "table" then
        for i,child in ipairs(children) do 
            if type(child.name) == "string" and #child.name > 0 then 
                local elm = CreateElement(child.name)
                if IsElement(elm) then
                    AppendChild(element,elm) 
                    if type(child.attributes) == "table" then
                        for attribute,value in pairs(child.attributes) do 
                            if attribute == "class" then
                                SetElementClass(elm,value)
                            elseif attribute == "id" then
                                SetElementID(elm,value)
                            else
                                SetElementAttribute(elm,attribute,value)
                            end
                        end
                    end
                    if type(child.children) == "table" and #child.children > 0 then
                        CreateElementChildren(elm,child.children)
                    else
                        if type(child.value) == "string" and #child.value > 0 then 
                            SetElementAttribute(elm,"textContent",child.value)
                        end
                    end
                end
            end
        end
    end
end

function GetXMLNodeChildren(node)
    if node then
        local children = xmlNodeGetChildren(node)
        if type(children) == "table" then 
            local result = {}
            for i,child in ipairs(children) do 
                table.insert(result,{
                    name = xmlNodeGetName(child),
                    attributes = xmlNodeGetAttributes(child),
                    value = xmlNodeGetValue(child),
                    children = GetXMLNodeChildren(child),
                    node = child
                })
            end
            return result
        end
    end
end

function CreateDocument(data)
    if type(data) == "table" then
        local element = CreateElement("document")
        if IsElement(element) then
            local code = nil 
            if type(data.src) == "string" then 
                code = readFile(data.src)
            end
            if not code then
                code = data.inner
            end
            if type(code) == "string" then
                if type(data.resource) == "userdata" then 
                    SetElementResource(element,data.resource)
                end
                SetElementStyle(element,data.style)
                LoadElementDocumentCode(element,code)
                if not QuerySelector(element,"head") then 
                    CreateElement("head",element)
                end
                if not QuerySelector(element,"body") then 
                    CreateElement("body",element)
                end
                if data.width and data.height then 
                    SetElementTexture(element,CreateTexture(data.width,data.height,function(texture)
                        TriggerEvent("onClientGTMLElementTextureUpdate",element,texture)
                    end))
                end
                return element
            end
        end
    end
end

function CreateRenderer()
    local resource = getResourceName(getThisResource())
    if resource then 
        return [[return function(element)
            local GTML = exports["]] + resource + [["]
            if type(GTML) == "table" then
                if type(_G["GTML_STORE"]) ~= "table" then
                    _G["GTML_STORE"] = {

                    }
                end
                addEventHandler("RequestForLoadCode",resourceRoot,function(code)
                    if type(code) == "string" then 
                        loadstring(code)()
                    end
                end)
                if GTML:IsElement(element) then  
                    local texture = nil
                    local document = GTML:GetElementDocument(element)
                    print("document is:",document)
                    if GTML:IsElement(document) then
                        texture = GTML:GetElementTexture(document)
                    end
                    if not isElement(texture) then 
                        texture = GTML:GetElementTexture(element)
                    end
                    if isElement(texture) then                        
                    end
                end
            end
        end]]
    end
end

function SetElementTexture(element,texture)
    if IsElement(element) and isElement(texture) then 
        local last = GetElementTexture(element)
        if last ~= texture then 
            SetElementData(element,"texture",texture)
            TriggerEvent("onClientGTMLElementTextureChange",element,last,texture)
        end
    end
end

function GetElementTexture(element)
    if IsElement(element) then 
        return GetElementData(element,"texture")
    end
end

function CreateElement(tp,parent)
    if type(tp) == "string" then 
        local element = createElement(CreateElementName(tp))
        if IsElement(element) then 
            SetElementData(element,"children",{})
            SetElementData(element,"style",{})
            SetElementData(element,"parent",false)
            SetElementData(element,"document",false)
            SetElementData(element,"remoteMode",false)
            SetElementData(element,"fetchs",{})
            SetElementData(element,"classes",{})
            SetElementData(element,"id",false)
            SetElementData(element,"attributes",{})
            SetElementData(element,"display","none")
            SetElementData(element,"texture",false)
            SetElementData(element,"resource",getThisResource())
            if IsElement(parent) then
                AppendChild(parent,element)
                if IsElementLinkTo(element,GetDocumentBody(GetElementDocument(element))) then
                    SetElementDisplayMode(element,"block")
                end
            end
            return element
        end
    end
end

function GetElementsByType(tp,resource)
    if type(tp) == "string" and type(resource) == "userdata" then 
        local elements = getElementsByType(CreateElementName(tp),getResourceRootElement(resource))
        if type(elements) == "table" then 
            return elements
        end
    end
end

function SetElementResource(element,resource)
    if IsElement(element) and type(resource) == "userdata" then 
        local last = GetElementResource(element)
        if last ~= resource then 
            SetElementData(element,"resource",resource)
            TriggerEvent("onClientGTMLElementResourceChange",element,last,resource)
        end
    end
end

function GetElementResource(element)
    if IsElement(element) then 
        return GetElementData(element,"resource")
    end
end

function SetElementDisplayMode(element,mode)
    if IsElement(element) and type(mode) == "string" then 
        local last = GetElementDisplayMode(element)
        if last ~= mode then 
            SetElementData(element,"display",mode)
            TriggerEvent("onClientGTMLElementDisplayModeChange",element,last,mode)
        end
    end
end

function GetElementDisplayMode(element)
    if IsElement(element) then 
        return GetElementData(element,"display")
    end
end

function GetDocumentHead(document)
    if GetElementType(document) == "document" then
        return QuerySelector(document,"head")
    end
end

function GetDocumentBody(document)
    if GetElementType(document) == "document" then 
        return QuerySelector(document,"body")
    end
end

function DetachElement(element)
    if IsElement(element) then
        local parent = GetElementParent(element)
        if IsElement(parent) then 
            return DetachChild(parent,element)
        end
    end
    return false
end

function DetachChild(parent,child)
    if IsElement(parent) and IsElement(child) then 
        local children = GetElementChildren(parent)
        if type(children) == "table" then
            SetElementData(parent,"children",table.filter(children,function(_,c)
                return c == child and EMPTY() or c
            end,true))
            if GetElementType(parent) == "document" then 
                SetElementData(child,"document",false)
            end
            SetElementData(child,"parent",false)
            SetElementData(child,"remoteMode",false)
            return true
        end
    end
    return false
end

function AppendChild(parent,child)
    if IsElement(parent) and IsElement(child) then
        if not ElementHasChild(parent,child) then
            local children = GetElementChildren(parent)
            if type(children) == "table" then
                DetachElement(child)
                SetElementData(child,"parent",parent)
                SetElementData(child,"remoteMode",GetElementRemoteMode(parent))
                if GetElementType(parent) == "document" then
                    SetElementData(child,"document",parent)
                end
                SetElementResource(child,GetElementResource(child))
                table.insert(children,child)
                return true
            end
        end
    end
    return false
end

function QuerySelector(element,query)
    if IsElement(element) and type(query) == "string" then 
        local children = QuerySelectorAll(element,query)
        if type(children) == "table" and #children > 0 then
            return children[#children]
        end
    end
end

function QuerySelectorAll(element,query)
    if IsElement(element) and type(query) == "string" then 
        if #query > 0 then
            local children = GetElementChildren(element)
            if type(children) == "table" and #children > 0 then 
                local sep = query/","
                if type(sep) == "table" and #sep > 0 then 
                    local queries = {}
                    for i,qu in ipairs(sep) do
                        if #qu > 0 then
                            qu = ReadStream(qu,function(byte,i)
                                if byte == ">" or byte == " " then
                                    local next = qu[i + 1]
                                    if next then
                                        if next == " " or next == ">" or next == "#" or next == "." or byte == ":" then
                                            return nil
                                        else
                                            return " "
                                        end
                                    else
                                        return nil
                                    end
                                end
                                return byte
                            end)
                            local e
                            e,qu = ReadStream(qu,function(byte,i)
                                return byte ~= " " and BreakStream() or byte
                            end)
                            local j = #qu
                            while j > 0 do
                                if qu[j] ~= " " then
                                    qu = qu[":" + j]
                                    break
                                end
                                j = j - 1
                            end
                            if #qu > 0 then 
                                local q = {}
                                if qu%"." or qu%"#" then
                                    local last = 0
                                    ReadStream(qu,function(byte,i)
                                        if byte == "." or byte == "#" or byte == ":" or byte == " " then
                                            local chunk = qu[last + ":" + (i - 1)]
                                            if chunk and #chunk > 0 then 
                                                table.insert(q,chunk)
                                            end
                                            last = i
                                        end
                                        return ""
                                    end)
                                    table.insert(q,qu[(last + (qu[last] == " " and 1 or 0)) + ":"])
                                else
                                    table.insert(q,qu)
                                end
                                if #q > 0 then 
                                    table.insert(queries,q)
                                end
                            end
                        end
                    end
                    if #queries > 0 then 
                        local selected = {}
                        for i,feature in ipairs(queries) do 
                            local children = GetElementChildrenByFeature(element,feature)
                            if type(children) == "table" and #children > 0 then 
                                for _,child in ipairs(children) do
                                    if not table.find(selected,child) then
                                        table.insert(selected,child)
                                    end
                                end
                            end
                        end
                        return selected
                    end
                end
            end
            return {}
        end
    end
end

function GetElementChildrenByFeature(element,feature)
    if IsElement(element) and type(feature) == "table" and #feature > 0 then 
        local children = GetElementAllChildren(element)
        if type(children) == "table" and #children > 0 then
            local selected = {}
            if #feature > 1 then
                local parents = {}
                for i,f in ipairs(feature) do 
                    if i < #feature then
                        local elements = GetElementList(children,f)
                        if type(elements) == "table" and #elements > 0 then 
                            for _,e in ipairs(elements) do 
                                table.insert(parents,{i,e})
                            end
                        end
                    end
                end
                if #parents > 0 then
                    local linked = table.filter(parents,function(_,v)
                        return v[1] == parents[#parents][1] and v[2] or nil
                    end,true)
                    local elements = {}
                    for i,parent in ipairs(linked) do 
                        local success = true
                        local length = parents[#parents][1] - 1
                        repeat
                            for i,p in ipairs(table.filter(parents,function(_,v)
                                if v[1] == length then
                                    return v[2]
                                end
                            end,true)) do
                                if not IsElementLinkTo(parent,p) then
                                    success = false
                                end
                            end
                            length = length - 1
                        until length < 1
                        if success then
                            table.insert(elements,parent)
                        end
                    end
                    if #elements > 0 then 
                        for i,parent in ipairs(elements) do
                            local list = GetElementList(GetElementAllChildren(parent),feature[#feature])
                            if type(list) == "table" and #list > 0 then 
                                for i,element in ipairs(list) do 
                                    table.insert(selected,element)
                                end
                            end
                        end
                    end
                end
            else
                selected = GetElementList(children,feature[#feature])
            end
            if type(selected) == "table" then
                return selected
            end
        end
    end
end

function IsElementLinkTo(element,parent)
    if IsElement(element) and IsElement(parent) then 
        local children = GetElementAllChildren(parent)
        if type(children) == "table" and #children > 0 then 
            for i,child in ipairs(children) do 
                if child == element then 
                    return true
                end
            end
        end
    end
    return false
end

function GetElementAllChildren(element)
    if IsElement(element) then 
        local children = GetElementChildren(element)
        if type(children) == "table" and #children > 0 then 
            local result = {}
            for i,child in ipairs(children) do 
                table.insert(result,child)
                local chren = GetElementAllChildren(child)
                if type(chren) == "table" and #chren > 0 then 
                    for _,c in ipairs(chren) do 
                        table.insert(result,c)
                    end
                end
            end
            return result
        end
    end
end

function GetElementList(children,feature)
    if type(children) == "table" and type(feature) == "string" then 
        local list = {}
        local searchType = "type"
        if feature[">>."] then 
            searchType = "class"
            feature = feature[2 + ":"]
        elseif feature[">>#"] then 
            searchType = "id"
            feature = feature[2 + ":"]
        end
        for i,child in ipairs(children) do 
            if (
                (searchType == "id" and GetElementID(child) == feature) or
                (searchType == "class" and ElementClassExists(child,feature)) or 
                (searchType == "type" and GetElementType(child) == feature)
            ) then
                table.insert(list,child)
            end
        end
        return list
    end
end

function SetElementAttribute(element,attribute,value)
    if IsElement(element) and type(attribute) == "string" then 
        if #attribute > 0 then
            local last = GetElementAttribute(element,attribute)
            if last ~= value then 
                local attributes = GetElementAttributes(element)
                if type(attributes) == "table" then 
                    attributes[attribute] = value
                    TriggerEvent("onClientGTMLElementAttributeChange",element,attribute,last,value)
                end
            end
        end
    end
end

function GetElementAttribute(element,attribute)
    if IsElement(element) and type(attribute) == "string" then
        if #attribute > 0 then  
            local attributes = GetElementAttributes(element)
            if type(attributes) == "table" then 
                return attributes[attribute]
            end
        end
    end
end

function GetElementAttributes(element)
    if IsElement(element) then 
        return GetElementData(element,"attributes")
    end
end

function AddElementClass(element,class)
    if IsElement(element) and type(class) == "string" and #class > 0 then
        if not ElementClassExists(element,class) then 
            local list = GetElementClassList(element)
            if type(list) == "table" then 
                table.insert(list,class)
                TriggerEvent("onClientGTMLElementClassAdd",element,class)
            end
        end
    end
end

function RemoveElementClass(element,class)
    if IsElement(element) and type(class) == "string" and #class > 0 then
        if ElementClassExists(element,class) then
            local list = GetElementClassList(element)
            if type(list) == "table" then 
                for index,c in ipairs(list) do
                    if c == class then 
                        table.remove(list,index)
                        TriggerEvent("onClientGTMLElementClassRemove",element,class)
                        break
                    end
                end
            end
        end 
    end
end

function SetElementClass(element,class)
    if IsElement(element) and type(class) == "string" and #class > 0 then 
        local list = {}
        if class%" " or class%"," then
            local last = 0
            ReadStream(class,function(byte,i)
                if byte == " " or byte == "," then
                    local chunk = class[(last + (#list > 0 and 1 or 0)) + ":" + (i - 1)]
                    if chunk and #chunk > 0 then
                        table.insert(list,chunk)
                    end
                    last = i
                end
                return ""
            end)
            local cls = ReadStream(class[(last + 1) + ":"],function(byte)
                return byte ~= " " and byte or nil
            end)
            if #cls > 0 then 
                table.insert(list,cls)
            end
        else
            table.insert(list,class)
        end
        for i,c in ipairs(list) do 
            AddElementClass(element,c)
        end
    end
end

function SetElementClassList(element,classes)
    if IsElement(element) and type(classes) == "table" then
        local last = GetElementClassList(element)
        if type(last) == "table" and last ~= classes then  
            SetElementData(element,"classes",classes)
            TriggerEvent("onClientGTMLElementClassListChange",element,last,classes)
        end
    end
end

function ElementClassExists(element,class)
    if IsElement(element) and type(class) == "string" and #class > 0 then 
        local classes = GetElementClassList(element)
        if type(classes) == "table" then 
            for i,c in ipairs(classes) do 
                if c == class then 
                    return true
                end
            end
        end
    end
    return false
end

function GetElementClassList(element)
    if IsElement(element) then
        return GetElementData(element,"classes")
    end
end

function SetElementID(element,id)
    if IsElement(element) and type(id) == "string" and #id > 0 then
        local last = GetElementID(element)
        if last ~= id then  
            SetElementData(element,"id",id)
            TriggerEvent("onClientGTMLElementIDChange",element,last,id)
        end
    end
end

function GetElementID(element)
    if IsElement(element) then 
        return GetElementData(element,"id")
    end
end

function ElementHasChild(parent,child)
    if IsElement(parent) and IsElement(child) then 
        return GetElementParent(child) == parent
    end
    return false
end

function GetElementParent(element)
    if IsElement(element) then 
        return GetElementData(element,"parent")
    end
end

function GetElementChildren(element)
    if IsElement(element) then 
        return GetElementData(element,"children")
    end
end

function GetElementDocument(element)
    if IsElement(element) then 
        local document = GetElementData(element,"document")
        if IsElement(document) then 
            return document
        end
        local parent = GetElementData(element,"parent")
        if IsElement(parent) then 
            return GetElementDocument(element)
        end
    end
end

function GetElementType(element)
    if IsElement(element) then 
        return getElementType(element)[(#"GTML-" + 1) + ":"]
    end
end

function IsElement(element)
    if isElement(element) then 
        if getElementType(element)[">>GTML-"] then 
            return true
        end
    end
    return false
end

function CreateElementName(tp)
    if type(tp) == "string" then 
        return "GTML-" + tp
    end
end

function SetElementRemoteMode(element,mode)
    if IsElement(element) and type(mode) == "string" then
        if mode == "server" or mode == "client" then 
            SetElementData(element,"remoteMode",mode)
            return true
        end
    end
    return false
end

function GetElementRemoteMode(element)
    if IsElement(element) then 
        return GetElementData(element,"remoteMode")
    end
end

function GetElementFetchRemotes(element)
    if IsElement(element) then 
        return GetElementData(element,"fetchs")
    end
end

function GetElementFetchRemote(element,key)
    if IsElement(element) and type(key) == "string" then
        local remotes = GetElementFetchRemotes(element)
        if type(remotes) == "table" then 
            return remotes[key]
        end
    end
end

function RemoveElementFetchRemote(element,key,ns)
    if IsElement(element) and type(key) == "string" then 
        local remotes = GetElementFetchRemotes(element)
        if type(remotes) == "table" then
            if type(remotes[key]) == "table" then
                if not remotes[key].done then
                    if remotes[key].mode == "client" and remotes[key].material then 
                        abortRemoteRequest(remotes[key].material)
                    else
                        if not ns then 
                            triggerServerEvent("GTML:RemoveFetchRemote",getLocalPlayer(),tostring(element),key)
                        end
                    end
                end
                if type(OpenReqeusts[element]) == "table" then
                    for i,req in ipairs(OpenReqeusts[element]) do 
                        if req.key == key then
                            table.remove(OpenReqeusts[element],i)
                            break
                        end
                    end
                    if #OpenReqeusts[element] < 1 then
                        OpenReqeusts[element] = nil
                    end
                end
                remotes[key] = nil
                collectgarbage("collect")
                return true
            end
        end
    end
    return false
end

function Fetch(element,data)
    if IsElement(element) and type(data) == "table" then 
        local mode = GetElementRemoteMode(element)
        mode = type(mode) == "string" and mode or DEFAULT_REMOTE_MODE
        if type(data.mode) and (data.mode == "client" or data.mode == "server") then 
            mode = data.mode
        end
        if mode then
            local url = type(data.url) == "string" and data.url["\\<</"]
            if url and url%[[://]] then
                local key = randomKey(15)
                while type(GetElementFetchRemote(element,key)) == "table" do 
                    key = randomKey(15)
                end
                if type(key) == "string" then 
                    local options = {
                        method = "GET",
                        connectionAttempts = 1,
                        connectTimeout = 5000,
                        queueName = key,
                        headers = {}
                    }
                    local bandWidth = {
                        IN = 5000,
                        OUT = 5000
                    }
                    local update = tonumber(data.update) or 1
                    if type(data.bandWidth) == "table" then 
                        for k,v in pairs(data.bandWidth) do 
                            v = tonumber(v)
                            if v then
                                bandWidth[k] = v
                            end
                        end
                    end
                    if type(data.options) == "table" then 
                        for k,v in pairs(data.options) do
                            options[k] = v
                        end
                    end
                    local form = nil 
                    if type(data.data) == "table" then 
                        form = toJSON(data.data,true,"none")
                        form = form["2:" + (#form - 1)]
                    end
                    if type(form) == "string" and #form > 0 then 
                        options.postData = form
                        options.headers["Content-Type"] = "application/json"
                        if type(data.options) == "table" then 
                            if type(data.options.postData) == "string" then 
                                options.postData = data.options.postData
                            end
                            if type(data.options.headers) == "table" and type(data.options.headers["Content-Type"]) == "string" then 
                                options.headers["Content-Type"] = data.options.headers["Content-Type"]
                            end
                        end
                    end
                    local remote = {
                        options = options,
                        key = key,
                        done = false,
                        mode = mode
                    }
                    if mode == "server" then
                        local remotes = GetElementFetchRemotes(element)
                        if type(remotes) == "table" then
                            remotes[key] = remote
                            triggerLatentServerEvent("GTML:FetchRemote",bandWidth.IN,getLocalPlayer(),tostring(element),key,url,options,bandWidth.OUT,update)
                            if type(OpenReqeusts[element]) ~= "table" then
                                OpenReqeusts[element] = {}
                            end
                            table.insert(OpenReqeusts[element],remote)
                        end
                    elseif mode == "client" then
                        local _,_,host = UnpackURL(url)
                        local function send(accepted)
                            local datas = {}
                            if accepted then
                                local remotes = GetElementFetchRemotes(element)
                                if type(remotes) == "table" then
                                    remotes[key] = remote
                                    remote.material = fetchRemote(url,options,function(b,info)
                                        datas.buffer = b
                                        datas.info = info
                                        remote.done = true
                                        TriggerEvent("onClientGTMLElementRemoteCallback",element,key,datas)
                                        RemoveElementFetchRemote(element,key)
                                    end)
                                else
                                    datas.error = "Element '" + element + "' doesn't store the remote!"
                                end
                            else
                                datas.error = "User didn't accept domain '" + url + "'!"
                            end
                            if datas.error then
                                TriggerEvent("onClientGTMLElementRemoteCallback",element,key,datas)
                                RemoveElementFetchRemote(element,key)
                            end
                        end
                        if data.passRequestDomain then
                            send(true)
                        else
                            requestDomains({host},data.force,send)
                        end
                    end
                    return key
                end
            end
        end
    end
end

function FetchAsync(element,data)
    if IsElement(element) and type(data) == "table" then 
        local key = Fetch(element,data)
        if type(key) == "string" then 
            return [[return Promise(function(resolve)
                local function callback(key,...)
                    if key == "]] + key + [[" then
                        removeEventHandler("onClientGTMLElementRemoteCallback",getRootElement(),callback)
                        resolve(...)
                    end
                end
                addEventHandler("onClientGTMLElementRemoteCallback",getRootElement(),callback)
            end)]]
        end
    end
end

function requestDomains(domains,force,callback)
    if type(domains) == "table" then
        return requestBrowserDomains(domains,false,function(accepted)
            if force then
                if accepted then 
                    callback(accepted)
                else
                    requestDomains(domains,force,callback)
                end
            else
                callback(accepted)
            end
        end)
    end
end

function readFile(path)
    if type(path) == "string" then 
        if fileExists(path) then
            local file = fileOpen(path)
            if file then
                local data = fileRead(file,fileGetSize(file))
                fileClose(file)
                if type(data) == "string" then 
                    return data
                end
            end
        end
    end
end

function TriggerEvent(name,element,...)
    if type(name) == "string" and isElement(element) then 
        triggerEvent(name,element,...)
    end
end