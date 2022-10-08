class "BoundingBox"{
    public = {

    }
}

function derive(v0,v1,v2,v3,t)
    v0 = tonumber(v0)
    v1 = tonumber(v1)
    v2 = tonumber(v2)
    v3 = tonumber(v3)
    t = tonumber(t)
    if v0 and v1 and v2 and v3 and t then 
        return ((1 - t)^3)*v0 + 3*((1 - t)^2)*t*v1 + 3*((1 - t)*(t^2))*v2 + (t^3)*v3
    end
end