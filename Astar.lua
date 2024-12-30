-- Utility Functions
local functions = {}
local function serializeVector(vector)
    return tostring(vector.X) .. "," .. tostring(vector.Y) .. "," .. tostring(vector.Z)
end

local function deserializeVector(serialized)
    local x, y, z = string.match(serialized, "([^,]+),([^,]+),([^,]+)")
    return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
end

local function heuristic(a, b)
    return math.abs(a.X - b.X) + math.abs(a.Z - b.Z)
end

local function isBlocked(position)
    if not workspace.Terrain:WorldToCellPreferEmpty(position) then -- out of bounds
        return true
    end

    local region = Region3.new(position - Vector3.new(0.5, 0.5, 0.5), position + Vector3.new(0.5, 0.5, 0.5))
    local parts = workspace:FindPartsInRegion3(region, nil, math.huge)
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and part.CanCollide then
            return true
        end
    end
    return false
end

local function getNeighbors(node)
    local neighbors = {}
    local directions = {
        Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
    }

    for _, dir in ipairs(directions) do
        local neighbor = node + dir
        if not isBlocked(neighbor) then
            table.insert(neighbors, neighbor)
        end
    end
    return neighbors
end

local function reconstructPath(cameFrom, current)
    local path = {}
    while cameFrom[serializeVector(current)] do
        table.insert(path, 1, current)
        current = deserializeVector(cameFrom[serializeVector(current)])
    end
    return path
end

local function insertWithPriority(queue, node, fScore)
    local inserted = false
    for i = 1, #queue do
        if fScore[serializeVector(node)] < fScore[serializeVector(queue[i])] then
            table.insert(queue, i, node)
            inserted = true
            break
        end
    end
    if not inserted then
        table.insert(queue, node)
    end
end

-- A* Algorithm
local function AStar(start, goal)
    local openSet = {start}
    local cameFrom = {}
    local gScore = {[serializeVector(start)] = 0}
    local fScore = {[serializeVector(start)] = heuristic(start, goal)}

    while #openSet > 0 do
        local current = table.remove(openSet, 1)
        if current == goal then
            return reconstructPath(cameFrom, current)
        end

        for _, neighbor in ipairs(getNeighbors(current)) do
            local serializedNeighbor = serializeVector(neighbor)
            local tentative_gScore = gScore[serializeVector(current)] + 1

            if not gScore[serializedNeighbor] or tentative_gScore < gScore[serializedNeighbor] then
                cameFrom[serializedNeighbor] = serializeVector(current)
                gScore[serializedNeighbor] = tentative_gScore
                fScore[serializedNeighbor] = gScore[serializedNeighbor] + heuristic(neighbor, goal)

                local found = false
                for _, node in ipairs(openSet) do
                    if node == neighbor then
                        found = true
                        break
                    end
                end

                if not found then
                    insertWithPriority(openSet, neighbor, fScore)
                end
            end
        end
    end

    return nil
end

-- Pathfinding with Alternate Goal
functions.findPathToGoal = function(start, goal)
    local path = AStar(start, goal)
    if not path then
        print("No direct path found. Attempting to find an alternate route.")

        local offset = 0
        while not path and offset < 10 do
            offset = offset + 5
            local reroutedGoal = Vector3.new(goal.X + offset, goal.Y, goal.Z)
            path = AStar(start, reroutedGoal)
        end
    end
    return path
end

-- Visualization
functions.visualize = function(path)
    for i = 1, #path - 1 do
        local part = Instance.new("Part")
        part.Size = Vector3.new(0.2, 0.2, 0.2)
        part.Position = path[i]
        part.Anchored = true
        part.Material = Enum.Material.Neon
        part.BrickColor = BrickColor.new("Bright Green")
        part.Parent = workspace
        task.spawn(function()
            task.wait(3)
            part:Destroy()
        end)
    end
end
functions.walk = function(path, unit)
    local argss = {
        [1] = false,
        [2] = {
            [1] = {
                [1] = unit,
                [2] = path[1]
            }
        },
        [3] = false
    }
    
    game:GetService("ReplicatedStorage"):WaitForChild("Action"):FireServer(unpack(argss))   
    for i = 1, #path - 1 do
    local args = {
        [1] = true,
        [2] = {
            [1] = {
                [1] = unit,
                [2] = path[i]
            }
        },
        [3] = false
    }
    
    game:GetService("ReplicatedStorage"):WaitForChild("Action"):FireServer(unpack(args))    
    end
end
return functions
