struct "PathCommand"{
    PathCommand = function(self,command)
        if type(command) == "string" and #command > 0 then 
            self.command = command
            self.storage = Storage()
        end
    end,
    Set = function(self,key,value)
        if instanceof(self.storage,Storage) then 
            self.storage:Set(key,value)
        end
    end,
    Get = function(self,key)
        if instanceof(self.storage,Storage) then 
            return self.storage:Get(key,value)
        end
    end
}

class "Path"{
    public = {
        Path = function(self,element,parent)
            if IsElement(element) and instanceof(parent,PixelBox) then 
                self.element = element
                self.parent = parent
                self.commands = {}
                self.fill = "black"
                self.stroke = "none"
                self.strokeWidth = 1
            end
        end,
        MoveTo = function(self,x,y)
            if type(self.commands) == "table" then
                x = tonumber(x)
                y = tonumber(y)
                if x and y then
                    local command = PathCommand("M")
                    command:Set("x",x)
                    command:Set("y",y)
                    table.insert(self.commands,command)
                end
            end
        end,
        LineTo = function(self,x,y)
            if type(self.commands) == "table" then
                x = tonumber(x)
                y = tonumber(y)
                if x and y then 
                    local command = PathCommand("L")
                    command:Set("x",x)
                    command:Set("y",y)
                    table.insert(self.commands,command)
                end
            end
        end,
        CurveTo = function(self,x1,y1,x2,y2,x,y)
            if type(self.commands) == "table" then 
                x1 = tonumber(x1)
                y1 = tonumber(y1)
                x2 = tonumber(x2)
                y2 = tonumber(y2)
                x = tonumber(x)
                y = tonumber(y)
                if x1 and y1 and x2 and y2 and x and y then
                   local command = PathCommand("C")
                   command:Set("x1",x1)
                   command:Set("y1",y1)
                   command:Set("x2",x2)
                   command:Set("y2",y2)
                   command:Set("x",x)
                   command:Set("y",y)
                   table.insert(self.commands,command)
                end
            end
        end,
        QuadTo = function(self,x1,y1,x,y)
            if type(self.commands) == "table" then 
                x1 = tonumber(x1)
                y1 = tonumber(y1)
                x = tonumber(x)
                y = tonumber(y)
                if x1 and y1 and x and y then
                    local command = PathCommand("Q")
                    command:Set("x1",x1)
                    command:Set("y1",y1)
                    command:Set("x",x)
                    command:Set("y",y)
                    table.insert(self.commands,command)
                end
            end
        end,
        Fill = function(self,color)
            if type(self.commands) == "table" then
                if type(color) == "string" and #color > 0 then 
                    self.fill = color
                end
            end
        end,
        Stroke = function(self,color)
            if type(self.commands) == "table" then 
                if type(color) == "string" and #color > 0 then
                    self.stroke = color
                end
            end
        end,
        StrokeWidth = function(self,width)
            if type(self.commands) == "table" then 
                width = tonumber(width) 
                if width then
                    self.strokeWidth = width
                end
            end
        end,
        Close = function(self)
            if type(self.commands) == "table" then
                table.insert(self.commands,PathCommand("Z"))
            end
        end,
        Convert = function(self)
            
        end
    }
}