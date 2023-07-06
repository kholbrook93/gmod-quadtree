-- Quadtree node class
local QuadNode = {}
QuadNode.__index = QuadNode

--- Create a new QuadNode.
--- @param bounds table The bounds of the QuadNode as { mins = Vector, maxs = Vector }.
--- @return table The new QuadNode instance.
function QuadNode.new(bounds)
    local self = setmetatable({}, QuadNode)
    self.bounds = bounds
    self.objects = {}
    self.children = nil
    return self
end

--- Subdivides the QuadNode into four child nodes.
function QuadNode:subdivide()
    local mins = self.bounds.mins
    local maxs = self.bounds.maxs
    local center = (mins + maxs) / 2

    self.children = {
        QuadNode.new({ mins = Vector(mins.x, mins.y, 0), maxs = Vector(center.x, center.y, 0) }), -- top left
        QuadNode.new({ mins = Vector(center.x, mins.y, 0), maxs = Vector(maxs.x, center.y, 0) }), -- top right
        QuadNode.new({ mins = Vector(mins.x, center.y, 0), maxs = Vector(center.x, maxs.y, 0) }), -- bottom left
        QuadNode.new({ mins = Vector(center.x, center.y, 0), maxs = Vector(maxs.x, maxs.y, 0) }) -- bottom right
    }
end

--- Inserts an object into the QuadNode or its child nodes.
--- @param object table The object to insert.
function QuadNode:insert(object)
    if self.children then
        local position = object.position

        for _, child in ipairs(self.children) do
            local childBounds = child.bounds
            if position.x >= childBounds.mins.x and position.x <= childBounds.maxs.x and
                position.y >= childBounds.mins.y and position.y <= childBounds.maxs.y then
                child:insert(object)
                return
            end
        end
    end

    table.insert(self.objects, object)

    local maxObjects = 4
    if #self.objects > maxObjects and not self.children then
        self:subdivide()

        -- Reinsert objects into children
        for i = #self.objects, 1, -1 do
            local obj = table.remove(self.objects, i)
            self:insert(obj)
        end
    end
end

--- Queries the QuadNode and its child nodes for objects within the specified range.
--- @param range table The range to query as { mins = Vector, maxs = Vector }.
--- @return table The queried objects.
function QuadNode:query(range)
    local result = {}

    if self.children then
        for _, child in ipairs(self.children) do
            local childBounds = child.bounds
            if childBounds.mins.x <= range.maxs.x and childBounds.maxs.x >= range.mins.x and
                childBounds.mins.y <= range.maxs.y and childBounds.maxs.y >= range.mins.y then
                local childResult = child:query(range)
                for _, obj in ipairs(childResult) do
                    table.insert(result, obj)
                end
            end
        end
    end

    for _, obj in ipairs(self.objects) do
        local position = obj.position
        if position.x >= range.mins.x and position.x <= range.maxs.x and
            position.y >= range.mins.y and position.y <= range.maxs.y then
            table.insert(result, obj)
        end
    end

    return result
end

--- Moves an object to a new position within the QuadNode.
--- @param object table The object to move.
--- @param newPosition table The new position of the object as a Vector.
--- Moves an object to a new position within the QuadNode and its children.
--- @param object table The object to move.
--- @param newPosition table The new position of the object as a Vector.
function QuadNode:remove(object)
    local index = nil
    for i, obj in ipairs(self.objects) do
        if obj == object then
            index = i
            break
        end
    end

    if index then
        table.remove(self.objects, index)

        -- Recursively move the object within child nodes if applicable
        if self.children then
            for _, child in ipairs(self.children) do
                child:remove(object)
            end
        end
    end
end

-- Quadtree class
local Quadtree = {}
Quadtree.__index = Quadtree

--- Create a new Quadtree.
--- @param mins table The minimum coordinates of the Quadtree bounds as a Vector.
--- @param maxs table The maximum coordinates of the Quadtree bounds as a Vector.
--- @return table The new Quadtree instance.
function Quadtree.new(mins, maxs)
    local self = setmetatable({}, Quadtree)
    self.root = QuadNode.new({ mins = mins, maxs = maxs })
    return self
end

--- Inserts an object into the Quadtree.
--- @param object table The object to insert.
function Quadtree:insert(object)
    self.root:insert(object)
end

--- Queries the Quadtree for objects within the specified range.
--- @param range table The range to query as { mins = Vector, maxs = Vector }.
--- @return table The queried objects.
function Quadtree:query(range)
    return self.root:query(range)
end

--- Moves an object to a new position within the Quadtree.
--- @param object table The object to move.
--- @param newPosition table The new position of the object as a Vector.
function Quadtree:move(object, newPosition)
    print(object, object.position)
    self.root:remove(object)
    
    object.position = newPosition
    self:insert(object)  -- Reinsert the object based on its new position
    print(object, object.position)
end











-- Create the test object with a position
local testObject = { position = { x = 10, y = 10 } }

-- Create 100 other objects with random positions
local otherObjects = {}
math.randomseed(os.time())
for i = 1, 100 do
    local obj = { position = { x = math.random(0, 100), y = math.random(0, 100) } }
    table.insert(otherObjects, obj)
end

-- Create a Quadtree with a defined range
local quadtreeRange = {
    mins = { x = 0, y = 0 },
    maxs = { x = 100, y = 100 }
}
local quadtree = Quadtree.new(quadtreeRange.mins, quadtreeRange.maxs)

-- Insert all objects into the Quadtree
quadtree:insert(testObject)
for _, obj in ipairs(otherObjects) do
    quadtree:insert(obj)
end

-- Define a range for testing
local testRange = {
    mins = { x = 5, y = 5 },
    maxs = { x = 15, y = 15 }
}

-- Query the Quadtree for objects within the test range
local queryResult = quadtree:query(testRange)

-- Check if the test object is in the query result
local isInRange = false
for _, obj in ipairs(queryResult) do
    if obj == testObject then
        isInRange = true
        break
    end
end

-- Print the result
if isInRange then
    print("Test object is within the range.")
else
    print("Test object is not within the range.")
end

-- Move the test object to a new position
local newPosition = { x = 50, y = 50 }
quadtree:move(testObject, newPosition)

-- Query the Quadtree again for objects within the test range
queryResult = quadtree:query(testRange)

-- Check if the test object is in the query result after moving
isInRange = false
for _, obj in ipairs(queryResult) do
    if obj == testObject then
        isInRange = true
        break
    end
end

-- Print the result after moving
if isInRange then
    print("Test object is still within the range after moving.")
else
    print("Test object is not within the range after moving.")
end
