---------- READ BEFORE USING ASTAR.LUA --------
---------- READ BEFORE USING ASTAR.LUA --------
---------- READ BEFORE USING ASTAR.LUA --------
---------- READ BEFORE USING ASTAR.LUA --------
--[[

This is a project made by 0x28 please credit me
If your going to take an inspiration out of it
Or taking knowledge / Code out of it
Thank you!

]]--
---------- READ BEFORE USING ASTAR.LUA --------
---------- READ BEFORE USING ASTAR.LUA --------
---------- READ BEFORE USING ASTAR.LUA --------
---------- READ BEFORE USING ASTAR.LUA --------





--[[

() Optimized A* Algorithm ()

]]--
local functions = {}
local cache_data = {} -- Cache data basically
local cach_lifetime = 10 -- Cache lifetime for less lag :P
local last_cached = 0
-- Math Libs \
local floor = math.floor
local pi = math.pi
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
    local serialized = serialized_vector(position)
    if cache_data[serialized] then
        return cache_data[serialized]
    end

    if not workspace.Terrain:WorldToCellPreferEmpty(position) then
        cache_data[serialized] = true
        return true
    end

    local region = Region3.new(position - Vector3.new(0.5, 0.1, 0.5), position + Vector3.new(0.5, 0.1, 0.5))
    local parts = workspace:FindPartsInRegion3(region, nil, math.huge)
    for _, part in ipairs(parts) do
        if part:IsDescendantOf(workspace.Game.Map.Map.Supplies) then
            print(part.Name)
        end
        if part:IsA("BasePart") and part.CanCollide and not part:IsDescendantOf(workspace.Game.PlayerFolder[game.Players.LocalPlayer.Name].Units) and not part:IsDescendantOf(workspace.Game.Map.Map.Supplies) then
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
        Vector3.new(0.3, 0, 0), Vector3.new(-0.3, 0, 0), Vector3.new(0, -0.5, 0),
        Vector3.new(0, 0, 0.3), Vector3.new(0, 0, -0.3),
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
    while goal[serialized_vector(current)] do
        table.insert(path, 1, current)
        current = deserialized_vector(goal[serialized_vector(current)])
    end
    return path
end

local function priority(queue, node, fScore)
    local inserted = false
    for i = 1, #queue do
        if fScore[serialized_vector(node)] < fScore[serialized_vector(queue[i])] then
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
functions.initialize = function(s, g)
    local start = Vector3.new(floor(s.X), floor(s.Y), floor(s.Z)) -- required or else the calculation will be fucked
    local goal = Vector3.new(floor(g.X), floor(g.Y), floor(g.Z))
    if os.clock() - last_cached > cach_lifetime then
        cache_data = {} -- cleans cache
        last_cached = os.clock()
    end

    local path = AStar(start, goal)
    if not path then
        warn("No path found. Rerouting path")

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
    for i = 1, #path do
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
    for i = 1, #path do
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
functions.getnearest = function(start, path, stud)

    local nearest = nil
    local nearest_distance = stud
    for _, supply in ipairs(path:GetChildren()) do -- supply: path childrens or model, child: basepart
        for _, child in ipairs(supply:GetChildren()) do
            if child:IsA("BasePart") and not child.Parent:GetAttribute('Occupied') then
                --print(child:GetAttribute('Occupied'), not child:GetAttribute('Occupied'))
                local distance = (start - child.Position).Magnitude
                if distance < nearest_distance then
                    --print(child:GetAttribute('Occupied'), not child:GetAttribute('Occupied'))
                    nearest_distance = distance
                    nearest = supply
                end
                break
            end
        end
    end

    return nearest
end

functions.isnear = function(start, goal, stud)
    local magnitude = (start - goal).Magnitude
    if magnitude < stud then
        return true
    end
    return false
end
functions.estimated = function(path, speed)
    local total_distance = 0
    for i = 1, #path - 1 do
        total_distance = total_distance + (path[i + 1] - path[i]).Magnitude
    end
    local estimated_time = total_distance / speed
    return estimated_time
end
functions.getworkposition = function(pos)
    local ray = pos
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {workspace.Game.PlayerFolder[game.Players.LocalPlayer.Name].Units} -- Add any parts to ignore here
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    local result = workspace:Raycast(ray, Vector3.new(0, -200, 0), raycastParams)
    return result.Position
end
functions.getselectedunit = function(unit)
    local valid = false
    local amount = 0
    units = {} -- clears the table so to prevent invalids
    for _, child in ipairs(workspace.Game.PlayerFolder[game.Players.LocalPlayer.Name].Units:GetChildren()) do
        if child:FindFirstChild("SelectionPart") and child.Name == unit then
            table.insert(units, child)
            valid = true -- checks
            amount = amount + 1
        end
    end    
    return units, valid, amount
end
return functions
