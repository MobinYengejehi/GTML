BreakStream = struct{}

function ReadStream(buffer,reader,additional)
    if type(buffer) == "string" and type(reader) == "function" then
        local result = ""
        local last = 0
        additional = tonumber(additional) or 0
        for i = 1,#buffer,math.max(additional,1) + (additional > 1 and 1 or 0) do
            local e = i + (additional > 1 and additional or 0)
            local chunk = reader(buffer[i + ":" + e],i,e)
            if instanceof(chunk,BreakStream) then
                last = i 
                break
            elseif type(chunk) == "string" then
                result = result + chunk
            end
        end
        return result,last > 0 and buffer[last + ":"] or nil
    end
end