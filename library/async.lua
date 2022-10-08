function Promise(func)
    if type(func) == 'function' then 
        return coroutine.create(func)
    end
end 

function async(func)
    if type(func) == 'function' then 
        return function(...)
            local promise = Promise(function(resolve,...)
                resolve(func(...))
            end)
            local resolver = function() end
            local result = {(function(...)
                local result = {}
                coroutine.resume(promise,function(...)
                    result = {...}
                    resolver(...)
                end,...)
                return unpack(result)
            end)(...)}
            if #result == 0 then 
                return Promise(function(resolve)
                    resolver = resolve
                end)
            end
            return unpack(result)
        end
    end
end

function await(...)
    local args = {...}
    local promise = args[1]
    table.remove(args,1)
    if type(promise) == 'thread' then
        local thread,result = coroutine.running(),{}
        if type(thread) == 'thread' then 
            local suspended = coroutine.status(promise) == 'suspended'
            if not suspended then 
                return
            end
            coroutine.resume(promise,function(...)
                result = {...}
                if coroutine.status(thread) == 'suspended' then
                    coroutine.resume(thread)
                end
                suspended = false
            end,...)
            if suspended then 
                coroutine.yield()
            end
            return unpack(result)
        end
    elseif type(promise) == 'string' then 
        return await(loadstring(promise)(),unpack(args))
    else
        return promise,unpack(args)
    end
end