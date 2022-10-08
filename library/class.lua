CLASSFUNCTIONS = {
    getPrivate = [==[function(self,index)
        if type(index) == 'string' then
            return self[tostring(self) .. ':private:value:' .. index]
        end
        return nil
    end]==],
    setPrivate = [==[function(self,index,value)
        if type(index) == 'string' then 
            self[tostring(self) .. ':private:value:' .. index] = value
            return self[tostring(self) .. ':private:value:' .. index]
        end
        return false
    end]==],
    getPublic = [==[function(self,index)
        if type(index) == 'string' then
            return self[index]
        end
    end]==],
    setPublic = [==[function(self,index,value)
        if type(index) == 'string' then 
            self[index] = value
            return self[index]   
        end
        return false
    end]==],
    getClassElements = [==[function(self)
        if CLASSELEMENTS[self.__name] then 
            return CLASSELEMENTS[self.__name]
        end
        return false
    end]==],
    destroyClassElement = [==[function(self) 
        local id = tonumber(self:getPrivate('CLASS_ELEMENT_ID'))
        if id then
            table(CLASSELEMENTS[self.__name]):remove(self:getPrivate('CLASS_ELEMENT_ID'))
            return id
        end
        return false
    end]==]
}
CLASSFUNCTION = false
CLASSELEMENTS = {}

function __REGISTERCLASS__(name,public,private,org)
    local constructor = function() end;local doOnEachFunction,doOnEachFunctionBeforCall,createConstructor = constructor,constructor,constructor
    local _get = function(self,key)
        return rawget(self,key)
    end
    local _set = function(self,key,value)
        return rawset(self,key,value)
    end
    local _add = constructor -- "+"
    local _sub = constructor -- "-"
    local _mul = constructor -- "*"
    local _div = constructor -- "/"
    local _mod = constructor -- "%"
    local _unm = constructor -- "-"
    local _concat = constructor -- ".."
    local _eq = constructor -- "=="
    local _lt = constructor -- "<"
    local _le = constructor -- "<="
    local _len = constructor -- "#"
    local orgType = org and '_1' or '_2'
    if type(name) == 'string' then
        local names = {['_1'] = name,['_2'] = '_' .. name}
        for k,n in pairs(names) do
            _G[n] = {__name = n,__private = private,__public = public}
            _G[n].__index = _G[n]
            CLASSELEMENTS[n] = {}
            for pr,prVal in pairs(private) do
                if pr == '_get' then
                    _get = prVal
                elseif pr == '_set' then 
                    _set = prVal
                elseif pr == "_add" then 
                    _add = prVal
                elseif pr == "_sub" then 
                    _sub = prVal
                elseif pr == "_mul" then 
                    _mul = prVal
                elseif pr == "_div" then 
                    _div = prVal
                elseif pr == "_mod" then 
                    _mod = prVal
                elseif pr == "_unm" then 
                    _unm = prVal
                elseif pr == "_concat" then 
                    _concat = prVal
                elseif pr == "_eq" then 
                    _eq = prVal
                elseif pr == "_lt" then 
                    _lt = prVal
                elseif pr == "_le" then 
                    _le = prVal
                else
                    _G[n][tostring(_G[n]) .. ':private:value:' .. pr] = prVal
                end
            end
            for pub,pubVal in pairs(public) do
                switch (pub){
                    case = {
                        {n,function()
                            if type(pubVal) == 'function' then 
                                constructor = pubVal
                            end
                        end},
                        {'_',function()
                            if type(pubVal) == 'function' then 
                                createConstructor = pubVal
                            end
                        end},
                        {'doOnEachFunction',function()
                            if type(pubVal) == 'function' then 
                                doOnEachFunction = pubVal
                            end
                        end},
                        {'doOnEachFunctionBeforCall',function()
                            if type(pubVal) == 'function' then 
                                doOnEachFunctionBeforCall = pubVal
                            end
                        end}
                    },
                    default = function(v)
                        if v ~= n and v ~= '_' and v ~= 'doOnEachFunctionBeforCall' and v ~= 'doOnEachFunction' then
                            switch (type(pubVal)){
                                case = {
                                    {'function',function()
                                        _G[n][pub] = function(self,...)
                                            doOnEachFunctionBeforCall(self,...)
                                            local values = {pubVal(self,...)}
                                            doOnEachFunction(self,...)
                                            return unpack(values)
                                        end
                                    end}
                                },
                                default = function(vl)
                                    if type(vl) ~= 'function' then 
                                        _G[n][pub] = pubVal
                                    end
                                end
                            }
                        end
                    end
                }
            end
            for nam,func in pairs(CLASSFUNCTIONS) do
                switch (type(func)){
                    case = {
                        {'string',function()
                            loadstring('CLASSFUNCTION = ' .. func)()
                            _G[n][nam] = CLASSFUNCTION
                        end}
                    }
                }
            end
            setmetatable(_G[n],{
                __call = function(self,...)
                    local tab = {}
                    for i,v in pairs(self.__public) do 
                        rawset(tab,i,v)
                    end
                    for key,val in pairs(self.__private) do 
                        tab[tostring(tab) .. ':private:value:' .. key] = val
                    end
                    if type(CLASSELEMENTS[self.__name]) == 'table' then 
                        table.insert(CLASSELEMENTS[self.__name],tab)
                        tab[tostring(tab) .. ':private:value:CLASS_ELEMENT_ID'] = #CLASSELEMENTS[self.__name]
                        tab[tostring(tab) .. ':private:value:_________CLSINSTANCE_________'] = self
                    end
                    for k,v in pairs(self) do 
                        for name in pairs(CLASSFUNCTIONS) do 
                            if k == name then 
                                rawset(tab,k,v)
                            end
                        end
                    end
                    self.__index = _get
                    self.__newindex = _set
                    self.__add = _add
                    self.__sub = _sub
                    self.__mul = _mul
                    self.__div = _div
                    self.__mod = _mod
                    self.__unm = _unm
                    self.__concat = _concat
                    self.__eq = _eq
                    self.__lt = _lt
                    self.__le = _le
                    setmetatable(tab,self)
                    if k == orgType then
                        local args = {...}
                        local nm = args[1]
                        local nme = nm
                        if nm:find(':') or nm:find(' ') then
                            local spls = nm:find(':') and split(nm,':') or split(nm,' ')
                            local syns,canC = {'local'},false
                            for i,v in ipairs(spls) do 
                                for _,syn in ipairs(syns) do 
                                    if v == syn then
                                        canC = true
                                    else
                                        nme = v
                                    end
                                end
                            end
                            if canC then 
                                _G['@SELFLOCALS@'][nme] = tab
                            end
                        end
                        _G[nme] = tab
                        createConstructor(tab,...)
                        return function(...)
                            constructor(tab,...)
                        end
                    else
                        constructor(tab,...)
                        return tab
                    end
                end,
                __index = _get,
                __newindex = _set,
                __add = _add,
                __sub = _sub,
                __mul = _mul,
                __div = _div,
                __mod = _mod,
                __unm = _unm,
                __concat = _concat,
                __eq = _eq,
                __lt = _lt,
                __le = _le
            })
        end
        return names
    elseif type(name) == 'table' then
        local target = {__name = '...',__private = private,__public = public}
        target.__index = target
        CLASSELEMENTS[target] = {}
        for pr,prVal in pairs(private) do
            if pr == '_get' then 
                _get = prVal
            elseif pr == '_set' then 
                _set = prVal
            elseif pr == "_add" then 
                _add = prVal
            elseif pr == "_sub" then 
                _sub = prVal
            elseif pr == "_mul" then 
                _mul = prVal
            elseif pr == "_div" then 
                _div = prVal
            elseif pr == "_mod" then 
                _mod = prVal
            elseif pr == "_unm" then 
                _unm = prVal
            elseif pr == "_concat" then 
                _concat = prVal
            elseif pr == "_eq" then 
                _eq = prVal
            elseif pr == "_lt" then 
                _lt = prVal
            elseif pr == "_le" then 
                _le = prVal
            else
                target[tostring(target) .. ':private:value:' .. pr] = prVal
            end
        end
        for pub,pubVal in pairs(public) do 
            switch (pub){
                case = {
                    {'constructor',function()
                        if type(pubVal) == 'function' then 
                            constructor = pubVal
                        end
                    end},
                    {'_',function()
                        if type(pubVal) == 'function' then 
                            createConstructor = pubVal
                        end
                    end},
                    {'doOnEachFunction',function()
                        if type(pubVal) == 'function' then 
                            doOnEachFunction = pubVal
                        end
                    end},
                    {'doOnEachFunctionBeforCall',function()
                        if type(pubVal) == 'function' then 
                            doOnEachFunctionBeforCall = pubVal
                        end
                    end}
                },
                default = function(v)
                    if v ~= 'constructor' and v ~= '_' and v ~= 'doOnEachFunctionBeforCall' and v ~= 'doOnEachFunction' then 
                        switch (type(pubVal)){
                            case = {
                                {'function',function()
                                    target[pub] = function(self,...)
                                        doOnEachFunctionBeforCall(self,...)
                                        local values = {pubVal(self,...)}
                                        doOnEachFunction(self,...)
                                        return unpack(values)
                                    end
                                end}
                            },
                            default = function(vl)
                                if type(vl) ~= 'function' then 
                                    target[pub] = pubVal
                                end
                            end
                        }
                    end
                end
            }
        end
        for nam,func in pairs(CLASSFUNCTIONS) do
            switch (type(func)){
                case = {
                    {'string',function()
                        loadstring('CLASSFUNCTION = ' .. func)()
                        target[nam] = CLASSFUNCTION
                    end}
                }
            }
        end
        setmetatable(target,{
            __call = function(self,...)
                local tab = {}
                for i,v in pairs(self.__public) do 
                    rawset(tab,i,v)
                end
                for key,val in pairs(self.__private) do 
                    tab[tostring(tab) .. ':private:value:' .. key] = val
                end
                if type(CLASSELEMENTS[self]) == 'table' then
                    table.insert(CLASSELEMENTS[self],tab)
                    tab[tostring(tab) .. ':private:value:CLASS_ELEMENT_ID'] = #CLASSELEMENTS[self]
                    tab[tostring(tab) .. ':private:value:_________CLSINSTANCE_________'] = self
                end
                for k,v in pairs(self) do 
                    for name in pairs(CLASSFUNCTIONS) do 
                        if k == name then 
                            rawset(tab,k,v)
                        end
                    end
                end
                setmetatable(tab,{
                    __call = self.__call,
                    __index = _get,
                    __newindex = _set,
                    __add = _add,
                    __sub = _sub,
                    __mul = _mul,
                    __div = _div,
                    __mod = _mod,
                    __unm = _unm,
                    __concat = _concat,
                    __eq = _eq,
                    __lt = _lt,
                    __le = _le
                })
                constructor(tab,...)
                return tab
            end,
            __index = _get,
            __newindex = _set,
            __add = _add,
            __sub = _sub,
            __mul = _mul,
            __div = _div,
            __mod = _mod,
            __unm = _unm,
            __concat = _concat,
            __eq = _eq,
            __lt = _lt,
            __le = _le
        })
        return target
    end
    return false
end

function __UNPACKNAMEDATA__(data)
    if type(data) == 'string' then
        local space = data:find(':') and ':' or ' '
        local properties,propData = {'org'},{}
        if type(space) == 'string' and space:len() > 0 then
            local args = split(data,space)
            for i = 1,#args do 
                if i == 1 then 
                    propData.name = args[i]
                else
                    for _,val in ipairs(properties) do 
                        if args[i] == val then 
                            propData[val] = true
                        end
                    end
                end
            end
        end
        return propData
    end
    return false
end

function class(name)
    if type(name) == 'table' then
        local public,private = {},{}
        for vName,v in pairs(name) do 
            if vName ~= 'public' and vName ~= 'private' then 
                private[vName] = v
            elseif vName == 'private' then 
                for pr,prVal in pairs(v) do 
                    private[pr] = prVal
                end
            elseif vName == 'public' then 
                public = v
            end
        end
        if public and private then
            return __REGISTERCLASS__(name,public,private,false) 
        end
    elseif type(name) == 'string' then
        return function(data)
            if type(data) == 'table' then 
                local public,private = {},{}
                local nameData = __UNPACKNAMEDATA__(name)
                for vName,v in pairs(data) do 
                    if vName ~= 'public' and vName ~= 'private' then
                        private[vName] = v
                    elseif vName == 'private' then 
                        for pr,prVal in pairs(v) do 
                            private[pr] = prVal
                        end
                    elseif vName == 'public' then
                        public = v
                    end
                end
                if public and private then 
                    return __REGISTERCLASS__(nameData.name,public,private,nameData.org)
                end
            end
            return false
        end
    end
    return false
end

function struct(name)
    if type(name) == 'table' then 
        local public,private = {},{}
        for vName,v in pairs(name) do
            if vName ~= 'public' and vName ~= 'private' then 
                public[vName] = v
            elseif vName == 'public' then 
                for pub,pubVal in pairs(v) do 
                    public[pub] = pubVal
                end
            elseif vName == 'private' then 
                private = v
            end
        end
        if public and private then 
            return __REGISTERCLASS__(name,public,private,false)
        end
    elseif type(name) == 'string' then 
        return function(data)
            if type(name) == 'string' then 
                if type(data) == 'table' then 
                    local public,private = {},{}
                    local nameData = __UNPACKNAMEDATA__(name)
                    for vName,v in pairs(data) do 
                        if vName ~= 'public' and vName ~= 'private' then 
                            public[vName] = v
                        elseif vName == 'public' then 
                            for pub,pubVal in pairs(v) do 
                                public[pub] = pubVal
                            end
                        elseif vName == 'private' then 
                            private = v
                        end
                    end
                    if public and private then 
                        return __REGISTERCLASS__(nameData.name,public,private,nameData.org)
                    end
                end
            end
            return false
        end
    end
    return false
end

function switch(value)
    return function(data)
        if type(data) == 'table' then
            data.default = type(data.default) == 'function' and data.default or function() end
            data.case = type(data.case) == 'table' and data.case or {}
            if data.case then 
                for i,val in ipairs(data.case) do 
                    if type(val) == 'table' then 
                        if val[1] == value then
                            if type(val[2]) == 'function' then 
                                val[2](val[1])
                            end
                        end
                    end
                end
            end
            data.default(value,data.case)
            return true
        end
        return false
    end
end

function instanceof(value,cls)
    if type(value) == 'table' and type(cls) == 'table' then
        if type(value.getPrivate) == 'function' then
            if type(value:getPrivate('_________CLSINSTANCE_________')) == 'table' then  
                if value:getPrivate('_________CLSINSTANCE_________') == cls then 
                    return true
                end
            end
        end
    end
    return false
end