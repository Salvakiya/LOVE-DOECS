local bit = require("bit")
local class = require("classic")

--[[
    in the article they use 22 for index bits and 8 for generation bits...
    they do this so that the id can fit in a light userdata.  Since this is
    currently all lua lets take advantage of the extra bits we have.
]]
local ENTITY_INDEX_BITS = 48 
local ENTITY_INDEX_MASK =bit.lshift(1,ENTITY_INDEX_BITS)-1


local ENTITY_GENERATION_BITS = 12
local ENTITY_GENERATION_MASK = bit.lshift(1,ENTITY_GENERATION_BITS)-1


--bitshifting functions
local band,bor,lshift,rshift = bit.band,bit.bor,bit.lshift,bit.rshift


local Entity = class:extend()
    --this should only be called from EntityManager
    function Entity:new(index,generation)
        self.id = bit.bor(bit.lshift(generation,ENTITY_INDEX_BITS),index)
    end
    
    --get the index for the entity
    function Entity:index()
        return bit.band(self.id, ENTITY_INDEX_MASK)
    end
    
    --get the generation for the entity
    function Entity:generation() 
        return bit.band(bit.rshift(self.id, ENTITY_INDEX_BITS), ENTITY_GENERATION_MASK)
    end


local EntityManager = class:extend()
    
    function EntityManager:new(minimum)
        self._generation = {} -- keeps a record of all entities
        self._free_indices = {} -- keeps a record of all free indices
        self.MINIMUM_FREE_INDICES = minimum or 1024 -- number of free indices until recycle
    end
    
    function EntityManager:create()
        
        local idx

        --if our _free_indices meets requirements(more than x amount of destroyed entities)
        if #self._free_indices>self.MINIMUM_FREE_INDICES then
            --get the index which is free
            idx = table.remove(self._free_indices,1)
        else
            --this is the first generation for this index
            table.insert(self._generation,1)

            --this is the actual index
            idx = #self._generation
            assert(idx<bit.lshift(1,ENTITY_INDEX_BITS),"ERROR??")
        end

        --create our entity and let it generate its ID
        return Entity(idx, self._generation[idx])
    end
    
    --check if entity e is alive
    function EntityManager:alive(e)
        --check if the entity's id matches the id/generation at its index
        return self._generation[e:index()] == e.generation()
    end
    
    --destroy entity e
    function EntityManager:destroy(e)
        --get the index of the entity from its id
        local idx = e:index()

        --increment the generation... this means the generation at e's index no longer matches
        self._generation[idx] = self._generation[idx]+1

        --add this index to the _free_indices table
        table.insert(self._free_indices,idx)
    end



    
    return EntityManager