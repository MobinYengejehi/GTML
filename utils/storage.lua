class "Storage"{
    public = {
        Storage = function(self)
            self.store = {}
        end,
        Set = function(self,key,value)
            if key ~= nil and type(key) ~= "boolean" then
                local last = self:Get(key)
                if last ~= value then  
                    self.store[key] = value
                end
            end
        end,
        Get = function(self,key)
            if key ~= nil and type(key) ~= "boolean" then 
                return self.store[key]
            end
        end
    }
}