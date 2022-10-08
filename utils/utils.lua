struct "EMPTY"{}

math.NaN = 0/0

function UnpackURL(url)
    if type(url) == "string" then 
        local protocol = ReadStream(url,function(byte)
            return byte == ":" and BreakStream() or byte
        end)
        local second = url[(#protocol + 1) + ":"]
        if second%"//" then
            local _
            _,second = ReadStream(second,function(byte)
                return (byte == ":" or byte == "/") and byte or BreakStream()
            end)
            local host = ReadStream(second,function(byte)
                return byte == "/" and BreakStream() or byte
            end)
            local ip,port = ReadStream(host,function(byte)
                return byte == ":" and BreakStream() or byte
            end)
            if port then 
                port = tonumber(port[2 + ":"])
            end
            local location,argsString = ReadStream(second[(#host + 1) + ":"],function(byte)
                return byte == "?" and BreakStream() or byte
            end)
            if argsString then
                argsString = argsString[2 + ":"]
            end
            local args = UnpackQueryArgs(argsString)
            return protocol,host,ip,port,location,args,argsString,second
        end
    end
end

function CreateQueryArgs(data)
    if type(data) == "table" then
        local str = ""
        for index,value in pairs(data) do 
            str = str + index + "=" + value + "&"
        end
        str = str - (#str + 1)
        return str
    end
end

function UnpackQueryArgs(query)
    if type(query) == "string" then
        local result = {}
        local spl = query/"&"
        if type(spl) == "table" and #spl > 0 then
            for i,arg in pairs(spl) do 
                if #arg < 1 then
                    table.remove(spl,i)
                end
            end
            for i,arg in pairs(spl) do 
                local index,value = unpack(arg/"=")
                if type(index) == "string" and #index > 0 then 
                    if not value or (type(value) == "string" and #value < 1) then
                        value = ""
                    end
                    result[index] = value
                end
            end
            return result
        end
    end
end

function randomKey(amount)
    amount = tonumber(amount) or 8
    if amount then 
        local chars = "qwertyuiopasdfghjklzxcvbnm1234567890!@#$%^&*()_+-=`~[]{};:'\",<>./?\\|QWERTYUIOPASDFGHJKLZXCVBNM"
        local key = ""
        for i = 1,amount do 
            key = key + chars[math.random(1,#chars)]
        end
        return key
    end
end

function table.filter(tbl,func,i)
    if type(tbl) == "table" and type(func) == "function" then 
        local result = {}
        for k,v in (i and ipairs or pairs)(tbl) do 
            local value = func(k,v)
            if not instanceof(value,EMPTY) then
                if i then 
                    table.insert(result,value)
                else
                    result[k] = value
                end
            end
        end
        return result
    end
end

function table.length(tbl)
    if type(tbl) == "table" then 
        local len = 0
        for _ in pairs(tbl) do 
            len = len + 1
        end
        return len
    end
end

function table.find(tbl,value)
    if type(tbl) == "table" then 
        for k,v in pairs(tbl) do 
            if v == value then 
                return k
            end
        end
    end
    return false
end

function isNaN(number)
    number = tonumber(number)
    if number then 
        if tostring(number)%"nan" then 
            return true
        end
    end
    return false
end