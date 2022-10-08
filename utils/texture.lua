class "PixelBox"{
    public = {
        PixelBox = function(self,name,parent)
            self.name = type(name) == "string" and name or ""
            self.attributes = {}
            self.children = {}
            self.xmlNode = nil
            if instanceof(parent,PixelBox) then
                parent:AppendChild(self)
            end
            self.onChange = function() end
        end,
        AppendChild = function(self,child,create)
            if type(self.children) == "table" then 
                if instanceof(child,PixelBox) then 
                    if not table.find(self.children,child) then
                        if self.xmlNode and not create then
                            if not child.xmlNode and #child.name > 0 then
                                child.xmlNode = xmlCreateChild(self.xmlNode,child.name)
                            end
                        end
                        child.parent = self
                        table.insert(self.children,child)
                    end
                end
            end
        end,
        DetachChild = function(self,child)
            if type(self.children) == "table" and #self.children > 0 then 
                if instanceof(child,PixelBox) then 
                    local index = table.find(self.children,child)
                    if index then 
                        child.parent = nil
                        table.remove(self.children,index)
                    end
                end
            end
        end,
        SetName = function(self,name)
            if type(name) == "string" then
                if name ~= self:GetName() then 
                    self.name = name
                end
            end
        end,
        GetName = function(self)
            return self.name
        end,
        SetAttributes = function(self,attributes) 
            if type(attributes) == "table" then 
                for attribute,value in pairs(attributes) do 
                    self:SetAttribute(attribute,value)
                end
            end
        end,
        SetAttribute = function(self,attribute,value)
            if type(self.attributes) == "table" and type(attribute) == "string" and value ~= nil then
                local last = self:GetAttribute(attribute)
                if last ~= value then  
                    self.attributes[attribute] = value
                    if self.xmlNode then 
                        xmlNodeSetAttribute(self.xmlNode,attribute,value)
                    end
                    if type(self.onChange) == "function" then 
                        self:onChange(attribute,last,value)
                    end
                end
            end
        end,
        GetAttribute = function(self,attribute)
            if type(attribute) == "string" then 
                return self.attributes[attribute]
            end
        end,
        Destroy = function(self)
            if self.xmlNode then 
                local dst = xmlDestroyNode(self.xmlNode)
                if instanceof(self.parent,PixelBox) then 
                    self.parent:DetachChild(self)
                end
            end
        end,
        IsLinkTo = function(self,parent)
            if instanceof(parent,PixelBox) and instanceof(self.parent,PixelBox) then 
                if self.parent == parent then
                    return true
                else
                    return self.parent:IsLinkTo(parent)
                end
            end
            return false
        end,
        GetChildByID = function(self,id)
            if type(id) == "string" and type(self.children) == "table" and #self.children > 0 then 
                for i,child in ipairs(self.children) do 
                    if child:GetAttribute("id") == id then 
                        return child
                    end
                end
            end
        end,
        GetElementsByType = function(self,tp)
            if type(tp) == "string" and type(self.children) == "table" and #self.children > 0 then
                return table.filter(self.children,function(i,v)
                    if v.name == tp then 
                        return v
                    end
                end)
            end 
        end,
        GetChildren = function(self)
            return table.filter(self.children,function(i,v)
                if v:GetAttribute("id") ~= "FIX_UPDATE" and v:GetAttribute("FIX_DESTROY") then
                    return v
                end
            end,true)
        end
    }
}

function CreateTexture(width,height,callback)
    width = tonumber(width) or 1
    height = tonumber(height) or 1
    if width and height then
        local texture = svgCreate(width,height,'<svg width="' + width + '" height="' + height + '" viewBox="0 0 ' + width + ' ' + height + '" ><rect id="FIX_UPDATE" x="0" y="0" width="1" height="1" fill="none" /></svg>')
        if isElement(texture) then
            if type(callback) == "function" then
                svgSetUpdateCallback(texture,callback)
            end
            return texture
        end
    end
end

function UpdateTexturePixels(texture,pixels)
    if isElement(texture) and instanceof(pixels,PixelBox) then
        if pixels.xmlNode then 
            if #pixels.children < 1 then 
                local d = PixelBox("rect",pixels)
                d:SetAttributes{
                    x = "0",
                    y = "0",
                    width = "1",
                    height = "1",
                    fill = "rgba(0,0,0,0)",
                    id = "FIX_DESTROY"
                }
            end
            svgSetDocumentXML(texture,pixels.xmlNode)
            xmlUnloadFile(pixels.xmlNode)
        end
    end
end

function GetTexturePixels(texture)
    if isElement(texture) then 
        local document = svgGetDocumentXML(texture)
        if document then
            local children = GetXMLNodeChildren(document)
            if type(children) == "table" then 
                local doc = PixelBox("document")
                doc.xmlNode = document
                CreateTextureChildren(doc,children)
                return doc
            end
        end
    end
end

function CreateTextureChildren(document,children)
    if instanceof(document,PixelBox) and type(children) == "table" and #children > 0 then 
        for i,child in ipairs(children) do 
            if type(child.name) == "string" then 
                local box = PixelBox(child.name)
                box.xmlNode = child.node
                if not table.find(document.children,box) then
                    box.parent = document
                    table.insert(document.children,box)
                end
                box:SetAttributes(child.attributes)
                CreateTextureChildren(box,child.children)
            end
        end
    end
end

function GetTextureSize(texture)
    if isElement(texture) then 
        return dxGetMaterialSize(texture)
    end
end

function SetTextureSize(texture,width,height)
    if isElement(texture) then 
        width = tonumber(width)
        height = tonumber(height)
        if width and height then 
            local lw,lh = GetTextureSize(texture)
            if width ~= lw or height ~= lh then 
                svgSetSize(texture,width,height)
            end
        end
    end
end

-- local texture

-- setTimer(function()
--     texture = CreateTexture(400,180)
--     local pixels = GetTexturePixels(texture)
--     -- local g = PixelBox("g",pixels)
--     -- g:SetAttribute("id","dd")
--     -- local rect = PixelBox("rect",g)
--     -- rect:SetAttributes{
--     --     x = "50",
--     --     y = "0",
--     --     width = "50%",
--     --     height = "100%",
--     --     fill = "#ff0000"
--     -- }
--     -- local animate = PixelBox("animate",rect)
--     -- animate:SetAttributes{
--     --     attributeName="rx",
--     --     values="0;20;0",
--     --     dur="10s",
--     --     repeatCount="indefinite"
--     -- }
--     -- local div = PixelBox("g",pixels)
--     -- div:SetAttributes{
--     --     fill = "white",
--     --     stroke = "#ff0000",
--     --     ["stroke-width"] = "10"
--     -- }
--     -- local circle = PixelBox("circle",div)
--     -- circle:SetAttributes{
--     --     cx = "50",
--     --     cy = "50",
--     --     r = "20",
--     --     stroke = "green"
--     -- }
--     -- local mask = PixelBox("mask",pixels)
--     -- mask:SetAttribute("id","myMask")
--     -- local rect = PixelBox("rect",mask)
--     -- rect:SetAttributes{
--     --     x = "0",
--     --     y = "0",
--     --     width = "100",
--     --     height = "100",
--     --     fill = "white"
--     -- }
--     -- local circle = PixelBox("circle",mask)
--     -- circle:SetAttributes{
--     --     cx = "30",
--     --     cy = "30",
--     --     r = "20",
--     --     -- mask = "url(#myMask)",
--     --     fill = "black"
--     -- }
--     -- local path = PixelBox("path",pixels)
--     -- path:SetAttributes{
--     --     d = "M10,35 A20,20,0,0,1,50,35 A20,20,0,0,1,90,35 Q90,65,50,95 Q10,65,10,35 Z",
--     --     fill = "green",
--     --     mask = "url(#myMask)"
--     -- }
--     -- rect = PixelBox("rect",pixels)
--     -- rect:SetAttributes{
--     --     x = "0",
--     --     y = "0",
--     --     width = "50",
--     --     height = "50",
--     --     fill = "green",
--     --     mask = "url(#myMask)"
--     -- }
--     UpdateTexturePixels(texture,pixels)
--     setTimer(function()
--         local pixels = GetTexturePixels(texture)
--         iprint(#pixels:GetElementsByType("g"))
--     end,1000,1)
-- end,1000,1)

-- addEventHandler("onClientRender",getRootElement(),function()
--     if texture then
--         dxDrawImage(200,200,400,180,texture)
--     end
-- end)