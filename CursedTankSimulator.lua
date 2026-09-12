-- [[ UNIFIED MOBILE SCRIPT: CTS / VENOM MOD ]]

local Services = {
	RunService = game:GetService("RunService"),
	UserInput = game:GetService("UserInputService"),
	Players = game:GetService("Players"),
	CoreGui = game:GetService("CoreGui"),
	Workspace = game:GetService("Workspace"),
	Lighting = game:GetService("Lighting"),
	TweenService = game:GetService("TweenService"),
	TextService = game:GetService("TextService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

---------------------------------------------------------
-- CONFIG & STATE
---------------------------------------------------------
local ESP = {
	Enabled = false,
	TeamCheck = false,
	ShowDistance = false,
	EnableFill = true,
	EnableOutline = true,
	Instances = {},
	HullColor = Color3.new(0.8, 0.2, 0.9),
	TurretColor = Color3.new(0.2, 0.9, 0.4),
	FillTransparency = 0.5,
	OutlineTransparency = 0.2
}

local Fly = {
	Active = false,
	Speed = 70,
	Root = nil
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
		color = Color3.fromRGB(0, 255, 0)
	elseif thickness < pen then
		local t = (thickness - pen * 0.5) / (pen * 0.5)
		color = Color3.new(1, 1 - t, 0)
	else
		color = Color3.fromRGB(255, 0, 0)
	end
	mesh.Color = color
end
local function PenView_StartHeartbeat(ui)
	if PenView.HeartbeatConnection then PenView.HeartbeatConnection:Disconnect() end
	PenView.LastPart = nil
	
	PenView.HeartbeatConnection = Services.RunService.Heartbeat:Connect(function()
		if not Other.PenView or not ui or not ui.viewport or not ui.viewport.Parent then return end
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
-- ESP & UTILITY FUNCTIONS
---------------------------------------------------------
local function CreateHighlight(parent, color)
	local hl = Instance.new("Highlight")
	hl.Adornee = parent
	hl.FillColor = color
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency = ESP.FillTransparency
	hl.OutlineTransparency = ESP.OutlineTransparency
	hl.Enabled = ESP.Enabled
	hl.Parent = parent
	return hl
end

local function UpdateESP()
	if not ESP.Enabled then
		for _, v in pairs(ESP.Instances) do
			if v.Hull then v.Hull.Enabled = false end
			if v.Turret then v.Turret.Enabled = false end
		end
		return
	end
	
	local vehicles = Services.Workspace:FindFirstChild("Vehicles")
	if not vehicles then return end
	
	for _, vehicle in ipairs(vehicles:GetChildren()) do
		if vehicle:IsA("Model") and not vehicle.Name:find(LocalPlayer.Name) then
			if not ESP.Instances[vehicle] then
				ESP.Instances[vehicle] = {}
			end
			
			local hull = vehicle:FindFirstChild("Hull")
			if hull and not ESP.Instances[vehicle].Hull then
				ESP.Instances[vehicle].Hull = CreateHighlight(hull, ESP.HullColor)
			end
			
			local turret = vehicle:FindFirstChild("Turret")
			if turret and not ESP.Instances[vehicle].Turret then
				ESP.Instances[vehicle].Turret = CreateHighlight(turret, ESP.TurretColor)
			end
			
			if ESP.Instances[vehicle].Hull then
				ESP.Instances[vehicle].Hull.Enabled = ESP.EnableFill or ESP.EnableOutline
				ESP.Instances[vehicle].Hull.FillTransparency = ESP.EnableFill and ESP.FillTransparency or 1
				ESP.Instances[vehicle].Hull.OutlineTransparency = ESP.EnableOutline and ESP.OutlineTransparency or 1
			end
			if ESP.Instances[vehicle].Turret then
				ESP.Instances[vehicle].Turret.Enabled = ESP.EnableFill or ESP.EnableOutline
				ESP.Instances[vehicle].Turret.FillTransparency = ESP.EnableFill and ESP.FillTransparency or 1
				ESP.Instances[vehicle].Turret.OutlineTransparency = ESP.EnableOutline and ESP.OutlineTransparency or 1
			end
		end
	end
end

Services.RunService.Heartbeat:Connect(function()
	UpdateESP()
	
	-- Fly Execution
	if Fly.Active then
		local char = LocalPlayer.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local root = char.HumanoidRootPart
			local camCF = Camera.CFrame
			local moveDir = Vector3.new()
			
			if Services.UserInput:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
			if Services.UserInput:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
			if Services.UserInput:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
			if Services.UserInput:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
			if Services.UserInput:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
			if Services.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
			
			if moveDir.Magnitude > 0 then
				root.Velocity = moveDir.Unit * Fly.Speed
			else
				root.Velocity = Vector3.new(0, 0, 0)
			end
		end
	end
end)
---------------------------------------------------------
-- MOBILE UI LIBRARY (TOUCH & SCALING OPTIMIZED)
---------------------------------------------------------
local Library = {}
Library.__index = Library

local themes = {
	Background = Color3.fromRGB(25, 25, 30),
	Accent = Color3.fromRGB(45, 120, 240),
	DarkContrast = Color3.fromRGB(18, 18, 22),
	LightContrast = Color3.fromRGB(35, 35, 42),
	TextColor = Color3.fromRGB(255, 255, 255)
}

function Library.new(title)
	local sg = Instance.new("ScreenGui")
	sg.Name = title
	sg.ResetOnSpawn = false
	sg.Parent = Services.CoreGui
	
	-- Main Frame
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(0.85, 0, 0.75, 0)
	main.Position = UDim2.new(0.075, 0, 0.125, 0)
	main.BackgroundColor3 = themes.Background
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Parent = sg
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = main
	
	-- TopBar
	local topbar = Instance.new("Frame")
	topbar.Name = "TopBar"
	topbar.Size = UDim2.new(1, 0, 0, 45)
	topbar.BackgroundColor3 = themes.DarkContrast
	topbar.Parent = main
	
	local topTitle = Instance.new("TextLabel")
	topTitle.Size = UDim2.new(1, -50, 1, 0)
	topTitle.Position = UDim2.new(0, 15, 0, 0)
	topTitle.Font = Enum.Font.GothamBold
	topTitle.Text = title
	topTitle.TextColor3 = themes.TextColor
	topTitle.TextSize = 16
	topTitle.TextXAlignment = Enum.TextXAlignment.Left
	topTitle.BackgroundTransparency = 1
	topTitle.Parent = topbar
	
	-- Mobile Toggle Floating Button
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "MobileToggleBtn"
	toggleBtn.Size = UDim2.new(0, 50, 0, 50)
	toggleBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
	toggleBtn.BackgroundColor3 = themes.Accent
	toggleBtn.Text = "MOD"
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.TextSize = 14
	toggleBtn.TextColor3 = themes.TextColor
	toggleBtn.Parent = sg
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(1, 0)
	btnCorner.Parent = toggleBtn
	
	-- Make Floating Button Draggable (Touch friendly)
	local dragging, dragInput, dragStart, startPos
	toggleBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = toggleBtn.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
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
	
	toggleBtn.MouseButton1Click:Connect(function()
		main.Visible = not main.Visible
	end)
	
	-- Tab Buttons Holder
	local tabHolder = Instance.new("ScrollingFrame")
	tabHolder.Size = UDim2.new(0.3, 0, 1, -45)
	tabHolder.Position = UDim2.new(0, 0, 0, 45)
	tabHolder.BackgroundColor3 = themes.DarkContrast
	tabHolder.BorderSizePixel = 0
	tabHolder.ScrollBarThickness = 2
	tabHolder.Parent = main
	
	local tabList = Instance.new("UIListLayout")
	tabList.Padding = UDim.new(0, 5)
	tabList.Parent = tabHolder
	
	-- Content Pages Holder
	local pageHolder = Instance.new("Frame")
	pageHolder.Size = UDim2.new(0.7, -10, 1, -55)
	pageHolder.Position = UDim2.new(0.3, 5, 0, 50)
	pageHolder.BackgroundTransparency = 1
	pageHolder.Parent = main

	local self = setmetatable({
		ScreenGui = sg,
		Main = main,
		TabHolder = tabHolder,
		PageHolder = pageHolder,
		Pages = {},
		ActivePage = nil
	}, Library)
	
	return self
end
function Library:AddTab(name)
	local tabBtn = Instance.new("TextButton")
	tabBtn.Size = UDim2.new(1, -10, 0, 40)
	tabBtn.Position = UDim2.new(0, 5, 0, 0)
	tabBtn.BackgroundColor3 = themes.LightContrast
	tabBtn.Font = Enum.Font.GothamMedium
	tabBtn.Text = name
	tabBtn.TextColor3 = themes.TextColor
	tabBtn.TextSize = 13
	tabBtn.Parent = self.TabHolder
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = tabBtn
	
	local pageScroll = Instance.new("ScrollingFrame")
	pageScroll.Size = UDim2.new(1, 0, 1, 0)
	pageScroll.BackgroundTransparency = 1
	pageScroll.ScrollBarThickness = 4
	pageScroll.Visible = false
	pageScroll.Parent = self.PageHolder
	
	local pageList = Instance.new("UIListLayout")
	pageList.Padding = UDim.new(0, 8)
	pageList.Parent = pageScroll
	
	pageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		pageScroll.CanvasSize = UDim2.new(0, 0, 0, pageList.AbsoluteContentSize.Y + 10)
	end)

	local tabObj = {
		Button = tabBtn,
		Page = pageScroll
	}
	
	tabBtn.MouseButton1Click:Connect(function()
		for _, t in pairs(self.Pages) do
			t.Page.Visible = false
			t.Button.BackgroundColor3 = themes.LightContrast
		end
		pageScroll.Visible = true
		tabBtn.BackgroundColor3 = themes.Accent
		self.ActivePage = tabObj
	end)
	
	if #self.Pages == 0 then
		pageScroll.Visible = true
		tabBtn.BackgroundColor3 = themes.Accent
		self.ActivePage = tabObj
	end
	
	table.insert(self.Pages, tabObj)
	
	local TabMethods = {}
	
	function TabMethods:AddToggle(text, default, callback)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, -8, 0, 45)
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
		label.TextSize = 13
		label.TextColor3 = themes.TextColor
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1
		label.Parent = frame
		
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 50, 0, 26)
		btn.Position = UDim2.new(1, -60, 0.5, -13)
		btn.BackgroundColor3 = default and themes.Accent or themes.DarkContrast
		btn.Text = default and "ON" or "OFF"
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.TextColor3 = themes.TextColor
		btn.Parent = frame
		
		local btnCr = Instance.new("UICorner")
		btnCr.CornerRadius = UDim.new(0, 13)
		btnCr.Parent = btn
		
		local state = default
		btn.MouseButton1Click:Connect(function()
			state = not state
			btn.BackgroundColor3 = state and themes.Accent or themes.DarkContrast
			btn.Text = state and "ON" or "OFF"
			if callback then callback(state) end
		end)
	end

	function TabMethods:AddSlider(text, min, max, default, callback)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, -8, 0, 55)
		frame.BackgroundColor3 = themes.LightContrast
		frame.Parent = pageScroll
		
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(0, 6)
		cr.Parent = frame
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -20, 0, 20)
		label.Position = UDim2.new(0, 10, 0, 5)
		label.Text = text .. ": " .. tostring(default)
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextColor3 = themes.TextColor
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1
		label.Parent = frame
		
		local sliderBack = Instance.new("TextButton")
		sliderBack.Size = UDim2.new(1, -20, 0, 12)
		sliderBack.Position = UDim2.new(0, 10, 0, 32)
		sliderBack.BackgroundColor3 = themes.DarkContrast
		sliderBack.Text = ""
		sliderBack.AutoButtonColor = false
		sliderBack.Parent = frame
		
		local sbCr = Instance.new("UICorner")
		sbCr.CornerRadius = UDim.new(0, 6)
		sbCr.Parent = sliderBack
		
		local fill = Instance.new("Frame")
		fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
		fill.BackgroundColor3 = themes.Accent
		fill.BorderSizePixel = 0
		fill.Parent = sliderBack
		
		local fillCr = Instance.new("UICorner")
		fillCr.CornerRadius = UDim.new(0, 6)
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
		btn.Size = UDim2.new(1, -8, 0, 40)
		btn.BackgroundColor3 = themes.LightContrast
		btn.Font = Enum.Font.GothamMedium
		btn.Text = text
		btn.TextColor3 = themes.TextColor
		btn.TextSize = 13
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
-- UI BUILD SETUP
---------------------------------------------------------
local win = Library.new("VENOM MOD (MOBILE)")

-- Tab 1: ESP & Visuals
local mainTab = win:AddTab("Visuals")
mainTab:AddToggle("Enable ESP", ESP.Enabled, function(state)
	ESP.Enabled = state
	UpdateESP()
end)

mainTab:AddToggle("ESP Fill", ESP.EnableFill, function(state)
	ESP.EnableFill = state
	UpdateESP()
end)

mainTab:AddToggle("ESP Outline", ESP.EnableOutline, function(state)
	ESP.EnableOutline = state
	UpdateESP()
end)

mainTab:AddToggle("Penetration View", Other.PenView, function(state)
	TogglePenView(state)
end)

mainTab:AddToggle("Remove Fog", Other.RemoveFog, function(state)
	Other.RemoveFog = state
	if state then
		Services.Lighting.FogEnd = 100000
	else
		Services.Lighting.FogEnd = 1000
	end
end)

-- Tab 2: Movement & Flight
local moveTab = win:AddTab("Movement")
moveTab:AddToggle("Enable Fly", Fly.Active, function(state)
	Fly.Active = state
end)

moveTab:AddSlider("Fly Speed", 10, 300, Fly.Speed, function(val)
	Fly.Speed = val
end)
