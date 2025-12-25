--// Universal Orion Hub
--// Version 1.0.0

-- Prevent double execution
if getgenv().UniversalOrionLoaded then return end
getgenv().UniversalOrionLoaded = true

------------------------------------------------
-- Services
------------------------------------------------
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

------------------------------------------------
-- Character Handling
------------------------------------------------
local Character, Humanoid, HRP

local function BindCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
end

BindCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
LocalPlayer.CharacterAdded:Connect(BindCharacter)

------------------------------------------------
-- Orion Library
------------------------------------------------
local OrionLib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/shlexware/Orion/main/source"
))()

------------------------------------------------
-- Window
------------------------------------------------
local Window = OrionLib:MakeWindow({
    Name = "Universal Orion Hub",
    HidePremium = true,
    SaveConfig = true,
    ConfigFolder = "UniversalOrion"
})

------------------------------------------------
-- Variables
------------------------------------------------
local InfiniteJump = false
local Fly = false
local Noclip = false
local Invisible = false
local GodMode = false

local FlySpeed = 60
local WalkSpeed = 16

------------------------------------------------
-- Movement Tab
------------------------------------------------
local MovementTab = Window:MakeTab({
    Name = "Movement",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Infinite Jump
MovementTab:AddToggle({
    Name = "Infinite Jump",
    Default = false,
    Callback = function(v)
        InfiniteJump = v
    end
})

UIS.JumpRequest:Connect(function()
    if InfiniteJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- WalkSpeed
MovementTab:AddSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Increment = 1,
    Callback = function(v)
        WalkSpeed = v
        if Humanoid then
            Humanoid.WalkSpeed = v
        end
    end
})

------------------------------------------------
-- Fly
------------------------------------------------
local BV, BG

MovementTab:AddToggle({
    Name = "Fly",
    Default = false,
    Callback = function(v)
        Fly = v

        if Fly and HRP then
            BV = Instance.new("BodyVelocity")
            BG = Instance.new("BodyGyro")

            BV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            BG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)

            BV.Parent = HRP
            BG.Parent = HRP
        else
            if BV then BV:Destroy() BV = nil end
            if BG then BG:Destroy() BG = nil end
        end
    end
})

RunService.RenderStepped:Connect(function()
    if Fly and HRP and BV and BG then
        local move = Vector3.zero

        if UIS:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end

        BV.Velocity = move * FlySpeed
        BG.CFrame = Camera.CFrame
    end
end)

------------------------------------------------
-- Player Tab
------------------------------------------------
local PlayerTab = Window:MakeTab({
    Name = "Player",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Noclip
PlayerTab:AddToggle({
    Name = "Noclip",
    Default = false,
    Callback = function(v)
        Noclip = v
    end
})

RunService.Stepped:Connect(function()
    if Noclip and Character then
        for _, p in ipairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end
end)

-- Invisible
PlayerTab:AddToggle({
    Name = "Invisible",
    Default = false,
    Callback = function(v)
        Invisible = v
        if Character then
            for _, p in ipairs(Character:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    p.Transparency = v and 1 or 0
                end
            end
        end
    end
})

-- God Mode
PlayerTab:AddToggle({
    Name = "God Mode",
    Default = false,
    Callback = function(v)
        GodMode = v
    end
})

RunService.Heartbeat:Connect(function()
    if GodMode and Humanoid then
        Humanoid.Health = Humanoid.MaxHealth
    end
end)

------------------------------------------------
-- ESP
------------------------------------------------
local ESPEnabled = false
local TeamCheck = false
local ESPObjects = {}

local function ClearESP()
    for _, gui in pairs(ESPObjects) do
        if gui then gui:Destroy() end
    end
    ESPObjects = {}
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    if TeamCheck and player.Team == LocalPlayer.Team then return end
    if ESPObjects[player] then return end

    local function Attach(char)
        ClearESP()

        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not head or not hrp then return end

        local bill = Instance.new("BillboardGui")
        bill.Name = "ESP"
        bill.Adornee = head
        bill.Size = UDim2.fromOffset(200, 40)
        bill.StudsOffset = Vector3.new(0, 2.5, 0)
        bill.AlwaysOnTop = true
        bill.Parent = head

        local text = Instance.new("TextLabel")
        text.BackgroundTransparency = 1
        text.Size = UDim2.fromScale(1,1)
        text.TextColor3 = Color3.fromRGB(255, 80, 80)
        text.TextStrokeTransparency = 0
        text.Font = Enum.Font.SourceSansBold
        text.TextScaled = true
        text.Parent = bill

        ESPObjects[player] = bill

        RunService.Heartbeat:Connect(function()
            if not ESPEnabled or not char.Parent then
                if bill then bill:Destroy() end
                ESPObjects[player] = nil
                return
            end

            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            text.Text = string.format("%s [%.0f]", player.Name, dist)
        end)
    end

    if player.Character then
        Attach(player.Character)
    end

    player.CharacterAdded:Connect(Attach)
end

------------------------------------------------
-- ESP Tab
------------------------------------------------
local ESPTab = Window:MakeTab({
    Name = "ESP",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ESPTab:AddToggle({
    Name = "Enable ESP",
    Default = false,
    Callback = function(v)
        ESPEnabled = v
        ClearESP()

        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                CreateESP(p)
            end
        end
    end
})

ESPTab:AddToggle({
    Name = "Team Check",
    Default = false,
    Callback = function(v)
        TeamCheck = v
        if ESPEnabled then
            ClearESP()
            for _, p in ipairs(Players:GetPlayers()) do
                CreateESP(p)
            end
        end
    end
})

Players.PlayerAdded:Connect(function(p)
    if ESPEnabled then
        CreateESP(p)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if ESPObjects[p] then
        ESPObjects[p]:Destroy()
        ESPObjects[p] = nil
    end
end)

------------------------------------------------
-- Init
------------------------------------------------
OrionLib:Init()

OrionLib:MakeNotification({
    Name = "Loaded",
    Content = "Universal Orion Hub loaded successfully",
    Image = "rbxassetid://4483345998",
    Time = 5
})
