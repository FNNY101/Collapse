local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = game:GetService("Workspace").CurrentCamera
local UserInputService = game:GetService("UserInputService")
local MousePos = UserInputService:GetMouseLocation()
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Infinite Ammo Variables
local WeaponryFramework
local WeaponHandler
local InfiniteAmmoEnabled = false

-- Current Tracer Position
local currentTracerPosition = "Bottom"

-- ESP Table
local ESP = {
 Enabled = true,
 TeamCheck = false,
 Box = {
     Enabled = false,
     Color = Color3.fromRGB(255, 255, 255),
     Thickness = 1,
     Outlines = true,
     OutlineThickness = 1
 },
 Tool = {
     Enabled = false,
     Color = Color3.fromRGB(255, 255, 255)
 },
 Distance = {
     Enabled = false,
     Color = Color3.fromRGB(255, 255, 255)
 },
 Tracers = {
     Enabled = false,
     Color = Color3.fromRGB(255, 255, 255),
     Thickness = 1,
     Outlines = true,
     OutlineThickness = 1
 },
 HealthBar = {
     Enabled = false,
     Color = Color3.fromRGB(0, 255, 0),
     Outlines = true
 }
}

-- Silent Aim Settings
getgenv().silentaim_settings = {
 enabled = false,
 fov = 150,
 hitbox = "Head",
 fovcircle = false,
 teamCheck = false,
 fovPosition = "Mouse"
}

-- Create Circle for FOV
local Circle = Drawing.new("Circle")
Circle.Visible = false
Circle.Thickness = 1
Circle.Color = Color3.fromRGB(255, 255, 255)
Circle.Transparency = 0.5
Circle.Filled = false

-- Silent Aim Implementation
local SilentAimTarget = nil

local function GetDirection(origin, destination)
    return (destination - origin).Unit * 1000
end

local function WorldToScreen(position)
    local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(position)
    return {Position = Vector2.new(screenPos.X, screenPos.Y), OnScreen = onScreen}
end

local function IsTeammate(player)
    return player.Character and player.Character:FindFirstChild("Teammate") ~= nil
end

local function HasCharacter(player)
    return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function GetClosestPlayer()
    local screenCenter = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y / 2)
    local mousePos = getgenv().silentaim_settings.fovPosition == "Mouse" and 
                     UserInputService:GetMouseLocation() or 
                     screenCenter
    
    local closestPlayer = nil
    local shortestDistance = getgenv().silentaim_settings.fov
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and HasCharacter(player) then
            -- Modified Team Check Logic
            if not (getgenv().silentaim_settings.teamCheck and 
                    player.Team and 
                    player.Team == LocalPlayer.Team) then
                local targetPart = player.Character:FindFirstChild(getgenv().silentaim_settings.hitbox or "Head")
                if targetPart then
                    local screenPos = WorldToScreen(targetPart.Position)
                    if screenPos.OnScreen then
                        local distance = (mousePos - screenPos.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Update Silent Aim Target
RunService.RenderStepped:Connect(function()
    if getgenv().silentaim_settings.enabled then
        SilentAimTarget = GetClosestPlayer()
    else
        SilentAimTarget = nil
    end
 
    -- Updated FOV Circle Handling
    local screenCenter = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y / 2)
    
    if getgenv().silentaim_settings.fovPosition == "Mouse" then
        Circle.Position = UserInputService:GetMouseLocation()
    else -- Centered
        Circle.Position = screenCenter
    end
    
    Circle.Radius = getgenv().silentaim_settings.fov
    Circle.Visible = getgenv().silentaim_settings.fovcircle
end)

-- Infinite Ammo Function
local function SetupInfiniteAmmo()
    WeaponryFramework = getsenv(LocalPlayer.PlayerScripts.WeaponryFramework)
    WeaponHandler = ReplicatedStorage.Remotes.WeaponHandler

    local WeaponPropertiesTable1
    local WeaponPropertiesTable2

    RunService.RenderStepped:Connect(function()
        if not InfiniteAmmoEnabled then return end

        for I, V in pairs(WeaponryFramework) do
            if I == "InventoryManager" then
                local InventoryManagerFunc = V
                for I, V in pairs(debug.getupvalues(InventoryManagerFunc)) do
                    if type(V) == "table" then
                        for I, V in pairs(V) do
                            if type(V) == "table" then
                                if I == 1 then
                                    WeaponPropertiesTable1 = V
                                    if WeaponPropertiesTable1.CurrentAmmo < WeaponPropertiesTable1.WeaponStats.MaxAmmo then
                                        WeaponPropertiesTable1.Reloading = true
                                        WeaponHandler:FireServer(3, WeaponPropertiesTable1)
                                        WeaponPropertiesTable1.CurrentAmmo = WeaponPropertiesTable1.WeaponStats.MaxAmmo
                                        WeaponPropertiesTable1.Reloading = false
                                    end
                                end
                                if I == 2 then
                                    WeaponPropertiesTable2 = V
                                    if WeaponPropertiesTable2.CurrentAmmo < WeaponPropertiesTable2.WeaponStats.MaxAmmo then
                                        WeaponPropertiesTable2.Reloading = true
                                        WeaponHandler:FireServer(3, WeaponPropertiesTable2)
                                        WeaponPropertiesTable2.CurrentAmmo = WeaponPropertiesTable2.WeaponStats.MaxAmmo
                                        WeaponPropertiesTable2.Reloading = false
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Hook Raycast
local Old
Old = hookmetamethod(game, "__namecall", function(Self, ...)
    local Args = {...}
    local method = getnamecallmethod()
    
    if not checkcaller() and Self == Workspace and method == "Raycast" and getgenv().silentaim_settings.enabled and SilentAimTarget then
        local origin = Args[1]
        Args[2] = GetDirection(origin, SilentAimTarget.Character[getgenv().silentaim_settings.hitbox].Position)
        return Old(Self, unpack(Args))
    end
    
    return Old(Self, ...)
end)

-- ESP Functions
local Functions = {}
do 
function Functions:IsAlive(Player)
    if Player and Player.Character and Player.Character:FindFirstChild("Head") and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0 then
        return true
    end
    return false
end
 
function Functions:GetTeam(Player)
    if not Player.Neutral then
        return game:GetService("Teams")[Player.Team.Name]
    end
    return "No Team"
end
 
function Functions:GetEquippedTool(Player)
    if Player and Player.Character then
        local Tool = Player.Character:FindFirstChildOfClass("Tool")
        if Tool then
            return Tool.Name
        end
    end
    return "None"
end
 
function Functions:GetDistance(Player)
    if Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return math.floor((Player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
    end
    return 0
end
end

-- ESP Implementation
do
local function AddESP(Player)
    local BoxOutline = Drawing.new("Square")
    local Box = Drawing.new("Square")
    local TracerOutline = Drawing.new("Line")
    local Tracer = Drawing.new("Line")
    local HealthBarOutline = Drawing.new("Square")
    local HealthBar = Drawing.new("Square")
    local ToolText = Drawing.new("Text")
    local DistanceText = Drawing.new("Text")
    local Connection
 
    Box.Filled = false
    BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    TracerOutline.Color = Color3.fromRGB(0, 0, 0)
    HealthBarOutline.Filled = false
    HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    HealthBar.Filled = true
    HealthBar.ZIndex = 5
 
    ToolText.Size = 13
    ToolText.Center = true
    ToolText.Outline = true
    ToolText.Font = 2
    ToolText.Color = ESP.Tool.Color
 
    DistanceText.Size = 13
    DistanceText.Center = true
    DistanceText.Outline = true
    DistanceText.Font = 2
    DistanceText.Color = ESP.Distance.Color
 
    local function HideESP()
        BoxOutline.Visible = false
        Box.Visible = false
        TracerOutline.Visible = false
        Tracer.Visible = false
        HealthBarOutline.Visible = false
        HealthBar.Visible = false
        ToolText.Visible = false
        DistanceText.Visible = false
    end
 
    local function DestroyESP()
        BoxOutline:Remove()
        Box:Remove()
        TracerOutline:Remove()
        Tracer:Remove()
        HealthBarOutline:Remove()
        HealthBar:Remove()
        ToolText:Remove()
        DistanceText:Remove()
        Connection:Disconnect()
    end
 
    Connection = RunService.Heartbeat:Connect(function()
        if not ESP.Enabled then 
            return HideESP()
        end
 
        if not Player or not Player.Parent then
            return DestroyESP()
        end
 
        if not Functions:IsAlive(Player) then
            return HideESP()
        end
 
        -- Modified Team Check Logic for ESP
        if (ESP.TeamCheck and 
            Player.Team and 
            Player.Team == LocalPlayer.Team) then
            return HideESP()
        end
 
        local HumanoidRootPart = Player.Character.HumanoidRootPart
        if not HumanoidRootPart then
            return HideESP()
        end
 
        local ScreenPosition, OnScreen = CurrentCamera:WorldToViewportPoint(HumanoidRootPart.Position)
        if not OnScreen then
            return HideESP()
        end
 
        local FrustumHeight = math.tan(math.rad(CurrentCamera.FieldOfView * 0.5)) * 2 * ScreenPosition.Z
        local Size = CurrentCamera.ViewportSize.Y / FrustumHeight * Vector2.new(5,6)
        local Position = Vector2.new(ScreenPosition.X, ScreenPosition.Y) - Size / 2

        if ESP.Box.Enabled then
            BoxOutline.Visible = ESP.Box.Outlines
            BoxOutline.Thickness = ESP.Box.Thickness + ESP.Box.OutlineThickness
            BoxOutline.Position = Position
            BoxOutline.Size = Size
 
            Box.Visible = true
            Box.Position = Position
            Box.Size = Size
            Box.Color = ESP.Box.Color
            Box.Thickness = ESP.Box.Thickness
        else
            Box.Visible = false
            BoxOutline.Visible = false
        end
 
        if ESP.Tool.Enabled then
            ToolText.Visible = true
            ToolText.Text = Functions:GetEquippedTool(Player)
            ToolText.Position = Vector2.new(Position.X + (Size.X / 2), Position.Y + Size.Y + 2)
            ToolText.Color = ESP.Tool.Color
        else
            ToolText.Visible = false
        end
 
        if ESP.Distance.Enabled then
            DistanceText.Visible = true
            DistanceText.Text = tostring(Functions:GetDistance(Player)) .. " studs"
            DistanceText.Position = Vector2.new(Position.X + (Size.X / 2), Position.Y - 15)
            DistanceText.Color = ESP.Distance.Color
        else
            DistanceText.Visible = false
        end

        if ESP.Tracers.Enabled then
            local tracerFrom
            if currentTracerPosition == "Bottom" then
                tracerFrom = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y)
            elseif currentTracerPosition == "Middle" then
                tracerFrom = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y / 2)
            elseif currentTracerPosition == "Top" then
                tracerFrom = Vector2.new(CurrentCamera.ViewportSize.X / 2, 0)
            elseif currentTracerPosition == "Mouse" then
                tracerFrom = UserInputService:GetMouseLocation()
            end

            TracerOutline.Visible = ESP.Tracers.Outlines
            TracerOutline.Thickness = ESP.Tracers.Thickness + ESP.Tracers.OutlineThickness
            TracerOutline.From = tracerFrom
            TracerOutline.To = Vector2.new(ScreenPosition.X, Position.Y + Size.Y)

            Tracer.Visible = true
            Tracer.Color = ESP.Tracers.Color
            Tracer.Thickness = ESP.Tracers.Thickness
            Tracer.From = tracerFrom
            Tracer.To = Vector2.new(TracerOutline.To.X, TracerOutline.To.Y)
        else
            TracerOutline.Visible = false
            Tracer.Visible = false
        end

        if ESP.HealthBar.Enabled then
            HealthBarOutline.Visible = ESP.HealthBar.Outlines
            HealthBarOutline.Position = Vector2.new(Position.X - 6, Position.Y + Size.Y)
            HealthBarOutline.Size = Vector2.new(3, -Size.Y * Player.Character.Humanoid.Health / Player.Character.Humanoid.MaxHealth)
            HealthBarOutline.Thickness = 1

            HealthBar.Visible = true
            HealthBar.Position = HealthBarOutline.Position
            HealthBar.Size = HealthBarOutline.Size
            HealthBar.Color = ESP.HealthBar.Color
        else
            HealthBarOutline.Visible = false
            HealthBar.Visible = false
        end
    end)
end

for i,v in pairs(Players:GetChildren()) do 
    if v ~= LocalPlayer then
        AddESP(v)
    end
end

Players.PlayerAdded:Connect(function(v)
    AddESP(v)
end)
end

-- Window Creation
local Window = Library:CreateWindow{
    Title = "Collapse:Weaponry",
    SubTitle = "Made by Finny <3",
    TabWidth = 160,
    Size = UDim2.fromOffset(530, 350),
    Acrylic = false,
    Theme = "VSC Dark High Contrast",
    MinimizeKey = Enum.KeyCode.RightControl
}

-- Tabs
local Tabs = {
    Main = Window:CreateTab{
        Title = "Main",
        Icon = "target"
    },
    Visuals = Window:CreateTab{
        Title = "Visuals",
        Icon = "eye"
    },
    Settings = Window:CreateTab{
        Title = "Settings",
        Icon = "settings"
    }
}

-- Main Tab Toggles and Sliders
Tabs.Main:CreateToggle("SilentAim", {
    Title = "Silent Aim",
    Default = false,
    Callback = function(Value)
        getgenv().silentaim_settings.enabled = Value
    end
})

Tabs.Main:CreateToggle("SilentAimTeamCheck", {
    Title = "Silent Aim Team Check",
    Default = false,
    Callback = function(Value)
        getgenv().silentaim_settings.teamCheck = Value
    end
})

Tabs.Main:CreateToggle("FovCircle", {
    Title = "FOV Circle",
    Default = false,
    Callback = function(Value)
        getgenv().silentaim_settings.fovcircle = Value
    end
})

Tabs.Main:CreateDropdown("FovPosition", {
    Title = "FOV Position",
    Values = {"Mouse", "Centered"},
    Default = "Mouse",
    Callback = function(Value)
        getgenv().silentaim_settings.fovPosition = Value
    end
})

Tabs.Main:CreateSlider("FovSize", {
    Title = "FOV Size",
    Default = 100,
    Min = 1,
    Max = 800,
    Rounding = 0,
    Callback = function(Value)
        getgenv().silentaim_settings.fov = Value
    end
})

Tabs.Main:CreateDropdown("SilentAimTarget", {
    Title = "Silent Aim Target",
    Values = {"Head", "HumanoidRootPart"},
    Default = "Head",
    Callback = function(Value)
        getgenv().silentaim_settings.hitbox = Value
    end
})

Tabs.Main:CreateToggle("InfiniteAmmo", {
    Title = "Infinite Ammo",
    Default = false,
    Callback = function(Value)
        InfiniteAmmoEnabled = Value
        if Value then
            SetupInfiniteAmmo()
        end
    end
})

Tabs.Main:CreateSlider("PlayerSpeed", {
    Title = "Player Speed",
    Default = 16,
    Min = 16,
    Max = 150,
    Rounding = 0,
    Callback = function(Value)
        local Character = game.Players.LocalPlayer.Character
        if Character and Character:FindFirstChild("Humanoid") then
            Character.Humanoid.WalkSpeed = Value
        end
    end
})

Tabs.Main:CreateSlider("JumpHeight", {
    Title = "Jump Height",
    Default = 50,
    Min = 50,
    Max = 150,
    Rounding = 0,
    Callback = function(Value)
        local Character = game.Players.LocalPlayer.Character
        if Character and Character:FindFirstChild("Humanoid") then
            Character.Humanoid.JumpPower = Value
        end
    end
})

-- Visuals Tab
Tabs.Visuals:CreateToggle("BoxESP", {
    Title = "Box ESP",
    Default = false,
    Callback = function(Value)
        ESP.Box.Enabled = Value
    end
})

Tabs.Visuals:CreateToggle("Tracers", {
    Title = "Tracers",
    Default = false,
    Callback = function(Value)
        ESP.Tracers.Enabled = Value
    end
})

Tabs.Visuals:CreateDropdown("TracerPosition", {
    Title = "Tracer Position",
    Values = {"Bottom", "Middle", "Top", "Mouse"},
    Default = "Bottom",
    Callback = function(Value)
        currentTracerPosition = Value
    end
})

Tabs.Visuals:CreateToggle("Healthbar", {
    Title = "Healthbar",
    Default = false,
    Callback = function(Value)
        ESP.HealthBar.Enabled = Value
    end
})

Tabs.Visuals:CreateToggle("ToolESP", {
    Title = "Tool ESP",
    Default = false,
    Callback = function(Value)
        ESP.Tool.Enabled = Value
    end
})

Tabs.Visuals:CreateToggle("DistanceESP", {
    Title = "Distance ESP",
    Default = false,
    Callback = function(Value)
        ESP.Distance.Enabled = Value
    end
})

Tabs.Visuals:CreateToggle("ESPTeamCheck", {
    Title = "ESP Team Check",
    Default = false,
    Callback = function(Value)
        ESP.TeamCheck = Value
    end
})

-- Save Manager and Interface Manager Setup
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("CollapseWeaponry")
InterfaceManager:SetFolder("CollapseWeaponry")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Notification
Library:Notify{
    Title = "Collapse-Weaponry",
    Content = "Script loaded successfully! - Made by finny<3",
    Duration = 5
}

-- Load Autoconfig
SaveManager:LoadAutoloadConfig()