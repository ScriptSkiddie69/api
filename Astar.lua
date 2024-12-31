---------- READ BEFORE READING ASTAR.LUA --------
---------- READ BEFORE READING ASTAR.LUA --------
---------- READ BEFORE READING ASTAR.LUA --------
---------- READ BEFORE READING ASTAR.LUA --------
--[[
| Also credit https://www.youtube.com/watch?v=PzEWHH2v3TE
| Learnt astar algorithm to that video
This is a project made by 0x28 please credit me
If your going to take an inspiration out of it
Or taking knowledge / Code out of it
Thank you!

]]--
---------- READ BEFORE READING ASTAR.LUA --------
---------- READ BEFORE READING ASTAR.LUA --------
---------- READ BEFORE READING ASTAR.LUA --------
---------- READ BEFORE READING ASTAR.LUA --------





--[[

/ () Optimized A* Algorithm NOT DONE () \

]]--
local functions = {}
local cache_data = {} -- Cache data basically
local cach_lifetime = 10 -- Cache lifetime for less lag :P
local last_cached = 0

local function serialized_vector(vector)
    return tostring(vector.X) .. "," .. tostring(vector.Y) .. "," .. tostring(vector.Z)
end

local function deserialized_vector(serialized)
    local x, y, z = string.match(serialized, "([^,]+),([^,]+),([^,]+)")
    return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
end

local function heuristic(a, b)
    return math.abs(a.X - b.X) + math.abs(a.Z - b.Z)
end

local function is_blocked(position)
    local serialized = serializeVector(position)
    if cache_data[serialized] then
        return cache_data[serialized]
    end

    if not workspace.Terrain:WorldToCellPreferEmpty(position) then
        cache_data[serialized] = true
        return true
    end

    local region = Region3.new(position - Vector3.new(0.5, 0.5, 0.5), position + Vector3.new(0.5, 0.5, 0.5))
    local parts = workspace:FindPartsInRegion3(region, nil, math.huge)
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and part.CanCollide then
            cache_data[serialized] = true
            return true
        end
    end

    cache_data[serialized] = false
    return false
end

local function get_neighbor(node)
    local neighbors = {}
    local directions = {
        Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
    }

    for _, dir in ipairs(directions) do
        local neighbor = node + dir
        if not is_blocked(neighbor) then
            table.insert(neighbors, neighbor)
        end
    end
    return neighbors
end

local function reconstruct(goal, current) -- reconstruct path
    local path = {}
    while goal[serializeVector(current)] do
        table.insert(path, 1, current)
        current = deserialized_vector(goal[serializeVector(current)])
    end
    return path
end

local function priority(queue, node, fScore)
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
    local gScore = {[serialized_vector(start)] = 0}
    local fScore = {[serialized_vector(start)] = heuristic(start, goal)}

    while #openSet > 0 do
        local current = table.remove(openSet, 1)
        if current == goal then
            return reconstruct(cameFrom, current)
        end

        for _, neighbor in ipairs(get_neighbor(current)) do
            local serializedNeighbor = serialized_vector(neighbor)
            local tentative_gScore = gScore[serialized_vector(current)] + 1

            if not gScore[serializedNeighbor] or tentative_gScore < gScore[serializedNeighbor] then
                cameFrom[serializedNeighbor] = serialized_vector(current)
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
                    priority(openSet, neighbor, fScore)
                end
            end
        end
    end

    return nil
end

-- faster optimized a* algorthm
functions.findPathToGoal = function(start, goal)
    if os.clock() - last_cached > cach_lifetime then
        cache_data = {} -- cleans cache
        last_cached = os.clock()
    end

    local path = AStar(start, goal)
    if not path then
        warn("No direct path found. Attempting to find an alternate route.")

        local offset = 0
        while not path and offset < 10 do
            offset = offset + 5
            local newgoal = Vector3.new(goal.X + offset, goal.Y, goal.Z)
            path = AStar(start, newgoal)
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

-- walk func (mrts)
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

