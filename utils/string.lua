local metatable = getmetatable[[]]

local find = string.find

function metatable.__index(self,key)
    if type(key) == "number" then 
        if #self > 0 then
            return (key > #self or key < 1) and nil or self:sub(key,key) 
        end
    elseif type(key) == "string" then
        local pos,e = find(key,">>")
        if pos == 1 then
            local str = key:sub(#">>" + 1,#key)
            if #str > 1 then 
                return find(self,str) == 1
            elseif #str == 1 then
                return self:sub(1,1) == str
            end
        end
        local pos,e = find(key,"array")
        if pos == 1 then 
            local args = {}
            local result = {}
            local lastChar = key:sub(#key,#key)
            local openBracket = find(key,"{")
            if openBracket then 
                local closeBracket = find(key,"}")
                if closeBracket then 
                    args = split(key:sub(openBracket + 1,closeBracket - 1),",")
                end
            end
            if type(args) == "table" and #args > 0 then 
                local Args = {}
                local len = #self
                for i,pos in ipairs(args) do
                    local t = pos:sub(#pos,#pos) 
                    local n = tonumber(pos:sub(1,#pos - ((t == "!" or t == "@") and 1 or 0)))
                    if n and n < len then
                        table.insert(Args,{
                            pos = n,
                            type = (t == "!" and 2) or (t == "@" and 3) or 1
                        })
                    end
                end
                local last = {
                    pos = 1,
                    type = 1
                }
                for i,data in pairs(Args) do 
                    if data.type == 3 then 
                        table.insert(result,self:sub(
                            (last.type == 1 or last.type == 2) and last.pos + 1 or last.pos,
                            data.pos - 1
                        ))
                    elseif data.type == 2 then 
                        table.insert(result,self:sub(i > 1 and last.pos + 1 or last.pos,data.pos))
                    elseif data.type == 1 then 
                        table.insert(result,self:sub(
                            i > 1 and (last.type == 3 and last.pos - 1) or last.pos,
                            data.pos - 1
                        ))
                    end
                    last.pos = data.pos
                    last.type = data.type
                end
                table.insert(
                    result,
                    (last.type == 3 and self:sub(last.pos,#self)) or
                    (last.type == 2 and self:sub(last.pos + 1,#self)) or 
                    self:sub(last.pos + 1,#self + 1)
                )
            else
                for i = 1,#self do 
                    table.insert(result,self:sub(i,i))
                end
            end
            return result
        end
        local pos = find(key,":")
        if pos then 
            local start = tonumber(key:sub(1,pos - 1)) or 1
            local endd = tonumber(key:sub(pos + 1,#key)) or #self
            if start or endd then 
                return self:sub(start,endd)
            end
        end
        local pos,e = find(key,"<<")
        if pos and e then 
            local start = key:sub(1,pos - 1)
            local endd = key:sub(e + 1,#key)
            if type(start) == "string" and type(endd) == "string" then
                return self:gsub(start,endd)
            end
        end
    end
    return rawget(string,key)
end

function metatable.__add(self,value)
    local result = self
    if type(value) == "table" then 
        for i,v in ipairs(value) do 
            result = result .. tostring(v)
        end
    else
        result = result .. tostring(value)
    end
    return result
end

function metatable.__mod(self,value)
    return self:find(tostring(value))
end

function metatable.__div(self,sep)
    if type(sep) == "string" then
        local result = {}
        local seprator = "(.-)" + sep
        local last = 1
        local s,e,cap = self:find(seprator,1)
        while s do 
            if s ~= 1 or cap ~= "" then 
                table.insert(result,cap)
            end
            last = e + 1
            s,e,cap = self:find(seprator,last)
        end
        if last <= #self then
            cap = self[last + ":"]
            table.insert(result,cap)
        end
        return result
    end
end

function metatable.__mul(self,value)
    value = tonumber(value)
    return value and self:rep(value)
end

function metatable.__pow(self,value)
    value = tonumber(value)
    return value and (
        value <= 1 and self:lower() or self:upper()
    ) or self:lower()
end

function metatable.__sub(self,value)
    local result = ""
    if type(value) == "number" then 
        local sub = #self - value
        result = self[sub <= 0 and "1:" + (#self - (-sub)) or (value + 1) + ":" + #self]
    elseif type(value) == "string" then
        local devided = self/value
        if type(devided) == "table" and #devided > 0 then
            for i,str in pairs(devided) do
                result = result + str
            end
        end
    elseif type(value) == "table" then
        result = self
        for i,str in ipairs(value) do
            if type(str) == "string" then 
                result = result - str
            end
        end
    end
    return result
end