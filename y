-- Variables
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera = game.Workspace.CurrentCamera
local espEnabled = false -- ESP starts off
local highlightObjects = {}
local aimbotEnabled = false -- Aimbot tracking status

-- Function to create or update the highlight object (ESP)
local function highlightPlayer(targetPlayer)
    if not highlightObjects[targetPlayer.Name] then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = targetPlayer.Character
        highlight.FillTransparency = 0.5 -- Semi-transparent glow
        highlight.OutlineTransparency = 0 -- Visible outline
        highlightObjects[targetPlayer.Name] = highlight
        
        -- Set highlight color based on team
        if targetPlayer.Team == player.Team then
            highlight.FillColor = Color3.new(0, 1, 0) -- Green for teammates
        else
            highlight.FillColor = Color3.new(1, 0, 0) -- Red for enemies
        end

        highlight.Parent = targetPlayer.Character
    end
end

-- Function to update ESP colors
local function updateESPColors()
    for _, highlight in pairs(highlightObjects) do
        if highlight and highlight.Parent then
            -- Update colors based on team
            if highlight.Adornee and highlight.Adornee:IsA("Model") then
                local targetPlayer = game.Players:GetPlayerFromCharacter(highlight.Adornee)
                if targetPlayer then
                    highlight.FillColor = targetPlayer.Team == player.Team and Color3.new(0, 1, 0) or Color3.new(1, 0, 0) -- Green for teammates, Red for enemies
                end
            end
        end
    end
end

-- Function to find the closest player
local function getClosestEnemy()
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, target in ipairs(game.Players:GetPlayers()) do
        if target ~= player and target.Character and target.Character:FindFirstChild("Head") then
            -- Check if the target is on the opposing team
            if target.Team ~= player.Team then
                local targetPosition = target.Character.Head.Position
                local screenPoint = camera:WorldToScreenPoint(targetPosition)
                local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude

                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = target
                end
            end
        end
    end

    return closestPlayer
end

-- Function to aim at the closest player's head
local function aimAtClosestPlayerHead()
    local targetPlayer = getClosestEnemy()
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
        local targetHead = targetPlayer.Character.Head
        local adjustedAimPosition = targetHead.Position + Vector3.new(0, 1, 0) -- Adjust height by 1 unit

        -- Aim at the adjusted target position directly
        camera.CFrame = CFrame.new(camera.CFrame.Position, adjustedAimPosition) -- Aim at the adjusted target position
    end
end

-- Toggle ESP on/off with "F"
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent then
        if input.KeyCode == Enum.KeyCode.F then
            espEnabled = not espEnabled
            if espEnabled then
                -- Highlight all players for ESP
                local players = game.Players:GetPlayers()
                for _, targetPlayer in pairs(players) do
                    if targetPlayer ~= player and targetPlayer.Character then
                        highlightPlayer(targetPlayer)
                    end
                end
            else
                -- Clear highlights
                for _, highlight in pairs(highlightObjects) do
                    if highlight then
                        highlight:Destroy()
                    end
                end
                highlightObjects = {}
            end
        end
    end
end)

-- Detect holding right-click for aimbot (track closest enemy head)
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent then
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            aimbotEnabled = true -- Enable aimbot (tracking starts)
        end
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimbotEnabled = false -- Disable aimbot (tracking stops)
    end
end)

-- Update ESP and aimbot every frame
game:GetService("RunService").RenderStepped:Connect(function()
    -- Update ESP colors
    if espEnabled then
        updateESPColors()
    end

    -- Aim at the closest player on the opposing team
    if aimbotEnabled then
        aimAtClosestPlayerHead() -- Aim at the closest player's head
    end
end)
