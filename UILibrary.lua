-- [[ UTeamz MOBILE UI LIBRARY ]] --
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local Library = {}
Library.__index = Library

local themes = {
    Background = Color3.fromRGB(20, 26, 22),
    Accent = Color3.fromRGB(46, 204, 113),
    DarkContrast = Color3.fromRGB(14, 18, 15),
    LightContrast = Color3.fromRGB(28, 36, 30),
    TextColor = Color3.fromRGB(255, 255, 255)
}

local function triggerSaveConfig()
    local saveFunc = (getgenv and getgenv().SaveConfig) or _G.SaveConfig
    if saveFunc then
        saveFunc()
    end
end

function Library.new(title)
    for _, old in ipairs(CoreGui:GetChildren()) do
        if old.Name == "UTeamz_UI" then old:Destroy() end
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "UTeamz_UI"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui
    
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 360, 0, 240)
    main.Position = UDim2.new(0.5, -180, 0.5, -120)
    main.BackgroundColor3 = themes.Background
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = sg
    
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
    topTitle.Size = UDim2.new(1, -15, 1, 0)
    topTitle.Position = UDim2.new(0, 12, 0, 0)
    topTitle.Font = Enum.Font.GothamBold
    topTitle.Text = title
    topTitle.TextColor3 = themes.Accent
    topTitle.TextSize = 14
    topTitle.TextXAlignment = Enum.TextXAlignment.Left
    topTitle.BackgroundTransparency = 1
    topTitle.Parent = topbar

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
    resizeGrip.Size = UDim2.new(0, 24, 0, 24)
    resizeGrip.Position = UDim2.new(1, -24, 1, -24)
    resizeGrip.BackgroundTransparency = 1
    resizeGrip.Text = "⇲"
    resizeGrip.Font = Enum.Font.GothamBold
    resizeGrip.TextSize = 14
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
            local newWidth = math.max(280, startSizeMenu.X + delta.X)
            local newHeight = math.max(180, startSizeMenu.Y + delta.Y)
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
    toggleBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
    toggleBtn.BackgroundColor3 = themes.Accent
    toggleBtn.Text = "UTeamz"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 13
    toggleBtn.TextColor3 = Color3.fromRGB(0,0,0)
    toggleBtn.Parent = sg
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = toggleBtn
    
    local draggingBtn, dragStartBtn, startPosBtn, dragInputBtn
    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingBtn = true
            dragStartBtn = input.Position
            startPosBtn = toggleBtn.Position
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
            toggleBtn.Position = UDim2.new(startPosBtn.X.Scale, startPosBtn.X.Offset + delta.X, startPosBtn.Y.Scale, startPosBtn.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingBtn = false
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
    corner.CornerRadius = UDim.new(0, 6)
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
            triggerSaveConfig()
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

return Library

