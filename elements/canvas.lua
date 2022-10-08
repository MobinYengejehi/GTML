class "Canvas"{
    public = {
        Canvas = function(self,element,parent)
            if IsElement(element) and instanceof(parent,PixelBox) then 
                self.element = element
                self.parent = parent
            end
        end
    }
}