
--[[
    Complete Roblox Script with Fluent GUI
    Features:
    - Autofarm Toggle
    - Cash Aura Toggle
    - Box ESP Toggle
    - Health ESP Toggle
    - Name ESP Toggle
    - Tracers Toggle
    - Skeleton ESP Toggle
    - Autokill Toggle (Enhanced)
    - Hitbox Expander
    - Hitbox Visualizer
    - Hitbox Size Slider
    - Settings and Save Manager
    Author: Finny<3 (with additions)
--]]

-- Load Fluent and its Addons
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Create the Fluent Window
local Window = Fluent:CreateWindow({
    Title = "Collapse-Baddies",
    SubTitle = "Made by Finny<3",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main" }),
    Visuals = Window:AddTab({ Title = "Visuals" }),
    Cash = Window:AddTab({ Title = "Cash" }),
    Combat = Window:AddTab({ Title = "Combat" }),
    Settings = Window:AddTab({ Title = "Settings" })
}

-- Initialize Toggle States
local autofarmEnabled = false
local cashAuraEnabled = false
local boxESPEnabled = false
local healthESPEnabled = false
local nameESPEnabled = false
local tracersEnabled = false
local skeletonESPEnabled = false
local autokillEnabled = false
local hitboxExpanded = false
local hitboxSize = 20  -- Default size
local hitboxVisualized = false

-- ESP Configuration Table
local Config = {
    Box = false,
    BoxColor = Color3.fromRGB(255, 255, 255),
    BoxThickness = 1,
    BoxOutline = true,
    BoxOutlineColor = Color3.fromRGB(255, 255, 255),
    BoxOutlineThickness = 1,
    HealthBar = false,
    HealthBarSide = "Left",
    Names = false,
    NamesColor = Color3.fromRGB(255, 255, 255),
    NamesOutline = true,
    NamesOutlineColor = Color3.fromRGB(0, 0, 0),
    NamesFont = 2,
    NamesSize = 13,
    Tracers = false,
    TracerColor = Color3.fromRGB(255, 255, 255),
    TracerThickness = 1.4,
    TracerTransparency = 1,
    Skeleton = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    SkeletonThickness = 1
}

-- Autofarm Functionality
local function startAutofarm()
    local plr = game.Players.LocalPlayer
    local cash = workspace:FindFirstChild("Cash")
    local dmg = workspace:FindFirstChild("Damageables")

    if not cash or not dmg then
        warn("Cash or Damageables folder not found in the workspace.")
        return
    end

    -- Prevent player from being idled
    for _, v in next, getconnections(plr.Idled) do
        v:Disable()
    end

    -- Function to pick up cash with teleportation
    local function getMoneyAutofarm()
        local cashPickedUp = false
        for _, m in pairs(cash:GetChildren()) do
            if m.Name == "Cash" and (m.Position - plr.Character.HumanoidRootPart.Position).Magnitude <= 300 then
                cashPickedUp = true
                plr.Character.HumanoidRootPart.CFrame = m.CFrame
                fireproximityprompt(m.ProximityPrompt, 6)
                task.wait(0.1)
            end
            if not getgenv().farm then
                break
            end
        end
        return cashPickedUp
    end

    -- Main autofarm loop
    while getgenv().farm do
        pcall(function()
            local Noclip = nil
            local Clip = nil

            function noclip()
                Clip = false
                local function Nocl()
                    if Clip == false and game.Players.LocalPlayer.Character ~= nil then
                        for _,v in pairs(game.Workspace.Damageables:GetDescendants()) do
                            if v:IsA('Model') and v.Name == 'ATM' then
                                for _, part in pairs(v:GetDescendants()) do
                                    if part:IsA('BasePart') and part.CanCollide then
                                        part.CanCollide = false
                                    end
                                end
                            end
                        end
                    end
                    wait(0.21)
                end
                Noclip = game:GetService('RunService').Stepped:Connect(Nocl)
            end

            function clip()
                if Noclip then Noclip:Disconnect() end
                Clip = true
            end

            noclip()

            for _, a in ipairs(dmg:GetChildren()) do
                if not getgenv().farm then break end
                if a:FindFirstChild("Damageable") and a.Damageable.Value > 0 and a.Name ~= "CashRegister" then
                    plr.Character.HumanoidRootPart.CFrame = a.Screen.CFrame * CFrame.new(0, 0, 0)
                    task.wait(0.3)

                    -- Break the ATM
                    repeat
                        if not getgenv().farm then break end
                        plr.Character.HumanoidRootPart.CFrame = a.Screen.CFrame * CFrame.new(0, 0, 0)
                        game:GetService("ReplicatedStorage"):WaitForChild("PUNCHEVENT"):FireServer(1)
                        task.wait(0.5)
                    until a.Damageable.Value <= 0

                    -- Ensure all cash is picked up before moving to the next ATM
                    local endTime = tick() + 2
                    local cashPickedUp
                    repeat
                        if not getgenv().farm then break end
                        cashPickedUp = getMoneyAutofarm()
                        task.wait(0.2)
                    until tick() >= endTime and not cashPickedUp

                    -- Move to next ATM if no cash was picked up
                    if not cashPickedUp then
                        task.wait(0.5)
                    end
                end
            end
        end)
        task.wait(1)
    end
end

-- Updated Cash Aura Functionality
local cashAuraConnection = nil

local function startCashAura()
    local player = game.Players.LocalPlayer
    local cashFolder = workspace:FindFirstChild("Cash")

    if not cashFolder then
        warn("Cash folder not found in the workspace.")
        return
    end

    -- Prevent player from being idled
    for _, connection in ipairs(getconnections(player.Idled)) do
        connection:Disable()
    end

    -- Function to collect cash
    local function collectCash()
        while cashAuraEnabled do
            local cashCollected = false
            
            for _, cash in pairs(cashFolder:GetChildren()) do
                if cash:IsA("Part") and cash:FindFirstChild("ProximityPrompt") then
                    local distance = (cash.Position - player.Character.HumanoidRootPart.Position).Magnitude

                    if distance <= 10 then
                        cashCollected = true
                        fireproximityprompt(cash.ProximityPrompt, 6)
                        task.wait(0.1)
                    end
                end
            end

            if not cashCollected then
                print("No cash collected this loop. Retrying...")
            end
            
            task.wait(0.1)
        end
    end

    cashAuraConnection = spawn(collectCash)
end

local function stopCashAura()
    if cashAuraConnection then
        cashAuraConnection:Disconnect()
        cashAuraConnection = nil
    end
end

-- Add Toggles to Cash Tab
local AutofarmToggle = Tabs.Cash:AddToggle("AutofarmToggle", {
    Title = "Autofarm (Enable Punch before toggling)",
    Default = false
})

local CashAuraToggle = Tabs.Cash:AddToggle("CashAuraToggle", {
    Title = "Cash Aura",
    Default = false
})

-- Add Toggles to Visuals Tab
local BoxToggle = Tabs.Visuals:AddToggle("BoxESP", {
    Title = "Box ESP",
    Default = false,
})

local HealthToggle = Tabs.Visuals:AddToggle("HealthESP", {
    Title = "Health ESP",
    Default = false,
})

local NameToggle = Tabs.Visuals:AddToggle("NameESP", {
    Title = "Name ESP",
    Default = false,
})

local TracerToggle = Tabs.Visuals:AddToggle("Tracers", {
    Title = "Tracers",
    Default = false,
})

local SkeletonToggle = Tabs.Visuals:AddToggle("SkeletonESP", {
    Title = "Skeleton ESP",
    Default = false,
})

-- Add Combat Tab Features
local HitboxExpanderToggle = Tabs.Combat:AddToggle("HitboxExpanderToggle", {
    Title = "Hitbox Expander",
    Default = false
})

local HitboxVisualizerToggle = Tabs.Combat:AddToggle("HitboxVisualizerToggle", {
    Title = "Hitbox Visualizer",
    Default = false
})

local HitboxSizeSlider = Tabs.Combat:AddSlider("HitboxSizeSlider", {
    Title = "Hitbox Size",
    Description = "Adjust the hitbox size",
    Default = 20,
    Min = 1,
    Max = 150,
    Rounding = 0,
    Callback = function(Value)
        hitboxSize = Value
        if hitboxExpanded then
            updateHitboxes()
        end
        if hitboxVisualized then
            updateHitboxVisualizer()
        end
    end
})

-- Add Autokill Toggle to Combat Tab
local AutokillToggle = Tabs.Combat:AddToggle("AutokillToggle", {
    Title = "Autokill",
    Default = false
})

-- Table to Track ESP Elements per Player
local ESPElements = {}

-- Function to Create ESP for a Player
local function CreateEsp(Player)
    if ESPElements[Player] then return end

    local Box = Drawing.new("Square")
    local BoxOutline = Drawing.new("Square")
    local Name = Drawing.new("Text")
    local HealthBar = Drawing.new("Square")
    local Tracer = Drawing.new("Line")
    local SkeletonLines = {
        Head = Drawing.new("Line"),
        UpperTorso = Drawing.new("Line"),
        LowerTorso = Drawing.new("Line"),
        LeftUpperArm = Drawing.new("Line"),
        LeftLowerArm = Drawing.new("Line"),
        RightUpperArm = Drawing.new("Line"),
        RightLowerArm = Drawing.new("Line"),
        LeftUpperLeg = Drawing.new("Line"),
        LeftLowerLeg = Drawing.new("Line"),
        RightUpperLeg = Drawing.new("Line"),
        RightLowerLeg = Drawing.new("Line")
    }

    Box.Filled = false
    Box.Color = Config.BoxColor
    Box.Thickness = Config.BoxThickness
    Box.ZIndex = 69
    Box.Visible = boxESPEnabled

    BoxOutline.Filled = false
    BoxOutline.Color = Config.BoxOutlineColor
    BoxOutline.Thickness = Config.BoxOutlineThickness
    BoxOutline.ZIndex = 68
    BoxOutline.Visible = Config.BoxOutline and boxESPEnabled

    Name.Visible = false
    Name.Center = true
    Name.Color = Config.NamesColor
    Name.Font = Config.NamesFont
    Name.Size = Config.NamesSize
    Name.Outline = Config.NamesOutline
    Name.OutlineColor = Config.NamesOutlineColor
    Name.ZIndex = 69

    HealthBar.Filled = true
    HealthBar.Color = Color3.fromRGB(0, 255, 0)
    HealthBar.ZIndex = 70
    HealthBar.Visible = healthESPEnabled

    Tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
    Tracer.To = Vector2.new(0, 0)
    Tracer.Color = Config.TracerColor
    Tracer.Thickness = Config.TracerThickness
    Tracer.Transparency = Config.TracerTransparency
    Tracer.Visible = tracersEnabled

    for _, line in pairs(SkeletonLines) do
        line.Thickness = Config.SkeletonThickness
        line.Color = Config.SkeletonColor
        line.Visible = skeletonESPEnabled
    end

    ESPElements[Player] = {
        Box = Box,
        BoxOutline = BoxOutline,
        Name = Name,
        HealthBar = HealthBar,
        Tracer = Tracer,
        SkeletonLines = SkeletonLines,
        IsVisible = false
    }

    local Updater = game:GetService("RunService").RenderStepped:Connect(function()
        if Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("Head") and Player.Character.Humanoid.Health > 0 then
            local Humanoid = Player.Character.Humanoid
            local HRP = Player.Character.HumanoidRootPart
            local Camera = workspace.CurrentCamera

            local Target2dPosition, IsVisible = Camera:WorldToViewportPoint(HRP.Position)

            local distance = (Camera.CFrame.p - HRP.Position).Magnitude
            local scale_factor = 1 / (distance * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 100
            local width, height = math.floor(30 * scale_factor), math.floor(45 * scale_factor)

            ESPElements[Player].IsVisible = IsVisible

            if boxESPEnabled then
                Box.Visible = IsVisible
                Box.Size = Vector2.new(width, height)
                Box.Position = Vector2.new(Target2dPosition.X - Box.Size.X / 2, Target2dPosition.Y - Box.Size.Y / 2)
            else
                Box.Visible = false
            end

            if Config.BoxOutline and boxESPEnabled then
                BoxOutline.Visible = IsVisible
                BoxOutline.Size = Vector2.new(width, height)
                BoxOutline.Position = Vector2.new(Target2dPosition.X - BoxOutline.Size.X / 2, Target2dPosition.Y - BoxOutline.Size.Y / 2)
            else
                BoxOutline.Visible = false
            end

            if healthESPEnabled then
                HealthBar.Visible = IsVisible

                local barWidth = Config.BoxThickness
                local barHeight = height * (Humanoid.Health / Humanoid.MaxHealth)

                if Config.HealthBarSide == "Left" then
                    HealthBar.Size = Vector2.new(barWidth, barHeight)
                    HealthBar.Position = Vector2.new(Target2dPosition.X - width / 2 - barWidth - 2, Target2dPosition.Y + height / 2 - barHeight - 1)
                elseif Config.HealthBarSide == "Bottom" then
                    HealthBar.Size = Vector2.new(width - 6, 2)
                    HealthBar.Position = Vector2.new(Target2dPosition.X - width / 2 + 3, Target2dPosition.Y + height / 2 + 5)
                end

                local healthPercent = Humanoid.Health / Humanoid.MaxHealth
                HealthBar.Color = Color3.fromRGB(255, 0, 0):lerp(Color3.fromRGB(0, 255, 0), healthPercent)
            else
                HealthBar.Visible = false
            end

            if Config.Names then
                Name.Visible = IsVisible
                Name.Text = Player.Name .. " " .. math.floor(distance) .. "m"
                Name.Position = Vector2.new(Target2dPosition.X, Target2dPosition.Y - height * 0.5 - 15)
            else
                Name.Visible = false
            end

            if Config.Tracers then
                Tracer.Visible = IsVisible
                Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                Tracer.To = Vector2.new(Target2dPosition.X, Target2dPosition.Y)
            else
                Tracer.Visible = false
            end

            if Config.Skeleton then
                local function worldToViewportPoint(position)
                    local screenPosition, onScreen = Camera:WorldToViewportPoint(position)
                    return Vector2.new(screenPosition.X, screenPosition.Y), onScreen
                end

                local function updateSkeletonLine(line, startPart, endPart)
                    if startPart and endPart then
                        local startPos, startVisible = worldToViewportPoint(startPart.Position)
                        local endPos, endVisible = worldToViewportPoint(endPart.Position)
                        line.From = startPos
                        line.To = endPos
                        line.Visible = startVisible and endVisible and IsVisible
                    else
                        line.Visible = false
                    end
                end

                local character = Player.Character
                updateSkeletonLine(SkeletonLines.Head, character:FindFirstChild("Head"), character:FindFirstChild("UpperTorso"))
                updateSkeletonLine(SkeletonLines.UpperTorso, character:FindFirstChild("UpperTorso"), character:FindFirstChild("LowerTorso"))
                updateSkeletonLine(SkeletonLines.LowerTorso, character:FindFirstChild("LowerTorso"), character:FindFirstChild("UpperTorso"))
                updateSkeletonLine(SkeletonLines.LeftUpperArm, character:FindFirstChild("LeftUpperArm"), character:FindFirstChild("LeftLowerArm"))
                updateSkeletonLine(SkeletonLines.LeftLowerArm, character:FindFirstChild("LeftLowerArm"), character:FindFirstChild("LeftHand"))
                updateSkeletonLine(SkeletonLines.RightUpperArm, character:FindFirstChild("RightUpperArm"), character:FindFirstChild("RightLowerArm"))
                updateSkeletonLine(SkeletonLines.RightLowerArm, character:FindFirstChild("RightLowerArm"), character:FindFirstChild("RightHand"))
                updateSkeletonLine(SkeletonLines.LeftUpperLeg, character:FindFirstChild("LeftUpperLeg"), character:FindFirstChild("LeftLowerLeg"))
                updateSkeletonLine(SkeletonLines.LeftLowerLeg, character:FindFirstChild("LeftLowerLeg"), character:FindFirstChild("LeftFoot"))
                updateSkeletonLine(SkeletonLines.RightUpperLeg, character:FindFirstChild("RightUpperLeg"), character:FindFirstChild("RightLowerLeg"))
                updateSkeletonLine(SkeletonLines.RightLowerLeg, character:FindFirstChild("RightLowerLeg"), character:FindFirstChild("RightFoot"))
            else
                for _, line in pairs(SkeletonLines) do
                    line.Visible = false
                end
            end
        else
            Box.Visible = false
            BoxOutline.Visible = false
            Name.Visible = false
            HealthBar.Visible = false
            Tracer.Visible = false
            for _, line in pairs(SkeletonLines) do
                line.Visible = false
            end
        end
    end)

    Player.CharacterRemoving:Connect(function()
        Box:Remove()
        BoxOutline:Remove()
        Name:Remove()
        HealthBar:Remove()
        Tracer:Remove()
        for _, line in pairs(SkeletonLines) do
            line:Remove()
        end
        Updater:Disconnect()
        ESPElements[Player] = nil
    end)
end

-- Function to Update ESP Visibility Based on Toggles
local function updateESPVisibility()
    for _, elements in pairs(ESPElements) do
        if elements.Box and elements.BoxOutline then
            elements.Box.Visible = boxESPEnabled and elements.IsVisible
            elements.BoxOutline.Visible = boxESPEnabled and Config.BoxOutline and elements.IsVisible
        end

        if elements.HealthBar then
            elements.HealthBar.Visible = healthESPEnabled and elements.IsVisible
        end

        if elements.Name then
            elements.Name.Visible = Config.Names and elements.IsVisible
        end

        if elements.Tracer then
            elements.Tracer.Visible = Config.Tracers and elements.IsVisible
        end

        if elements.SkeletonLines then
            for _, line in pairs(elements.SkeletonLines) do
                line.Visible = Config.Skeleton and elements.IsVisible
            end
        end
    end
end

-- Connect OnChanged Events for ESP Toggles
BoxToggle:OnChanged(function(value)
    boxESPEnabled = value
    Config.Box = boxESPEnabled
    updateESPVisibility()
end)

HealthToggle:OnChanged(function(value)
    healthESPEnabled = value
    Config.HealthBar = healthESPEnabled
    updateESPVisibility()
end)

NameToggle:OnChanged(function(value)
    nameESPEnabled = value
    Config.Names = nameESPEnabled
    updateESPVisibility()
end)

TracerToggle:OnChanged(function(value)
    tracersEnabled = value
    Config.Tracers = tracersEnabled
    updateESPVisibility()
end)

SkeletonToggle:OnChanged(function(value)
    skeletonESPEnabled = value
    Config.Skeleton = skeletonESPEnabled
    updateESPVisibility()
end)

-- Hitbox Expander Function
local function updateHitboxes()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
            player.Character.HumanoidRootPart.Transparency = 1
            player.Character.HumanoidRootPart.CanCollide = false
        end
    end
end

-- Hitbox Visualizer Function
local visualizerParts = {}

local function updateHitboxVisualizer()
    for _, part in pairs(visualizerParts) do
        part:Destroy()
    end
    visualizerParts = {}

    if hitboxVisualized then
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local visualizer = Instance.new("Part")
                visualizer.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                visualizer.CFrame = player.Character.HumanoidRootPart.CFrame
                visualizer.Color = Color3.new(1, 0, 0)  -- Red color
                visualizer.Transparency = 0.7
                visualizer.CanCollide = false
                visualizer.Anchored = true
                visualizer.Parent = workspace
                table.insert(visualizerParts, visualizer)
            end
        end
    end
end

-- Connect Combat Tab Toggle Actions
HitboxExpanderToggle:OnChanged(function(value)
    hitboxExpanded = value
    if hitboxExpanded then
        updateHitboxes()
    else
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)  -- Reset to default size
                player.Character.HumanoidRootPart.Transparency = 1
                player.Character.HumanoidRootPart.CanCollide = true
            end
        end
    end
end)

HitboxVisualizerToggle:OnChanged(function(value)
    hitboxVisualized = value
    updateHitboxVisualizer()
end)

-- Enhanced Autokill Functionality
local autokillConnection = nil
local currentTarget = nil

local function startAutokill()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local punchRemote = game:GetService("ReplicatedStorage"):WaitForChild("PUNCHEVENT")

    local function getClosestPlayer()
        local closestPlayer = nil
        local shortestDistance = math.huge

        for _, otherPlayer in pairs(game.Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("Humanoid") and otherPlayer.Character.Humanoid.Health > 0 then
                local distance = (otherPlayer.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
                if distance < shortestDistance then
                    closestPlayer = otherPlayer
                    shortestDistance = distance
                end
            end
        end

        return closestPlayer
    end

    local function equipPunch()
        local punchTool = player.Backpack:FindFirstChild("1 punches")
        if punchTool then
            humanoid:EquipTool(punchTool)
        end
    end

    autokillConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not autokillEnabled then return end

        if not currentTarget or not currentTarget.Character or currentTarget.Character.Humanoid.Health <= 0 then
            currentTarget = getClosestPlayer()
        end

        if currentTarget then
            equipPunch()
            character.HumanoidRootPart.CFrame = currentTarget.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)
            punchRemote:FireServer(1)  -- Use the correct argument
        end
    end)
end

local function stopAutokill()
    if autokillConnection then
        autokillConnection:Disconnect()
        autokillConnection = nil
    end
    currentTarget = nil
end

-- Toggle Actions for Autokill
AutokillToggle:OnChanged(function(value)
    autokillEnabled = value
    if autokillEnabled then
        startAutokill()
    else
        stopAutokill()
    end
end)

-- Function to Create ESP for All Current Players
local function initializeESP()
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            CreateEsp(player)
            player.CharacterAdded:Connect(function()
                CreateEsp(player)
            end)
        end
    end
end

-- Initialize ESP for Existing Players
initializeESP()

-- Connect to New Players Joining the Game
game:GetService("Players").PlayerAdded:Connect(function(player)
    if player ~= game.Players.LocalPlayer then
        CreateEsp(player)
        player.CharacterAdded:Connect(function()
            CreateEsp(player)
        end)
    end
end)

-- Clean Up ESP When Players Leave
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if ESPElements[player] then
        ESPElements[player].Box:Remove()
        ESPElements[player].BoxOutline:Remove()
        ESPElements[player].Name:Remove()
        ESPElements[player].HealthBar:Remove()
        ESPElements[player].Tracer:Remove()
        for _, line in pairs(ESPElements[player].SkeletonLines) do
            line:Remove()
        end
        ESPElements[player] = nil
    end
end)

-- Toggle Actions for Autofarm
AutofarmToggle:OnChanged(function(value)
    autofarmEnabled = value
    getgenv().farm = autofarmEnabled

    if autofarmEnabled then
        spawn(function()
            startAutofarm()
        end)
    end
end)

-- Toggle Actions for Cash Aura
CashAuraToggle:OnChanged(function(value)
    cashAuraEnabled = value
    if cashAuraEnabled then
        startCashAura()
    else
        stopCashAura()
    end
end)

-- Ensure All GUI Elements are Updated and Saved
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
