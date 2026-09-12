-- [[ CTSuteamz Mobile Script | UTeamz ]] --
print("CTSuteamz | t.me/UTeamz")

local Services = {
    RunService = game:GetService("RunService"),
    UserInput = game:GetService("UserInputService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

---------------------------------------------------------
-- CONFIG & STATE
---------------------------------------------------------
local ESP = {
    Enabled = true,
    TeamCheck = false,
    ShowDistance = true,
    EnableFill = true,
    EnableOutline = true,
    Instances = {},
    HullColor = Color3.fromRGB(46, 204, 113),
    TurretColor = Color3.fromRGB(52, 152, 219),
    FillTransparency = 0.5,
    OutlineTransparency = 0.2
}

local Mark = {
    Enabled = false,
    Distance = 1000,
    DecalID = "11552476728",
    OffsetY = 50,
    Size = 25,
    UpdateInterval = 0.016,
    TimeSinceUpdate = 0
}

local Timers = {
    VehicleScan = 0,
    Cleanup = 0,
    ScanInterval = 0.5,
    CleanupInterval = 2
}

local Fly = {
    Active = false,
    Speed = 70,
    Root = nil
}

-- Ð¡Ð¾ÑÑ‚Ð¾ÑÐ½Ð¸Ðµ Ð¼Ð¾Ð±Ð¸Ð»ÑŒÐ½Ñ‹Ñ… ÐºÐ½Ð¾Ð¿Ð¾Ðº Ð¿Ð¾Ð»ÐµÑ‚Ð°
local FlyInput = {
    Forward = false,
    Backward = false,
    Left = false,
    Right = false,
    Up = false,
    Down = false
}

local Other = {
    RemoveFog = false,
    PenView = false
}

local PenView = {
    UI = nil,
    HeartbeatConnection = nil,
    LastPart = nil,
    LastChassisName = nil,
    ArmorTypes = {
        "Structural Steel", "RHA", "HHRA", "CHA", "NERA", "Internal RHA", "Internal HHRA",
        "Internal CHA", "Composite Screen", "Rubber-fabric Screen", "Internal Aluminium",
        "Aluminium", "Aluminium Alloy", "Internal Aluminium Alloy", "Internal Structural Steel",
        "ERA", "Wood", "Armour"
    }
}

-- Ð“Ð»Ð¾Ð±Ð°Ð»ÑŒÐ½Ð°Ñ Ð¿ÐµÑ€ÐµÐ¼ÐµÐ½Ð½Ð°Ñ Ð´Ð»Ñ UI Ð´Ð¶Ð¾Ð¹ÑÑ‚Ð¸ÐºÐ°
local FlyUIFrame = nil

---------------------------------------------------------
-- FOLDERS & CONTAINERS
---------------------------------------------------------
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "CTSuteamz_ESP"
ESPFolder.Parent = Services.CoreGui

local MarkScreenGui = Instance.new("ScreenGui")
MarkScreenGui.Name = "CTSuteamz_Marks"
MarkScreenGui.ResetOnSpawn = false
MarkScreenGui.Parent = Services.CoreGui

---------------------------------------------------------
-- PENETRATION VIEW SYSTEM
---------------------------------------------------------
local function PenView_CreateUI()
    for _, v in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        if v.Name == "PenViewport" then v:Destroy() end
    end
    
    local sg = Instance.new("ScreenGui")
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = -100
    sg.Name = "PenViewport"
    sg.Parent = LocalPlayer.PlayerGui
    
    local vp = Instance.new("ViewportFrame", sg)
    vp.Size = UDim2.new(1, 0, 1, 0)
    vp.BackgroundTransparency = 1
    vp.ImageTransparency = 0.25
    vp.ZIndex = -100
    
    local cam = Instance.new("Camera")
    vp.CurrentCamera = cam
    cam.CameraType = Enum.CameraType.Scriptable
    
    return {viewport = vp, vpcam = cam}
end

local function PenView_GetPenetration()
    local vehicles = Services.Workspace:FindFirstChild("Vehicles")
    if not vehicles then return 200 end
    local chassis = vehicles:FindFirstChild("Chassis" .. LocalPlayer.Name)
    if not chassis then return 200 end
    local gunFolder = chassis:FindFirstChild("Gun")
    if not gunFolder then return 200 end
    
    for _, gunWeapon in ipairs(gunFolder:GetChildren()) do
        local config = gunWeapon:FindFirstChild("Config")
        if config then
            local shells = config:FindFirstChild("Shells")
            if shells then
                for _, folder in ipairs(shells:GetChildren()) do
                    local penVal = folder:FindFirstChild("Penetration")
                    if penVal then return penVal.Value end
                end
            end
        end
    end
    return 200
end
local function PenView_FindGunBrick(chassis)
    local gun = chassis:FindFirstChild("Gun", true)
    if not gun then return nil end
    for _, obj in ipairs(gun:GetDescendants()) do
        if obj.Name == "GunBrick" then return obj end
    end
    return nil
end

local function PenView_GetArmorThickness(hitPart, hitPos, direction, hitNormal)
    if not hitPart or not hitPos then return 0 end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Whitelist
    params.FilterDescendantsInstances = {hitPart}
    
    local result = Services.Workspace:Raycast(hitPos + direction * 4, -direction * 50, params)
    if result and result.Instance == hitPart then
        local thickness = (hitPos - result.Position).Magnitude / 0.00357
        if hitNormal then
            local cos = math.abs(hitNormal:Dot(-direction.Unit))
            thickness = thickness / math.max(cos, 0.05)
        end
        return thickness
    end
    return 0
end

local function PenView_UpdateViewport(ui, part, thickness, pen)
    if not ui or not ui.viewport or not ui.viewport.Parent then return end
    if not part or not part.Parent then
        if ui.viewport then ui.viewport:ClearAllChildren() end
        PenView.LastPart = nil
        return
    end
    
    local mesh = ui.viewport:FindFirstChildWhichIsA("BasePart")
    if PenView.LastPart ~= part or not mesh then
        PenView.LastPart = part
        ui.viewport:ClearAllChildren()
        local clone = part:Clone()
        clone.Transparency = 0.3
        clone.CanCollide = false
        clone.Anchored = true
        clone.Parent = ui.viewport
        mesh = clone
    end
    if not mesh then return end
    
    pcall(function() mesh.CFrame = part.CFrame end)
    ui.vpcam.CFrame = Services.Workspace.CurrentCamera.CFrame
    ui.vpcam.FieldOfView = Services.Workspace.CurrentCamera.FieldOfView
    
    local color
    if thickness <= 0.1 or pen <= 0 then
        color = Color3.fromRGB(90, 90, 90)
    elseif thickness <= pen * 0.5 then
        color = Color3.fromRGB(46, 204, 113)
    elseif thickness < pen then
        local t = (thickness - pen * 0.5) / (pen * 0.5)
        color = Color3.new(1, 1 - t, 0)
    else
        color = Color3.fromRGB(231, 76, 60)
    end
    mesh.Color = color
end

local function PenView_StartHeartbeat(ui)
    if PenView.HeartbeatConnection then PenView.HeartbeatConnection:Disconnect() end
    PenView.LastPart = nil
    
    PenView.HeartbeatConnection = Services.RunService.Heartbeat:Connect(function()
        if not ui or not ui.viewport or not ui.viewport.Parent then return end
        local vehicles = Services.Workspace:FindFirstChild("Vehicles")
        if not vehicles then
            if ui.viewport then ui.viewport:ClearAllChildren() end
            return
        end
        local chassis = vehicles:FindFirstChild("Chassis" .. LocalPlayer.Name)
        if not chassis then
            if ui.viewport then ui.viewport:ClearAllChildren() end
            PenView.LastPart = nil
            PenView.LastChassisName = nil
            return
        end
        
        if chassis.Name ~= PenView.LastChassisName then
            PenView.LastChassisName = chassis.Name
            PenView.LastPart = nil
        end
        
        local gunBrick = PenView_FindGunBrick(chassis)
        if not gunBrick then return end
        
        local pen = PenView_GetPenetration()
        local origin = gunBrick.Position + gunBrick.CFrame.LookVector * 2
        local dir = gunBrick.CFrame.LookVector
        
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = {chassis, Services.Workspace:FindFirstChild("Projectiles")}
        rayParams.IgnoreWater = true
        
        local result = Services.Workspace:Raycast(origin, dir * 3000, rayParams)
        if result and result.Instance and table.find(PenView.ArmorTypes, result.Instance.Name) and result.Instance.CanCollide then
            local thickness = PenView_GetArmorThickness(result.Instance, result.Position, dir, result.Normal)
            PenView_UpdateViewport(ui, result.Instance, thickness, pen)
        else
            if ui.viewport then ui.viewport:ClearAllChildren() end
            PenView.LastPart = nil
        end
    end)
end

local function TogglePenView(state)
    Other.PenView = state
    if state then
        PenView.UI = PenView_CreateUI()
        PenView_StartHeartbeat(PenView.UI)
    else
        if PenView.HeartbeatConnection then PenView.HeartbeatConnection:Disconnect() end
        if PenView.UI and PenView.UI.viewport and PenView.UI.viewport.Parent then
            PenView.UI.viewport.Parent:Destroy()
        end
        PenView.UI = nil
    end
end
---------------------------------------------------------
-- TANK FLY SYSTEM (ADAPTED FOR MOBILE)
---------------------------------------------------------
local bv = Instance.new("BodyVelocity")
bv.Name = "CTSuteamzFlyVelocity"
bv.MaxForce = Vector3.new(500000, 500000, 500000)

local bg = Instance.new("BodyGyro")
bg.Name = "CTSuteamzFlyGyro"
bg.MaxTorque = Vector3.new(500000, 500000, 500000)
bg.D = 120

local function findFlyPart(model)
    local candidates = {}
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and not part:IsA("VehicleSeat") then
            table.insert(candidates, part)
        end
    end
    for _, part in ipairs(candidates) do
        if part.Name:lower():find("hull") then return part end
    end
    if #candidates > 0 then
        table.sort(candidates, function(a, b)
            return (a.Size.X*a.Size.Y*a.Size.Z) > (b.Size.X*b.Size.Y*b.Size.Z)
        end)
        return candidates[1]
    end
    return nil
end

local function initFlyRoot()
    local vehicles = workspace:FindFirstChild("Vehicles")
    if vehicles then
        local tankModel = vehicles:FindFirstChild("Chassis" .. LocalPlayer.Name)
        if tankModel then
            Fly.Root = findFlyPart(tankModel)
            return
        end
    end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Fly.Root = LocalPlayer.Character.HumanoidRootPart
    end
end

local function startFly()
    if Fly.Active then return end
    initFlyRoot()
    Fly.Active = true
    if Fly.Root then
        bv.Parent = Fly.Root
        bg.Parent = Fly.Root
    end
    if FlyUIFrame then FlyUIFrame.Visible = true end -- ÐŸÐ¾ÐºÐ°Ð·Ñ‹Ð²Ð°ÐµÐ¼ Ð¼Ð¾Ð±Ð¸Ð»ÑŒÐ½Ñ‹Ðµ ÐºÐ½Ð¾Ð¿ÐºÐ¸ ÑƒÐ¿Ñ€Ð°Ð²Ð»ÐµÐ½Ð¸Ñ
end

local function stopFly()
    if not Fly.Active then return end
    Fly.Active = false
    bv.Parent = nil
    bg.Parent = nil
    
    -- Ð¡Ð±Ñ€Ð°ÑÑ‹Ð²Ð°ÐµÐ¼ Ð¸Ð½Ð¿ÑƒÑ‚Ñ‹
    for k, v in pairs(FlyInput) do FlyInput[k] = false end
    if FlyUIFrame then FlyUIFrame.Visible = false end -- Ð¡ÐºÑ€Ñ‹Ð²Ð°ÐµÐ¼ Ð¼Ð¾Ð±Ð¸Ð»ÑŒÐ½Ñ‹Ðµ ÐºÐ½Ð¾Ð¿ÐºÐ¸
end

---------------------------------------------------------
-- ESP & MARKERS
---------------------------------------------------------
local function GetModelPosition(model)
    if model:IsA("BasePart") then return model.Position end
    if model.PrimaryPart then return model.PrimaryPart.Position end
    local cf, _ = model:GetBoundingBox()
    return cf.Position
end

local function UpdateESPInstance(espData)
    if not espData.Instance then return end
    local color = espData.IsHull and ESP.HullColor or ESP.TurretColor
    espData.Color = color
    espData.Instance.FillColor = ESP.EnableFill and color or Color3.new(0,0,0)
    espData.Instance.FillTransparency = ESP.EnableFill and ESP.FillTransparency or 1
    espData.Instance.OutlineColor = ESP.EnableOutline and color or Color3.new(0,0,0)
    espData.Instance.OutlineTransparency = ESP.EnableOutline and ESP.OutlineTransparency or 1
    espData.Instance.Enabled = ESP.Enabled

    if espData.DistanceBillboard then
        espData.DistanceBillboard.Enabled = ESP.Enabled and ESP.ShowDistance and espData.IsHull
    end
end

local function UpdateAllESPInstances()
    for _, espData in pairs(ESP.Instances) do
        UpdateESPInstance(espData)
    end
end

local function ClearAllESP()
    for obj, espData in pairs(ESP.Instances) do
        if espData.Instance then espData.Instance:Destroy() end
        if espData.DistanceBillboard then espData.DistanceBillboard:Destroy() end
        if espData.MarkBillboard then espData.MarkBillboard:Destroy() end
    end
    ESP.Instances = {}
end

local function CreateESP(targetObject, color, isHull)
    if ESP.Instances[targetObject] then return ESP.Instances[targetObject] end
	local highlight = Instance.new("Highlight")
    highlight.FillColor = ESP.EnableFill and color or Color3.new(0,0,0)
    highlight.FillTransparency = ESP.EnableFill and ESP.FillTransparency or 1
    highlight.OutlineColor = ESP.EnableOutline and color or Color3.new(0,0,0)
    highlight.OutlineTransparency = ESP.EnableOutline and ESP.OutlineTransparency or 1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = targetObject
    highlight.Parent = ESPFolder
    
    local distanceBillboard, distanceLabel, markBillboard, turretAdornee
    
    if isHull then
        distanceBillboard = Instance.new("BillboardGui")
        distanceBillboard.Name = "DistanceDisplay"
        distanceBillboard.Adornee = targetObject
        distanceBillboard.Size = UDim2.new(0,200,0,50)
        distanceBillboard.StudsOffset = Vector3.new(0,-3,0)
        distanceBillboard.AlwaysOnTop = true
        distanceBillboard.Enabled = ESP.Enabled and ESP.ShowDistance
        distanceBillboard.Parent = ESPFolder
        
        distanceLabel = Instance.new("TextLabel")
        distanceLabel.Name = "DistanceText"
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Size = UDim2.new(1,0,1,0)
        distanceLabel.Font = Enum.Font.SourceSansBold
        distanceLabel.TextSize = 18
        distanceLabel.TextColor3 = color
        distanceLabel.TextStrokeTransparency = 0
        distanceLabel.TextStrokeColor3 = Color3.new(0,0,0)
        distanceLabel.Text = "0 m"
        distanceLabel.Parent = distanceBillboard
        
        local chassis = targetObject.Parent and targetObject.Parent.Parent
        if chassis then
            local turret = chassis:FindFirstChild("Turret")
            if turret then
                for _, obj in ipairs(turret:GetChildren()) do
                    if obj:IsA("Model") then turretAdornee = obj break end
                end
            end
        end
        
        markBillboard = Instance.new("Frame")
        markBillboard.Name = "MarkDisplay"
        markBillboard.Size = UDim2.new(0, Mark.Size, 0, Mark.Size)
        markBillboard.Position = UDim2.new(0,0,0,0)
        markBillboard.BackgroundTransparency = 1
        markBillboard.Visible = false
        markBillboard.Parent = MarkScreenGui
        
        local img = Instance.new("ImageLabel")
        img.Name = "MarkImage"
        img.BackgroundTransparency = 1
        img.Size = UDim2.new(1,0,1,0)
        img.Image = "rbxassetid://" .. tostring(Mark.DecalID)
        img.Parent = markBillboard
    end
    
    ESP.Instances[targetObject] = {
        Instance = highlight,
        DistanceLabel = distanceLabel,
        DistanceBillboard = distanceBillboard,
        MarkBillboard = markBillboard,
        TurretAdornee = turretAdornee,
        Target = targetObject,
        Color = color,
        IsHull = isHull,
    }
    return ESP.Instances[targetObject]
end

local function ProcessChassis(chassis)
    if not chassis:IsA("Model") or not chassis.Name:match("^Chassis") then return end
    local playerName = chassis.Name:match("^Chassis(.+)$")
    if not playerName or playerName == "" or playerName == LocalPlayer.Name then return end
    
    if ESP.TeamCheck then
        local targetPlayer = Services.Players:FindFirstChild(playerName)
        if targetPlayer and LocalPlayer.Team and targetPlayer.Team and LocalPlayer.Team == targetPlayer.Team then
            return
        end
    end
    
    local hull = chassis:FindFirstChild("Hull")
    if hull then
        for _, obj in ipairs(hull:GetChildren()) do
            if obj:IsA("Model") then CreateESP(obj, ESP.HullColor, true) break end
        end
    end
    local turret = chassis:FindFirstChild("Turret")
    if turret then
        for _, obj in ipairs(turret:GetChildren()) do
            if obj:IsA("Model") then CreateESP(obj, ESP.TurretColor, false) break end
        end
    end
end

local function ScanVehicles()
    local vehiclesFolder = workspace:FindFirstChild("Vehicles")
    if not vehiclesFolder then return end
    for _, chassis in ipairs(vehiclesFolder:GetChildren()) do
        ProcessChassis(chassis)
    end
end

local function UpdateMarkPositions()
    if not Camera or not Mark.Enabled then return end
    local camPos = Camera.CFrame.Position
    local vpSize = Camera.ViewportSize
    
    for _, espData in pairs(ESP.Instances) do
        if espData.MarkBillboard and espData.IsHull then
            local target = espData.TurretAdornee or espData.Target
            if target and target.Parent then
                local ok, pos = pcall(GetModelPosition, target)
                if not ok then pos = espData.Target.Position end
                if (pos - camPos).Magnitude >= Mark.Distance then
                    local sp, onScreen = Camera:WorldToViewportPoint(pos)
                    if onScreen and sp.Z > 0 then
                        local x = math.clamp(sp.X - Mark.Size/2, 0, vpSize.X - Mark.Size)
                        local y = math.clamp(sp.Y - Mark.OffsetY - Mark.Size/2, 0, vpSize.Y - Mark.Size)
                        espData.MarkBillboard.Position = UDim2.new(0, x, 0, y)
                        espData.MarkBillboard.Visible = true
                    else
                        espData.MarkBillboard.Visible = false
                    end
                else
                    espData.MarkBillboard.Visible = false
                end
            else
                espData.MarkBillboard.Visible = false
            end
        end
    end
end

local function UpdateDistanceLabels()
    if not Camera then return end
    local camPos = Camera.CFrame.Position
    for _, espData in pairs(ESP.Instances) do
        if espData.IsHull and espData.DistanceLabel and espData.Target and espData.Target.Parent then
            local ok, pos = pcall(GetModelPosition, espData.Target)
            if ok then
                local dist = math.floor((pos - camPos).Magnitude / 3)
                espData.DistanceLabel.Text = dist .. " m"
            end
        end
    end
end

local function CleanupESP()
    local toRemove = {}
    for obj, espData in pairs(ESP.Instances) do
        if not obj or not obj.Parent then
            table.insert(toRemove, obj)
            if espData.Instance then espData.Instance:Destroy() end
            if espData.DistanceBillboard then espData.DistanceBillboard:Destroy() end
            if espData.MarkBillboard then espData.MarkBillboard:Destroy() end
        end
    end
    for _, obj in ipairs(toRemove) do ESP.Instances[obj] = nil end
end
---------------------------------------------------------
-- LOOPS & EVENTS
---------------------------------------------------------
Services.RunService.Heartbeat:Connect(function(dt)
    Timers.VehicleScan += dt
    if Timers.VehicleScan >= Timers.ScanInterval then
        Timers.VehicleScan = 0
        ScanVehicles()
    end
    
    Timers.Cleanup += dt
    if Timers.Cleanup >= Timers.CleanupInterval then
        Timers.Cleanup = 0
        CleanupESP()
    end
    
    UpdateDistanceLabels()
end)

Services.RunService.RenderStepped:Connect(function(dt)
    Mark.TimeSinceUpdate += dt
    if Mark.TimeSinceUpdate >= Mark.UpdateInterval then
        Mark.TimeSinceUpdate = 0
        UpdateMarkPositions()
    end
    
    if Fly.Active and Fly.Root and Fly.Root.Parent then
        local cam = Services.Workspace.CurrentCamera
        local move = Vector3.zero
        
        -- ÐšÐ¾Ð¼Ð±Ð¸Ð½Ð¸Ñ€Ð¾Ð²Ð°Ð½Ð½Ð¾Ðµ ÑƒÐ¿Ñ€Ð°Ð²Ð»ÐµÐ½Ð¸Ðµ (ÐšÐ»Ð°Ð²Ð¸Ð°Ñ‚ÑƒÑ€Ð° + ÐœÐ¾Ð±Ð¸Ð»ÑŒÐ½Ñ‹Ðµ ÐºÐ½Ð¾Ð¿ÐºÐ¸ UI)
        if Services.UserInput:IsKeyDown(Enum.KeyCode.W) or FlyInput.Forward then move += cam.CFrame.LookVector end
        if Services.UserInput:IsKeyDown(Enum.KeyCode.S) or FlyInput.Backward then move -= cam.CFrame.LookVector end
        if Services.UserInput:IsKeyDown(Enum.KeyCode.A) or FlyInput.Left then move -= cam.CFrame.RightVector end
        if Services.UserInput:IsKeyDown(Enum.KeyCode.D) or FlyInput.Right then move += cam.CFrame.RightVector end
        if Services.UserInput:IsKeyDown(Enum.KeyCode.Space) or FlyInput.Up then move += Vector3.new(0,1,0) end
        if Services.UserInput:IsKeyDown(Enum.KeyCode.LeftControl) or FlyInput.Down then move -= Vector3.new(0,1,0) end
        
        bv.Velocity = move.Magnitude > 0 and move.Unit * Fly.Speed or Vector3.zero
        bg.CFrame = cam.CFrame
    end
end)

---------------------------------------------------------
-- GREEN MOBILE UI LIBRARY & FLY D-PAD
---------------------------------------------------------
local Library = {}
Library.__index = Library

local themes = {
    Background = Color3.fromRGB(20, 26, 22),
    Accent = Color3.fromRGB(46, 204, 113),
    DarkContrast = Color3.fromRGB(14, 18, 15),
    LightContrast = Color3.fromRGB(28, 36, 30),
    TextColor = Color3.fromRGB(255, 255, 255)
}

function Library.new(title)
    for _, old in ipairs(Services.CoreGui:GetChildren()) do
        if old.Name == "CTSuteamz_UI" then old:Destroy() end
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "CTSuteamz_UI"
    sg.ResetOnSpawn = false
    sg.Parent = Services.CoreGui
    
    -- ====================================================
    -- Ð¡ÐžÐ—Ð”ÐÐÐ˜Ð• D-PAD Ð”Ð›Ð¯ ÐŸÐžÐ›ÐÐ¢Ð (ÐœÐ¾Ð±Ð¸Ð»ÑŒÐ½Ð¾Ðµ ÑƒÐ¿Ñ€Ð°Ð²Ð»ÐµÐ½Ð¸Ðµ)
    -- ====================================================
    FlyUIFrame = Instance.new("Frame")
    FlyUIFrame.Name = "FlyMobileControls"
    FlyUIFrame.Size = UDim2.new(0, 180, 0, 180)
    FlyUIFrame.Position = UDim2.new(1, -210, 1, -210) -- ÐŸÑ€Ð°Ð²Ñ‹Ð¹ Ð½Ð¸Ð¶Ð½Ð¸Ð¹ ÑƒÐ³Ð¾Ð»
    FlyUIFrame.BackgroundTransparency = 1
    FlyUIFrame.Visible = false
    FlyUIFrame.Parent = sg

    local function createFlyBtn(name, text, pos)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 50, 0, 50)
        btn.Position = pos
        btn.BackgroundColor3 = themes.Background
        btn.BorderColor3 = themes.Accent
        btn.BorderSizePixel = 2
        btn.Text = text
        btn.TextColor3 = themes.Accent
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 18
        btn.Parent = FlyUIFrame
        
        local cr = Instance.new("UICorner")
        cr.CornerRadius = UDim.new(0, 8)
        cr.Parent = btn

        -- Ð›Ð¾Ð³Ð¸ÐºÐ° Ð½Ð°Ð¶Ð°Ñ‚Ð¸Ð¹ Ð´Ð»Ñ Ð¼Ð¾Ð±Ð¸Ð»Ð¾Ðº
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                FlyInput[name] = true
                btn.BackgroundColor3 = themes.Accent
                btn.TextColor3 = Color3.fromRGB(0,0,0)
            end
        end)
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                FlyInput[name] = false
                btn.BackgroundColor3 = themes.Background
                btn.TextColor3 = themes.Accent
            end
        end)
    end

    -- Ð Ð°ÑÑÑ‚Ð°Ð½Ð¾Ð²ÐºÐ° ÐºÐ½Ð¾Ð¿Ð¾Ðº 3x3
    createFlyBtn("Forward", "^", UDim2.new(0, 65, 0, 5))
    createFlyBtn("Backward", "v", UDim2.new(0, 65, 0, 125))
    createFlyBtn("Left", "<", UDim2.new(0, 5, 0, 65))
    createFlyBtn("Right", ">", UDim2.new(0, 125, 0, 65))
    createFlyBtn("Up", "UP", UDim2.new(0, 125, 0, 5))
    createFlyBtn("Down", "DN", UDim2.new(0, 5, 0, 125))
    -- ====================================================

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0.85, 0, 0.75, 0)
    main.Position = UDim2.new(0.075, 0, 0.125, 0)
    main.BackgroundColor3 = themes.Background
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = sg
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = main
    
    local topbar = Instance.new("Frame")
    topbar.Name = "TopBar"
    topbar.Size = UDim2.new(1, 0, 0, 40)
    topbar.BackgroundColor3 = themes.DarkContrast
    topbar.Parent = main
    
    local topTitle = Instance.new("TextLabel")
    topTitle.Size = UDim2.new(1, -15, 1, 0)
    topTitle.Position = UDim2.new(0, 12, 0, 0)
    topTitle.Font = Enum.Font.GothamBold
    topTitle.Text = title
    topTitle.TextColor3 = themes.Accent
    topTitle.TextSize = 15
    topTitle.TextXAlignment = Enum.TextXAlignment.Left
    topTitle.BackgroundTransparency = 1
    topTitle.Parent = topbar
    
    -- ÐŸÐ»Ð°Ð²Ð°ÑŽÑ‰Ð°Ñ ÐºÐ½Ð¾Ð¿ÐºÐ° Ð´Ð»Ñ Ð¼Ð¾Ð±Ð¸Ð»Ð¾Ðº
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "CTSuteamz_ToggleButton"
    toggleBtn.Size = UDim2.new(0, 75, 0, 35)
    toggleBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
    toggleBtn.BackgroundColor3 = themes.Accent
    toggleBtn.Text = "CTSuteamz"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 12
    toggleBtn.TextColor3 = Color3.fromRGB(0,0,0)
    toggleBtn.Parent = sg
	
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = toggleBtn
    
    -- Ð”Ñ€Ð°Ð³ Ð¿Ð»Ð°Ð²Ð°ÑŽÑ‰ÐµÐ¹ ÐºÐ½Ð¾Ð¿ÐºÐ¸
    local dragging, dragInput, dragStart, startPos
    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = toggleBtn.Position
        end
    end)
    
    toggleBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    Services.UserInput.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    Services.UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    toggleBtn.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)
    
    local tabHolder = Instance.new("ScrollingFrame")
    tabHolder.Size = UDim2.new(0.28, 0, 1, -40)
    tabHolder.Position = UDim2.new(0, 0, 0, 40)
    tabHolder.BackgroundColor3 = themes.DarkContrast
    tabHolder.BorderSizePixel = 0
    tabHolder.ScrollBarThickness = 2
    tabHolder.Parent = main
    
    local tabList = Instance.new("UIListLayout")
    tabList.Padding = UDim.new(0, 4)
    tabList.Parent = tabHolder
    
    local pageHolder = Instance.new("Frame")
    pageHolder.Size = UDim2.new(0.72, -10, 1, -50)
    pageHolder.Position = UDim2.new(0.28, 5, 0, 45)
    pageHolder.BackgroundTransparency = 1
    pageHolder.Parent = main

    return setmetatable({
        ScreenGui = sg,
        Main = main,
        TabHolder = tabHolder,
        PageHolder = pageHolder,
        Pages = {}
    }, Library)
end

function Library:AddTab(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, -6, 0, 36)
    tabBtn.Position = UDim2.new(0, 3, 0, 0)
    tabBtn.BackgroundColor3 = themes.LightContrast
    tabBtn.Font = Enum.Font.GothamMedium
    tabBtn.Text = name
    tabBtn.TextColor3 = themes.TextColor
    tabBtn.TextSize = 12
    tabBtn.Parent = self.TabHolder
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = tabBtn
    
    local pageScroll = Instance.new("ScrollingFrame")
    pageScroll.Size = UDim2.new(1, 0, 1, 0)
    pageScroll.BackgroundTransparency = 1
    pageScroll.ScrollBarThickness = 3
    pageScroll.Visible = false
    pageScroll.Parent = self.PageHolder
    
    local pageList = Instance.new("UIListLayout")
    pageList.Padding = UDim.new(0, 6)
    pageList.Parent = pageScroll
    
    pageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        pageScroll.CanvasSize = UDim2.new(0, 0, 0, pageList.AbsoluteContentSize.Y + 10)
    end)

    local tabObj = {Button = tabBtn, Page = pageScroll}
    
    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(self.Pages) do
            t.Page.Visible = false
            t.Button.BackgroundColor3 = themes.LightContrast
            t.Button.TextColor3 = themes.TextColor
        end
        pageScroll.Visible = true
        tabBtn.BackgroundColor3 = themes.Accent
        tabBtn.TextColor3 = Color3.fromRGB(0,0,0)
    end)
    
    if #self.Pages == 0 then
        pageScroll.Visible = true
        tabBtn.BackgroundColor3 = themes.Accent
        tabBtn.TextColor3 = Color3.fromRGB(0,0,0)
    end
    
    table.insert(self.Pages, tabObj)
    
    local TabMethods = {}
    
    function TabMethods:AddToggle(text, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -6, 0, 40)
        frame.BackgroundColor3 = themes.LightContrast
        frame.Parent = pageScroll
        
        local cr = Instance.new("UICorner")
        cr.CornerRadius = UDim.new(0, 6)
        cr.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.Text = text
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextColor3 = themes.TextColor
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.BackgroundTransparency = 1
        label.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 48, 0, 24)
        btn.Position = UDim2.new(1, -55, 0.5, -12)
        btn.BackgroundColor3 = default and themes.Accent or themes.DarkContrast
        btn.Text = default and "ON" or "OFF"
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.TextColor3 = default and Color3.fromRGB(0,0,0) or themes.TextColor
        btn.Parent = frame
        
        local btnCr = Instance.new("UICorner")
        btnCr.CornerRadius = UDim.new(0, 12)
        btnCr.Parent = btn
        
        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.BackgroundColor3 = state and themes.Accent or themes.DarkContrast
            btn.Text = state and "ON" or "OFF"
            btn.TextColor3 = state and Color3.fromRGB(0,0,0) or themes.TextColor
            if callback then callback(state) end
        end)
	end
	
    function TabMethods:AddSlider(text, min, max, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -6, 0, 50)
        frame.BackgroundColor3 = themes.LightContrast
        frame.Parent = pageScroll
        
        local cr = Instance.new("UICorner")
        cr.CornerRadius = UDim.new(0, 6)
        cr.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 20)
        label.Position = UDim2.new(0, 10, 0, 4)
        label.Text = text .. ": " .. tostring(default)
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextColor3 = themes.TextColor
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.BackgroundTransparency = 1
        label.Parent = frame
        
        local sliderBack = Instance.new("TextButton")
        sliderBack.Size = UDim2.new(1, -20, 0, 10)
        sliderBack.Position = UDim2.new(0, 10, 0, 30)
        sliderBack.BackgroundColor3 = themes.DarkContrast
        sliderBack.Text = ""
        sliderBack.AutoButtonColor = false
        sliderBack.Parent = frame
        
        local sbCr = Instance.new("UICorner")
        sbCr.CornerRadius = UDim.new(0, 5)
        sbCr.Parent = sliderBack
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(math.clamp((default - min)/(max - min), 0, 1), 0, 1, 0)
        fill.BackgroundColor3 = themes.Accent
        fill.BorderSizePixel = 0
        fill.Parent = sliderBack
        
        local fillCr = Instance.new("UICorner")
        fillCr.CornerRadius = UDim.new(0, 5)
        fillCr.Parent = fill
        
        local isSliding = false
        local function update(input)
            local pos = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * pos)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            label.Text = text .. ": " .. tostring(val)
            if callback then callback(val) end
        end
        
        sliderBack.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                isSliding = true
                update(input)
            end
        end)
        
        Services.UserInput.InputChanged:Connect(function(input)
            if isSliding and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                update(input)
            end
        end)
        
        Services.UserInput.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                isSliding = false
            end
        end)
    end
    
    function TabMethods:AddButton(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 36)
        btn.BackgroundColor3 = themes.LightContrast
        btn.Font = Enum.Font.GothamMedium
        btn.Text = text
        btn.TextColor3 = themes.TextColor
        btn.TextSize = 12
        btn.Parent = pageScroll
        
        local cr = Instance.new("UICorner")
        cr.CornerRadius = UDim.new(0, 6)
        cr.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            if callback then callback() end
        end)
    end

    return TabMethods
end

---------------------------------------------------------
-- UI INTERFACE BUILD
---------------------------------------------------------
local win = Library.new("CTSuteamz | t.me/UTeamz")

-- Ð¢Ð°Ð± 1: ESP
local espTab = win:AddTab("ESP")
espTab:AddToggle("Enable ESP", ESP.Enabled, function(v)
    ESP.Enabled = v
    UpdateAllESPInstances()
end)
espTab:AddToggle("Team Check", ESP.TeamCheck, function(v)
    ESP.TeamCheck = v
    ClearAllESP()
    ScanVehicles()
end)
espTab:AddToggle("Show Distance", ESP.ShowDistance, function(v)
    ESP.ShowDistance = v
    UpdateAllESPInstances()
end)
espTab:AddToggle("Enable Fill", ESP.EnableFill, function(v)
    ESP.EnableFill = v
    UpdateAllESPInstances()
end)
espTab:AddToggle("Enable Outline", ESP.EnableOutline, function(v)
    ESP.EnableOutline = v
    UpdateAllESPInstances()
end)

-- Ð¢Ð°Ð± 2: Mark System
local markTab = win:AddTab("Marks")
markTab:AddToggle("Enable Mark", Mark.Enabled, function(v)
    Mark.Enabled = v
    if not v then
        for _, espData in pairs(ESP.Instances) do
            if espData.MarkBillboard then espData.MarkBillboard.Visible = false end
        end
    end
end)
markTab:AddSlider("Mark Distance", 100, 5000, Mark.Distance, function(v) Mark.Distance = v end)
markTab:AddSlider("Mark Offset Y", 0, 200, Mark.OffsetY, function(v) Mark.OffsetY = v end)
markTab:AddSlider("Mark Size", 5, 50, Mark.Size, function(v)
    Mark.Size = v
    for _, espData in pairs(ESP.Instances) do
        if espData.MarkBillboard then
            espData.MarkBillboard.Size = UDim2.new(0, v, 0, v)
        end
    end
end)

-- Ð¢Ð°Ð± 3: Visuals
local visTab = win:AddTab("Visuals")
visTab:AddToggle("Penetration View", Other.PenView, function(v) TogglePenView(v) end)
visTab:AddToggle("Remove Fog", Other.RemoveFog, function(v)
    Other.RemoveFog = v
    for _, child in ipairs(Services.Lighting:GetChildren()) do
        if child:IsA("Atmosphere") then
            child.Density = v and 0 or 0.3
            child.Haze = v and 0 or 0.1
        end
    end
end)

-- Ð¢Ð°Ð± 4: Fly (ÐžÐ±Ð½Ð¾Ð²Ð»ÐµÐ½Ð¾)
local flyTab = win:AddTab("Fly")
flyTab:AddToggle("Enable Fly", Fly.Active, function(v)
    if v then startFly() else stopFly() end
end)
flyTab:AddSlider("Fly Speed", 10, 300, Fly.Speed, function(v) Fly.Speed = v end)

-- Ð¢Ð°Ð± 5: Info
local infoTab = win:AddTab("Info")
infoTab:AddButton("Copy Telegram Link", function()
    setclipboard("https://t.me/UTeamz")
end)

ScanVehicles()
