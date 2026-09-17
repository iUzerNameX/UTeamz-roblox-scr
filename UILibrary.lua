local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Library = {}
Library.__index = Library

local themes = {
	Background = Color3.fromRGB(20, 26, 22),
	Accent = Color3.fromRGB(46, 204, 113),
	DarkContrast = Color3.fromRGB(14, 18, 15),
	LightContrast = Color3.fromRGB(28, 36, 30),
	TextColor = Color3.fromRGB(255, 255, 255)
}

local function tween(object, info, properties)
	local t = TweenService:Create(object, info or TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
	t:Play()
	return t
end

local function triggerSaveConfig()
	local saveFunc = (getgenv and getgenv().SaveConfig) or _G.SaveConfig
	if saveFunc then
		saveFunc()
	end
end

function Library.new(title)
	local parentContainer = (gethui and gethui()) or CoreGui

	for _, old in ipairs(parentContainer:GetChildren()) do
		if old.Name == "UTeamz_UI" then old:Destroy() end
	end

	local sg = Instance.new("ScreenGui")
	sg.Name = "UTeamz_UI"
	sg.ResetOnSpawn = false
	sg.Parent = parentContainer

	local notifHolder = Instance.new("Frame")
	notifHolder.Name = "NotificationHolder"
	notifHolder.Size = UDim2.new(0, 220, 1, -20)
	notifHolder.Position = UDim2.new(1, -10, 1, -10)
	notifHolder.AnchorPoint = Vector2.new(1, 1)
	notifHolder.BackgroundTransparency = 1
	notifHolder.ZIndex = 100
	notifHolder.Parent = sg

	local notifList = Instance.new("UIListLayout")
	notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifList.HorizontalAlignment = Enum.HorizontalAlignment.Right
	notifList.Padding = UDim.new(0, 6)
	notifList.Parent = notifHolder

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.Size = UDim2.new(0.45, 0, 0.55, 0)
	main.BackgroundColor3 = themes.Background
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Parent = sg

	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = Vector2.new(340, 240)
	constraint.MaxSize = Vector2.new(550, 420)
	constraint.Parent = main

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = main

	local topbar = Instance.new("Frame")
	topbar.Name = "TopBar"
	topbar.Size = UDim2.new(1, 0, 0, 40)
	topbar.BackgroundColor3 = themes.DarkContrast
	topbar.BorderSizePixel = 0
	topbar.Parent = main

	local topTitle = Instance.new("TextLabel")
	topTitle.Size = UDim2.new(0.5, -12, 1, 0)
	topTitle.Position = UDim2.new(0, 12, 0, 0)
	topTitle.Font = Enum.Font.GothamBold
	topTitle.Text = title
	topTitle.TextColor3 = themes.Accent
	topTitle.TextSize = 14
	topTitle.TextXAlignment = Enum.TextXAlignment.Left
	topTitle.BackgroundTransparency = 1
	topTitle.Parent = topbar

	local tgLabel = Instance.new("TextLabel")
	tgLabel.Name = "TelegramTag"
	tgLabel.Size = UDim2.new(0.5, -12, 1, 0)
	tgLabel.Position = UDim2.new(1, -12, 0, 0)
	tgLabel.AnchorPoint = Vector2.new(1, 0)
	tgLabel.Font = Enum.Font.GothamMedium
	tgLabel.Text = "t.me/UTeamz"
	tgLabel.TextColor3 = themes.TextColor
	tgLabel.TextTransparency = 0.5
	tgLabel.TextSize = 11
	tgLabel.TextXAlignment = Enum.TextXAlignment.Right
	tgLabel.BackgroundTransparency = 1
	tgLabel.Parent = topbar

	local draggingMenu, dragStartMenu, startPosMenu, dragInputMenu
	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingMenu = true
			dragStartMenu = input.Position
			startPosMenu = main.Position
		end
	end)

	topbar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInputMenu = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInputMenu and draggingMenu then
			local delta = input.Position - dragStartMenu
			main.Position = UDim2.new(startPosMenu.X.Scale, startPosMenu.X.Offset + delta.X, startPosMenu.Y.Scale, startPosMenu.Y.Offset + delta.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingMenu = false
		end
	end)

	local resizeGrip = Instance.new("TextButton")
	resizeGrip.Name = "ResizeGrip"
	resizeGrip.Size = UDim2.new(0, 16, 0, 16)
	resizeGrip.Position = UDim2.new(1, -18, 1, -18)
	resizeGrip.BackgroundTransparency = 1
	resizeGrip.Text = "◢"
	resizeGrip.TextColor3 = themes.Accent
	resizeGrip.ZIndex = 10
	resizeGrip.Parent = main

	local resizingMenu, resizeStartMenu, startSizeMenu
	resizeGrip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizingMenu = true
			resizeStartMenu = input.Position
			startSizeMenu = main.AbsoluteSize
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if resizingMenu and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local delta = input.Position - resizeStartMenu
			local newWidth = math.max(300, startSizeMenu.X + delta.X)
			local newHeight = math.max(200, startSizeMenu.Y + delta.Y)
			main.Size = UDim2.new(0, newWidth, 0, newHeight)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizingMenu = false
		end
	end)

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "UTeamz_ToggleButton"
	toggleBtn.Size = UDim2.new(0, 70, 0, 35)
	toggleBtn.Position = UDim2.new(0.47, 0, 0, 0)
	toggleBtn.BackgroundColor3 = themes.Accent
	toggleBtn.Text = "UTeamz"
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.TextSize = 13
	toggleBtn.TextColor3 = Color3.fromRGB(0,0,0)
	toggleBtn.Parent = sg

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = toggleBtn

	local draggingBtn, dragStartBtn, startPosBtn, dragInputBtn, wasDragged = false, nil, nil, nil, false
	toggleBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingBtn = true
			dragStartBtn = input.Position
			startPosBtn = toggleBtn.Position
			wasDragged = false
		end
	end)

	toggleBtn.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInputBtn = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInputBtn and draggingBtn then
			local delta = input.Position - dragStartBtn
			if delta.Magnitude > 5 then wasDragged = true end
			toggleBtn.Position = UDim2.new(startPosBtn.X.Scale, startPosBtn.X.Offset + delta.X, startPosBtn.Y.Scale, startPosBtn.Y.Offset + delta.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingBtn = false
		end
	end)

	local menuVisible = true
	toggleBtn.MouseButton1Click:Connect(function()
		if not wasDragged then
			menuVisible = not menuVisible
			if menuVisible then
				main.Visible = true
				constraint.MinSize = Vector2.new(340, 240)
				tween(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(0.45, 0, 0.55, 0)
				})
			else
				constraint.MinSize = Vector2.new(0, 0)
				local t = tween(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = UDim2.new(0, 0, 0, 0)
				})
				t.Completed:Connect(function()
					if not menuVisible then main.Visible = false end
				end)
			end
		end
	end)

	local tabHolder = Instance.new("ScrollingFrame")
	tabHolder.Size = UDim2.new(0.28, 0, 1, -40)
	tabHolder.Position = UDim2.new(0, 0, 0, 40)
	tabHolder.BackgroundColor3 = themes.DarkContrast
	tabHolder.BorderSizePixel = 0
	tabHolder.ScrollBarThickness = 2
	tabHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabHolder.Parent = main

	local tabList = Instance.new("UIListLayout")
	tabList.Padding = UDim.new(0, 4)
	tabList.Parent = tabHolder

	tabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabHolder.CanvasSize = UDim2.new(0, 0, 0, tabList.AbsoluteContentSize.Y + 8)
	end)

	local pageHolder = Instance.new("Frame")
	pageHolder.Size = UDim2.new(0.72, -10, 1, -50)
	pageHolder.Position = UDim2.new(0.28, 5, 0, 45)
	pageHolder.BackgroundTransparency = 1
	pageHolder.Parent = main

	local searchFrame = Instance.new("Frame")
	searchFrame.Size = UDim2.new(1, -6, 0, 26)
	searchFrame.Position = UDim2.new(0, 0, 0, 0)
	searchFrame.BackgroundColor3 = themes.DarkContrast
	searchFrame.Parent = pageHolder

	local sfCorner = Instance.new("UICorner")
	sfCorner.CornerRadius = UDim.new(0, 6)
	sfCorner.Parent = searchFrame

	local searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1, -12, 1, 0)
	searchBox.Position = UDim2.new(0, 8, 0, 0)
	searchBox.PlaceholderText = "Search..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
	searchBox.Text = ""
	searchBox.Font = Enum.Font.Gotham
	searchBox.TextSize = 11
	searchBox.TextColor3 = themes.TextColor
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.BackgroundTransparency = 1
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchFrame

	local allElements = {}

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(searchBox.Text)
		for _, item in ipairs(allElements) do
			if query == "" then
				item.Frame.Visible = true
			else
				local match = string.find(string.lower(item.Text), query) ~= nil
				item.Frame.Visible = match
			end
		end
	end)

	local pickerWindow = Instance.new("Frame")
	pickerWindow.Name = "ColorPickerModal"
	pickerWindow.Size = UDim2.new(0, 234, 0, 240)
	pickerWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	pickerWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	pickerWindow.BackgroundColor3 = themes.Background
	pickerWindow.BorderSizePixel = 0
	pickerWindow.Visible = false
	pickerWindow.ZIndex = 30
	pickerWindow.Parent = sg

	local pwCorner = Instance.new("UICorner")
	pwCorner.CornerRadius = UDim.new(0, 10)
	pwCorner.Parent = pickerWindow

	local pwTop = Instance.new("Frame")
	pwTop.Size = UDim2.new(1, 0, 0, 32)
	pwTop.BackgroundColor3 = themes.DarkContrast
	pwTop.BorderSizePixel = 0
	pwTop.ZIndex = 31
	pwTop.Parent = pickerWindow

	local pwTopCorner = Instance.new("UICorner")
	pwTopCorner.CornerRadius = UDim.new(0, 10)
	pwTopCorner.Parent = pwTop

	local pwTitle = Instance.new("TextLabel")
	pwTitle.Size = UDim2.new(1, -35, 1, 0)
	pwTitle.Position = UDim2.new(0, 10, 0, 0)
	pwTitle.Text = "Select a color"
	pwTitle.Font = Enum.Font.GothamBold
	pwTitle.TextSize = 12
	pwTitle.TextColor3 = themes.Accent
	pwTitle.TextXAlignment = Enum.TextXAlignment.Left
	pwTitle.BackgroundTransparency = 1
	pwTitle.ZIndex = 32
	pwTitle.Parent = pwTop

	local pwClose = Instance.new("TextButton")
	pwClose.Size = UDim2.new(0, 32, 0, 32)
	pwClose.Position = UDim2.new(1, -32, 0, 0)
	pwClose.Text = "X"
	pwClose.Font = Enum.Font.GothamBold
	pwClose.TextColor3 = themes.TextColor
	pwClose.TextSize = 13
	pwClose.BackgroundTransparency = 1
	pwClose.ZIndex = 32
	pwClose.Parent = pwTop

	pwClose.MouseButton1Click:Connect(function()
		pickerWindow.Visible = false
	end)

	local gridFrame = Instance.new("Frame")
	gridFrame.Size = UDim2.new(1, -16, 1, -44)
	gridFrame.Position = UDim2.new(0, 8, 0, 38)
	gridFrame.BackgroundTransparency = 1
	gridFrame.ZIndex = 31
	gridFrame.Parent = pickerWindow

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 20, 0, 20)
	gridLayout.CellPadding = UDim2.new(0, 2, 0, 2)
	gridLayout.Parent = gridFrame

	local activeColorCallback = nil

	for row = 1, 9 do
		for col = 1, 10 do
			local colorBtn = Instance.new("TextButton")
			colorBtn.Text = ""
			colorBtn.BorderSizePixel = 0
			colorBtn.ZIndex = 32
			colorBtn.Parent = gridFrame

			local cCr = Instance.new("UICorner")
			cCr.CornerRadius = UDim.new(0, 4)
			cCr.Parent = colorBtn

			local color
			if col == 1 then
				local v = (row - 1) / 8
				color = Color3.new(v, v, v)
			else
				local hue = (col - 2) / 9
				local val = math.clamp(1.1 - (row / 10), 0.2, 1)
				local sat = math.clamp(row / 6, 0.3, 1)
				color = Color3.fromHSV(hue, sat, val)
			end
			colorBtn.BackgroundColor3 = color

			colorBtn.MouseButton1Click:Connect(function()
				if activeColorCallback then
					activeColorCallback(color)
				end
				pickerWindow.Visible = false
			end)
		end
	end

	local function openPicker(titleText, defaultColor, callback)
		pwTitle.Text = titleText
		activeColorCallback = callback
		pickerWindow.Visible = true
	end

	local libraryInstance = setmetatable({
		ScreenGui = sg,
		Main = main,
		TabHolder = tabHolder,
		PageHolder = pageHolder,
		NotifHolder = notifHolder,
		AllElements = allElements,
		OpenPicker = openPicker,
		Pages = {}
	}, Library)

	return libraryInstance
end

function Library:Notify(options)
	local title = options.Title or "Notification"
	local content = options.Content or ""
	local duration = options.Duration or 3

	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(1, 0, 0, 48)
	notif.BackgroundColor3 = themes.LightContrast
	notif.BackgroundTransparency = 1
	notif.BorderSizePixel = 0
	notif.ZIndex = 101
	notif.Parent = self.NotifHolder

	local nCorner = Instance.new("UICorner")
	nCorner.CornerRadius = UDim.new(0, 8)
	nCorner.Parent = notif

	local nBar = Instance.new("Frame")
	nBar.Size = UDim2.new(0, 4, 1, 0)
	nBar.BackgroundColor3 = themes.Accent
	nBar.BorderSizePixel = 0
	nBar.BackgroundTransparency = 1
	nBar.ZIndex = 102
	nBar.Parent = notif

	local nBarCorner = Instance.new("UICorner")
	nBarCorner.CornerRadius = UDim.new(0, 2)
	nBarCorner.Parent = nBar

	local nTitle = Instance.new("TextLabel")
	nTitle.Size = UDim2.new(1, -15, 0, 18)
	nTitle.Position = UDim2.new(0, 12, 0, 4)
	nTitle.Text = title
	nTitle.Font = Enum.Font.GothamBold
	nTitle.TextSize = 12
	nTitle.TextColor3 = themes.Accent
	nTitle.TextTransparency = 1
	nTitle.TextXAlignment = Enum.TextXAlignment.Left
	nTitle.BackgroundTransparency = 1
	nTitle.ZIndex = 102
	nTitle.Parent = notif

	local nDesc = Instance.new("TextLabel")
	nDesc.Size = UDim2.new(1, -15, 0, 22)
	nDesc.Position = UDim2.new(0, 12, 0, 22)
	nDesc.Text = content
	nDesc.Font = Enum.Font.Gotham
	nDesc.TextSize = 11
	nDesc.TextColor3 = themes.TextColor
	nDesc.TextTransparency = 1
	nDesc.TextXAlignment = Enum.TextXAlignment.Left
	nDesc.BackgroundTransparency = 1
	nDesc.ZIndex = 102
	nDesc.Parent = notif

	tween(notif, TweenInfo.new(0.3), {BackgroundTransparency = 0})
	tween(nBar, TweenInfo.new(0.3), {BackgroundTransparency = 0})
	tween(nTitle, TweenInfo.new(0.3), {TextTransparency = 0})
	tween(nDesc, TweenInfo.new(0.3), {TextTransparency = 0})

	task.delay(duration, function()
		local t = tween(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1})
		tween(nBar, TweenInfo.new(0.3), {BackgroundTransparency = 1})
		tween(nTitle, TweenInfo.new(0.3), {TextTransparency = 1})
		tween(nDesc, TweenInfo.new(0.3), {TextTransparency = 1})
		t.Completed:Connect(function()
			notif:Destroy()
		end)
	end)
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
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = tabBtn

	local pageScroll = Instance.new("ScrollingFrame")
	pageScroll.Size = UDim2.new(1, 0, 1, -32)
	pageScroll.Position = UDim2.new(0, 0, 0, 32)
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
			tween(t.Button, TweenInfo.new(0.2), {BackgroundColor3 = themes.LightContrast, TextColor3 = themes.TextColor})
		end
		pageScroll.Visible = true
		tween(tabBtn, TweenInfo.new(0.2), {BackgroundColor3 = themes.Accent, TextColor3 = Color3.fromRGB(0,0,0)})
	end)

	if #self.Pages == 0 then
		pageScroll.Visible = true
		tabBtn.BackgroundColor3 = themes.Accent
		tabBtn.TextColor3 = Color3.fromRGB(0,0,0)
	end

	table.insert(self.Pages, tabObj)

	local TabMethods = {}
	local parentLibrary = self

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

		local switchBack = Instance.new("TextButton")
		switchBack.Size = UDim2.new(0, 44, 0, 22)
		switchBack.Position = UDim2.new(1, -52, 0.5, -11)
		switchBack.BackgroundColor3 = default and themes.Accent or themes.DarkContrast
		switchBack.Text = ""
		switchBack.Parent = frame

		local sbCr = Instance.new("UICorner")
		sbCr.CornerRadius = UDim.new(1, 0)
		sbCr.Parent = switchBack

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 18, 0, 18)
		knob.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
		knob.BackgroundColor3 = default and Color3.fromRGB(0,0,0) or themes.TextColor
		knob.BorderSizePixel = 0
		knob.Parent = switchBack

		local knobCr = Instance.new("UICorner")
		knobCr.CornerRadius = UDim.new(1, 0)
		knobCr.Parent = knob

		local state = not not default
		local ToggleMethods = {}

		local function updateState(newState, skipCallback)
			state = newState
			if state then
				tween(switchBack, TweenInfo.new(0.2), {BackgroundColor3 = themes.Accent})
				tween(knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -20, 0.5, -9), BackgroundColor3 = Color3.fromRGB(0,0,0)})
			else
				tween(switchBack, TweenInfo.new(0.2), {BackgroundColor3 = themes.DarkContrast})
				tween(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = themes.TextColor})
			end

			if not skipCallback and callback then 
				callback(state) 
			end
			triggerSaveConfig()
		end

		switchBack.MouseButton1Click:Connect(function()
			updateState(not state)
		end)

		function ToggleMethods:Set(val, skipCallback)
			updateState(not not val, skipCallback)
		end

		function ToggleMethods:Get()
			return state
		end

		table.insert(parentLibrary.AllElements, {Frame = frame, Text = text})

		return ToggleMethods
	end

	function TabMethods:AddColorPicker(text, defaultColor, callback)
		defaultColor = defaultColor or Color3.fromRGB(255, 255, 255)

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, -6, 0, 40)
		frame.BackgroundColor3 = themes.LightContrast
		frame.Parent = pageScroll

		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(0, 6)
		cr.Parent = frame

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.65, 0, 1, 0)
		label.Position = UDim2.new(0, 10, 0, 0)
		label.Text = text
		label.Font = Enum.Font.Gotham
		label.TextSize = 12
		label.TextColor3 = themes.TextColor
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1
		label.Parent = frame

		local colorPreview = Instance.new("TextButton")
		colorPreview.Size = UDim2.new(0, 36, 0, 24)
		colorPreview.Position = UDim2.new(1, -46, 0.5, -12)
		colorPreview.BackgroundColor3 = defaultColor
		colorPreview.Text = ""
		colorPreview.Parent = frame

		local previewCr = Instance.new("UICorner")
		previewCr.CornerRadius = UDim.new(0, 6)
		previewCr.Parent = colorPreview

		colorPreview.MouseButton1Click:Connect(function()
			parentLibrary.OpenPicker(text, colorPreview.BackgroundColor3, function(selectedColor)
				colorPreview.BackgroundColor3 = selectedColor
				if callback then callback(selectedColor) end
				triggerSaveConfig()
			end)
		end)

		table.insert(parentLibrary.AllElements, {Frame = frame, Text = text})
	end

	function TabMethods:AddKeybind(text, defaultKey, callback)
		defaultKey = defaultKey or Enum.KeyCode.E

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, -6, 0, 40)
		frame.BackgroundColor3 = themes.LightContrast
		frame.Parent = pageScroll

		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(0, 6)
		cr.Parent = frame

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.65, 0, 1, 0)
		label.Position = UDim2.new(0, 10, 0, 0)
		label.Text = text
		label.Font = Enum.Font.Gotham
		label.TextSize = 12
		label.TextColor3 = themes.TextColor
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1
		label.Parent = frame

		local keyBtn = Instance.new("TextButton")
		keyBtn.Size = UDim2.new(0, 65, 0, 24)
		keyBtn.Position = UDim2.new(1, -75, 0.5, -12)
		keyBtn.BackgroundColor3 = themes.DarkContrast
		keyBtn.Text = defaultKey.Name
		keyBtn.Font = Enum.Font.GothamBold
		keyBtn.TextSize = 11
		keyBtn.TextColor3 = themes.Accent
		keyBtn.Parent = frame

		local kCr = Instance.new("UICorner")
		kCr.CornerRadius = UDim.new(0, 6)
		kCr.Parent = keyBtn

		local currentKey = defaultKey
		local listening = false

		keyBtn.MouseButton1Click:Connect(function()
			listening = true
			keyBtn.Text = "..."
			keyBtn.TextColor3 = themes.TextColor
		end)

		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if listening then
				if input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode == Enum.KeyCode.Escape then
						currentKey = Enum.KeyCode.Unknown
						keyBtn.Text = "None"
					else
						currentKey = input.KeyCode
						keyBtn.Text = currentKey.Name
					end
					keyBtn.TextColor3 = themes.Accent
					listening = false
					triggerSaveConfig()
				end
			elseif not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == currentKey and currentKey ~= Enum.KeyCode.Unknown then
					if callback then callback(currentKey) end
				end
			end
		end)

		table.insert(parentLibrary.AllElements, {Frame = frame, Text = text})
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

		UserInputService.InputChanged:Connect(function(input)
			if isSliding and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
				update(input)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				if isSliding then
					isSliding = false
					triggerSaveConfig()
				end
			end
		end)

		table.insert(parentLibrary.AllElements, {Frame = frame, Text = text})
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
			tween(btn, TweenInfo.new(0.1), {BackgroundColor3 = themes.Accent, TextColor3 = Color3.fromRGB(0,0,0)})
			task.delay(0.15, function()
				tween(btn, TweenInfo.new(0.2), {BackgroundColor3 = themes.LightContrast, TextColor3 = themes.TextColor})
			end)
			if callback then callback() end
		end)

		table.insert(parentLibrary.AllElements, {Frame = btn, Text = text})
	end

	return TabMethods
end

return Library
