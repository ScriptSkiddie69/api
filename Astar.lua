local functions = {}

functions.heuristic = function(a, b)
    return math.abs(a.X - b.X) + math.abs(a.Y - b.Y)
end


functions.isBlocked = function(position)
    local region = Region3.new(position - Vector3.new(0.5, 0.5, 0.5), position + Vector3.new(0.5, 0.5, 0.5))
    local parts = workspace:FindPartsInRegion3(region, nil, math.huge)
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and part.CanCollide then
            return true
        end
    end
    return false
end

functions.getNeighbors = function(node)
    local neighbors = {}
    local directions = {
        Vector3.new(1, 0, 0), -- Right
        Vector3.new(-1, 0, 0), -- Left
        Vector3.new(0, 0, 1), -- Forward
        Vector3.new(0, 0, -1), -- Backward
    }
    
    for _, dir in ipairs(directions) do
        local neighbor = node + dir
        if not functions.isBlocked(neighbor) then
            table.insert(neighbors, neighbor)
        end
    end
    return neighbors
end

-- Reconstruct path incase of blocking
functions.reconstructPath = function(cameFrom, current)
    local path = {}
    while cameFrom[current] do
        table.insert(path, 1, current)
        current = cameFrom[current]
    end
    return path
end

-- A* Algorithm to find a path
functions.AStar = function(start, goal)
    local openSet = {start}
    local cameFrom = {}
    local gScore = {[start] = 0}
    local fScore = {[start] = functions.heuristic(start, goal)}
    
    while #openSet > 0 do
        local current = table.remove(openSet, 1)
        if current == goal then
            return functions.reconstructPath(cameFrom, current)
        end
        
        for _, neighbor in ipairs(functions.getNeighbors(current)) do
            local tentative_gScore = gScore[current] + 1
            if not gScore[neighbor] or tentative_gScore < gScore[neighbor] then
                cameFrom[neighbor] = current
                gScore[neighbor] = tentative_gScore
                fScore[neighbor] = gScore[neighbor] + functions.heuristic(neighbor, goal)
                
                local found = false
                for _, node in ipairs(openSet) do
                    if node == neighbor then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(openSet, neighbor)
                end
            end
        end
    end
    
    return nil
end

functions.findPathToGoal = function(start, goal)
    local path = functions.AStar(start, goal)
    if not path then
        print("No direct path found. Attempting to find an alternate route.")

        local reroutedGoal = Vector3.new(goal.X + 5, goal.Y, goal.Z + 5)
        return functions.AStar(start, reroutedGoal)
    end
    
    return path
end
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
return functions
