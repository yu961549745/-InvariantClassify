ceRefine:=proc(_e)
    local e;
    e:=factor(_e);
    if type(e,`*`) then
        
    else
        return e;
    end if; 
end proc: