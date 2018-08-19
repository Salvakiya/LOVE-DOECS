local bit = require("bit")
local class = require("classic")

local ENTITY_INDEX_BITS = 48
local ENTITY_INDEX_MASK =bit.lshift(1,ENTITY_INDEX_BITS)-1

local ENTITY_GENERATION_BITS = 12
local ENTITY_GENERATION_MASK = bit.lshift(1,ENTITY_GENERATION_BITS)-1

local band,bor,lshift,rshift = bit.band,bit.bor,bit.lshift,bit.rshift

local Entity = class:extend()
    function Entity:new(index,generation)
        self.id = bit.bor(bit.lshift(generation,ENTITY_INDEX_BITS),index)
    end
    function Entity:index()
        return bit.band(self.id, ENTITY_INDEX_MASK)
    end
    function Entity:generation() 
        return bit.band(bit.rshift(self.id, ENTITY_INDEX_BITS), ENTITY_GENERATION_MASK)
    end

local DebugNameComponentManager = {}
local EntityManager = class:extend()
    function EntityManager:new(minimum)
        self._generation = {}
        self._free_indices = {}
        self.MINIMUM_FREE_INDICES = minimum or 1024
    end
    function EntityManager:create()
        local idx
        if #self._free_indices>self.MINIMUM_FREE_INDICES then
            idx = table.remove(self._free_indices,1)
        else
            table.insert(self._generation,1)
            idx = #self._generation
            assert(idx<bit.lshift(1,ENTITY_INDEX_BITS),"ERROR??")
        end
        return Entity(idx, self._generation[idx])
    end
    function EntityManager:alive(e)
        return self._generation[e:index()] == e.generation()
    end
    function EntityManager:destroy(e)
        local idx = e:index()
        self._generation[idx] = self._generation[idx]+1
        table.insert(self._free_indices,idx)
    end



    
    return EntityManager