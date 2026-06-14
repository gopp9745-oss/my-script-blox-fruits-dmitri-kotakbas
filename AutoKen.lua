--[[
    Auto Ken Training v2.0
    Blox Fruits — Auto Observation Haki V1 Training
    Executor: Xeno / Delta
    NO external UI dependencies — fully custom interface
    Features: Auto Ken, Smart Target, Live Stats, Level-Up Detector, Circle Toggle
]]

-- ==================== CONFIG ====================
getgenv().KenConfig = getgenv().KenConfig or {
    AutoKen = false,
    FlyHeight = 80,
    StayTime = 5,
    RechargeTime = 6,
    SafeRange = 12,
    TargetMode = "Smart",
    AutoActivate = true,
    ShowMainUI = true,
}
local C = getgenv().KenConfig

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local plr = Players.LocalPlayer

-- ==================== COLORS ====================
local COL_BG        = Color3.fromRGB(18, 18, 30)
local COL_BG2       = Color3.fromRGB(24, 24, 42)
local COL_BG3       = Color3.fromRGB(30, 30, 50)
local COL_ACCENT    = Color3.fromRGB(70, 130, 255)
local COL_ACCENT2   = Color3.fromRGB(100, 160, 255)
local COL_TEXT      = Color3.fromRGB(220, 225, 240)
local COL_TEXT_DIM  = Color3.fromRGB(140, 145, 170)
local COL_GREEN     = Color3.fromRGB(80, 220, 120)
local COL_RED       = Color3.fromRGB(240, 80, 80)
local COL_YELLOW    = Color3.fromRGB(255, 200, 60)
local COL_TOGGLE_ON = Color3.fromRGB(60, 180, 100)
local COL_TOGGLE_OFF= Color3.fromRGB(80, 80, 100)

-- ==================== HELPERS ====================
local function getHRP()
    local char = plr.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function hasObservation()
    local char = plr.Character
    local bp = plr:FindFirstChild("Backpack")
    for _, name in pairs({"Observation", "Ken", "Observation Haki"}) do
        if char and char:FindFirstChild(name) then return true end
        if bp and bp:FindFirstChild(name) then return true end
    end
    return false
end

local function activateObservation()
    pcall(function()
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        if remotes then
            local commF = remotes:FindFirstChild("CommF_")
            if commF then commF:InvokeServer("Observation") end
        end
    end)
    pcall(function()
        local obs = (plr.Backpack and plr.Backpack:FindFirstChild("Observation"))
            or (plr.Character and plr.Character:FindFirstChild("Observation"))
        if obs and obs:IsA("Tool") and plr.Character and plr.Character:FindFirstChild("Humanoid") then
            plr.Character.Humanoid:EquipTool(obs)
            task.wait(0.1)
        end
    end)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.08)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end)
end

local function getDodgeCount()
    local char = plr.Character
    if char then
        for _, name in pairs({"Dodge", "DodgeCount", "Dodges", "Observations"}) do
            local v = char:FindFirstChild(name)
            if v and v:IsA("NumberValue") then return v.Value end
        end
    end
    return nil
end

local function getKenLevel()
    local data = plr:FindFirstChild("Data")
    if data then
        for _, name in pairs({"Observation", "Ken", "ObservationLevel"}) do
            local v = data:FindFirstChild(name)
            if v then return v.Value end
        end
    end
    return nil
end

local function findBestTarget()
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    local hrp = getHRP()
    if not hrp then return nil end

    local best, bestScore = nil, -math.huge
    for _, e in pairs(enemies:GetChildren()) do
        local hum = e:FindFirstChild("Humanoid")
        local hrpE = e:FindFirstChild("HumanoidRootPart")
        if hum and hrpE and hum.Health > 0 then
            local dist = (hrpE.Position - hrp.Position).Magnitude
            local lvl = e:FindFirstChild("Level") and e.Level.Value or 1
            local hasHaki = e:FindFirstChild("Haki") ~= nil
                or e:FindFirstChild("Observation") ~= nil

            local score = 0
            if C.TargetMode == "Nearest" then
                score = -dist
            elseif C.TargetMode == "Haki" then
                score = (hasHaki and 1000 or 0) - dist
            else
                if hasHaki then score = score + 500 end
                score = score + lvl * 3 - dist * 0.5
            end
            if score > bestScore then bestScore = score; best = e end
        end
    end
    return best
end

local function flyTo(pos, offset)
    local hrp = getHRP()
    if not hrp then return end
    local target = pos + Vector3.new(0, offset or 0, 0)
    local d = (target - hrp.Position).Magnitude
    if d < 2 then return end
    local tw = TweenService:Create(hrp, TweenInfo.new(math.clamp(d / 250, 0.15, 2), Enum.EasingStyle.Linear), {
        Position = target
    })
    tw:Play()
    tw.Completed:Wait()
end

-- ==================== STATS ====================
local Stats = {
    StartTime = os.clock(),
    CycleCount = 0,
    LastKenLevel = nil,
    StartKenLevel = nil,
    CurrentTarget = nil,
    Status = "Idle",
    KenAvailable = false,
}

-- ==================== CUSTOM UI ====================
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "KenTrainingUI"
mainGui.ResetOnSpawn = false
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainGui.Parent = CoreGui

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 280, 0, 380)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -190)
mainFrame.BackgroundColor3 = COL_BG
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = mainGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 1
mainStroke.Color = COL_ACCENT
mainStroke.Transparency = 0.5
mainStroke.Parent = mainFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = COL_BG2
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 12)
titleFix.Position = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = COL_BG2
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Auto Ken Training v2.0"
titleLabel.TextColor3 = COL_ACCENT2
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -30, 0, 5)
closeBtn.BackgroundColor3 = COL_RED
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

-- Tab buttons
local tabContainer = Instance.new("Frame")
tabContainer.Name = "Tabs"
tabContainer.Size = UDim2.new(1, -12, 0, 30)
tabContainer.Position = UDim2.new(0, 6, 0, 42)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabContainer

local tabButtons = {}
local tabPages = {}
local activeTab = "Training"

local function createTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 85, 0, 26)
    btn.BackgroundColor3 = COL_BG3
    btn.Text = icon .. " " .. name
    btn.TextColor3 = COL_TEXT_DIM
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.Parent = tabContainer
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1, -12, 1, -100)
    page.Position = UDim2.new(0, 6, 0, 78)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = COL_ACCENT
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Parent = mainFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = page

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 2)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 2)
    padding.PaddingRight = UDim.new(0, 2)
    padding.Parent = page

    tabButtons[name] = btn
    tabPages[name] = page
    page.Visible = (name == activeTab)

    btn.MouseButton1Click:Connect(function()
        activeTab = name
        for n, b in pairs(tabButtons) do
            b.BackgroundColor3 = (n == name) and COL_ACCENT or COL_BG3
            b.TextColor3 = (n == name) and Color3.new(1,1,1) or COL_TEXT_DIM
        end
        for n, p in pairs(tabPages) do
            p.Visible = (n == name)
        end
    end)

    if name == activeTab then
        btn.BackgroundColor3 = COL_ACCENT
        btn.TextColor3 = Color3.new(1,1,1)
    end

    return page
end

-- UI builders for each tab
local function addSection(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = COL_ACCENT2
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
end

local function addLabel(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = COL_TEXT
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

local function addToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = COL_BG3
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -52, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = COL_TEXT
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 40, 0, 20)
    toggleBtn.Position = UDim2.new(1, -48, 0.5, -10)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = ""
    toggleBtn.Parent = frame
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1, 0); tc.Parent = toggleBtn

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = UDim2.new(0, 2, 0.5, -8)
    dot.BorderSizePixel = 0
    dot.Parent = toggleBtn
    local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot

    local state = default or false

    local function update()
        if state then
            toggleBtn.BackgroundColor3 = COL_TOGGLE_ON
            TweenService:Create(dot, TweenInfo.new(0.15), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
        else
            toggleBtn.BackgroundColor3 = COL_TOGGLE_OFF
            TweenService:Create(dot, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
        end
    end
    update()

    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        update()
        if callback then callback(state) end
    end)

    return {
        Set = function(_, val)
            state = val
            update()
        end,
        Get = function() return state end,
    }
end

local function addSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 44)
    frame.BackgroundColor3 = COL_BG3
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = COL_TEXT
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 40, 0, 20)
    valLbl.Position = UDim2.new(1, -48, 0, 2)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = COL_ACCENT2
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = frame

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -20, 0, 6)
    barBg.Position = UDim2.new(0, 10, 0, 28)
    barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    barBg.BorderSizePixel = 0
    barBg.Parent = frame
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = barBg

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    barFill.BackgroundColor3 = COL_ACCENT
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    local bf = Instance.new("UICorner"); bf.CornerRadius = UDim.new(1, 0); bf.Parent = barFill

    local barBtn = Instance.new("TextButton")
    barBtn.Size = UDim2.new(1, 0, 0, 18)
    barBtn.Position = UDim2.new(0, 0, 0.5, -9)
    barBtn.BackgroundTransparency = 1
    barBtn.Text = ""
    barBtn.Parent = barBg

    local dragging = false
    local current = default

    barBtn.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local absPos = barBg.AbsolutePosition.X
            local absSize = barBg.AbsoluteSize.X
            local x = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
            current = math.floor(min + (max - min) * x + 0.5)
            barFill.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)
            valLbl.Text = tostring(current)
            if callback then callback(current) end
        end
    end)

    return {
        Get = function() return current end,
        Set = function(_, val)
            current = math.clamp(val, min, max)
            barFill.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)
            valLbl.Text = tostring(current)
        end,
    }
end

local function addDropdown(parent, text, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = COL_BG3
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = COL_TEXT
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0.5, -8, 0, 22)
    dropBtn.Position = UDim2.new(0.5, 0, 0.5, -11)
    dropBtn.BackgroundColor3 = COL_BG
    dropBtn.Text = default .. " ▼"
    dropBtn.TextColor3 = COL_ACCENT2
    dropBtn.Font = Enum.Font.GothamMedium
    dropBtn.TextSize = 11
    dropBtn.BorderSizePixel = 0
    dropBtn.Parent = frame
    local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0, 5); dc.Parent = dropBtn

    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(0.5, -8, 0, #options * 24)
    listFrame.Position = UDim2.new(0.5, 0, 0, 32)
    listFrame.BackgroundColor3 = COL_BG
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.ZIndex = 10
    listFrame.Parent = frame
    local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0, 5); lc.Parent = listFrame

    local current = default
    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 24)
        optBtn.BackgroundColor3 = (opt == default) and COL_BG3 or COL_BG
        optBtn.Text = opt
        optBtn.TextColor3 = (opt == default) and COL_ACCENT2 or COL_TEXT
        optBtn.Font = Enum.Font.GothamMedium
        optBtn.TextSize = 11
        optBtn.BorderSizePixel = 0
        optBtn.ZIndex = 11
        optBtn.Parent = listFrame

        optBtn.MouseButton1Click:Connect(function()
            current = opt
            dropBtn.Text = opt .. " ▼"
            listFrame.Visible = false
            for _, b in pairs(listFrame:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = (b.Text == opt) and COL_BG3 or COL_BG
                    b.TextColor3 = (b.Text == opt) and COL_ACCENT2 or COL_TEXT
                end
            end
            if callback then callback(opt) end
        end)
    end

    dropBtn.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
    end)

    return {
        Get = function() return current end,
        Set = function(_, val)
            current = val
            dropBtn.Text = val .. " ▼"
        end,
    }
end

-- ==================== BUILD TABS ====================
local tabTraining = createTab("Training", "⚔")
local tabSettings = createTab("Settings", "⚙")
local tabStats = createTab("Stats", "📊")

-- Training tab
addSection(tabTraining, "Auto Ken")
local togAutoKen = addToggle(tabTraining, "Auto Ken Training", false, function(state)
    C.AutoKen = state
    Stats.Status = state and "Starting..." or "Stopped"
    if not state then Stats.CurrentTarget = nil end
end)

addDropdown(tabTraining, "Target Mode", {"Smart", "Nearest", "Haki"}, "Smart", function(val)
    C.TargetMode = val
end)

addLabel(tabTraining, "Hotkey: N")

-- Settings tab
addSection(tabSettings, "Timings")
addSlider(tabSettings, "Fly Height", 50, 150, 80, function(v) C.FlyHeight = v end)
addSlider(tabSettings, "Stay Time (s)", 3, 10, 5, function(v) C.StayTime = v end)
addSlider(tabSettings, "Recharge Time (s)", 4, 12, 6, function(v) C.RechargeTime = v end)
addSlider(tabSettings, "Safe Range", 5, 25, 12, function(v) C.SafeRange = v end)

addSection(tabSettings, "Options")
addToggle(tabSettings, "Auto Activate Obs", true, function(state)
    C.AutoActivate = state
end)

-- Stats tab
addSection(tabStats, "Live Statistics")
local lblStatus = addLabel(tabStats, "Status: Idle")
local lblTarget = addLabel(tabStats, "Target: None")
local lblKenLevel = addLabel(tabStats, "Ken Level: N/A")
local lblDodges = addLabel(tabStats, "Dodges: N/A")
local lblCycles = addLabel(tabStats, "Cycles: 0")
local lblTime = addLabel(tabStats, "Time: 0m 0s")

-- ==================== CIRCLE TOGGLE ====================
local circleGui = Instance.new("ScreenGui")
circleGui.Name = "KenCircle"
circleGui.ResetOnSpawn = false
circleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
circleGui.Parent = CoreGui

local circle = Instance.new("TextButton")
circle.Size = UDim2.new(0, 50, 0, 50)
circle.Position = UDim2.new(0.93, 0, 0.82, 0)
circle.Text = "K"
circle.Font = Enum.Font.GothamBold
circle.TextSize = 24
circle.TextColor3 = Color3.fromRGB(180, 210, 255)
circle.BackgroundColor3 = COL_BG
circle.BackgroundTransparency = 0.15
circle.BorderSizePixel = 0
circle.Active = true
circle.Draggable = true
circle.Parent = circleGui

local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent = circle

local circleStroke = Instance.new("UIStroke")
circleStroke.Thickness = 1.5
circleStroke.Color = COL_ACCENT
circleStroke.Transparency = 0.4
circleStroke.Parent = circle

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    C.ShowMainUI = false
end)

circle.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
    C.ShowMainUI = mainFrame.Visible
end)

-- Pulse animation
spawn(function()
    while circle and circle.Parent do
        if C.AutoKen then
            local a = math.abs(math.sin(os.clock() * 3))
            circleStroke.Transparency = 0.05 + a * 0.3
            circleStroke.Thickness = 1.5 + a * 1.5
            circle.TextTransparency = 0.05
            circle.Text = "●"
        else
            circleStroke.Transparency = 0.4
            circleStroke.Thickness = 1.5
            circle.TextTransparency = 0.3
            circle.Text = "K"
        end
        task.wait(0.03)
    end
end)

-- ==================== KEYBIND ====================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.N then
        C.AutoKen = not C.AutoKen
        Stats.Status = C.AutoKen and "Starting..." or "Stopped"
        if not C.AutoKen then Stats.CurrentTarget = nil end
        pcall(function() togAutoKen:Set(C.AutoKen) end)
    end
end)

-- ==================== LEVEL-UP DETECTOR ====================
local function startLevelMonitor()
    local data = plr:FindFirstChild("Data")
    if not data then return end
    local obsLvl = data:FindFirstChild("Observation")
        or data:FindFirstChild("Ken")
        or data:FindFirstChild("ObservationLevel")
    if not obsLvl then return end

    Stats.LastKenLevel = obsLvl.Value
    Stats.StartKenLevel = obsLvl.Value

    obsLvl:GetPropertyChangedSignal("Value"):Connect(function()
        local newLvl = obsLvl.Value
        if newLvl > (Stats.LastKenLevel or 0) then
            StarterGui:SetCore("SendNotification", {
                Title = "Observation Level Up!",
                Text = tostring(Stats.LastKenLevel) .. " -> " .. tostring(newLvl),
                Duration = 5,
            })
            spawn(function()
                for i = 1, 10 do
                    circle.TextSize = 24 + i * 2
                    circle.BackgroundTransparency = 0.15 - i * 0.01
                    task.wait(0.02)
                end
                for i = 1, 10 do
                    circle.TextSize = 44 - i * 2
                    circle.BackgroundTransparency = 0.05 + i * 0.01
                    task.wait(0.02)
                end
            end)
        end
        Stats.LastKenLevel = newLvl
    end)
end

-- ==================== STATS UPDATER ====================
spawn(function()
    while task.wait(0.5) do
        local kenLvl = getKenLevel()
        local elapsed = os.clock() - Stats.StartTime
        local mins = math.floor(elapsed / 60)
        local secs = math.floor(elapsed % 60)

        local lvlTxt = kenLvl and ("Level " .. kenLvl) or "N/A"
        if kenLvl and Stats.StartKenLevel and kenLvl > Stats.StartKenLevel then
            lvlTxt = lvlTxt .. " (+" .. (kenLvl - Stats.StartKenLevel) .. ")"
        end

        local dodgeCount = getDodgeCount()
        local dodgeTxt = dodgeCount and tostring(dodgeCount) or "N/A"

        pcall(function()
            lblStatus.Text = "Status: " .. Stats.Status
            lblTarget.Text = "Target: " .. (Stats.CurrentTarget and Stats.CurrentTarget.Name or "None")
            lblKenLevel.Text = "Ken " .. lvlTxt
            lblDodges.Text = "Dodges: " .. dodgeTxt
            lblCycles.Text = "Cycles: " .. Stats.CycleCount
            lblTime.Text = "Time: " .. mins .. "m " .. secs .. "s"
        end)
    end
end)

-- ==================== MAIN LOOP ====================
spawn(function()
    while true do
        task.wait(0.1)
        if not C.AutoKen then task.wait(0.5) continue end

        local ok, err = pcall(function()
            local char = plr.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                Stats.Status = "Waiting for respawn..."
                return
            end
            local hrp = char.HumanoidRootPart

            if C.AutoActivate then
                activateObservation()
                task.wait(0.2)
            end

            local target = findBestTarget()
            if not target then
                Stats.Status = "No enemies found"
                Stats.CurrentTarget = nil
                return
            end
            Stats.CurrentTarget = target
            Stats.Status = "Moving to " .. target.Name

            local tPos = target.HumanoidRootPart.Position
            flyTo(tPos, 0)

            Stats.Status = "Training with " .. target.Name .. "..."
            local start = os.clock()
            while os.clock() - start < C.StayTime and C.AutoKen do
                pcall(function()
                    local tp = target.HumanoidRootPart.Position
                    local d = (tp - hrp.Position).Magnitude
                    if d > C.SafeRange then
                        hrp.CFrame = CFrame.new(tp + Vector3.new(0, 5, 0))
                    end
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(tp.X, hrp.Position.Y, tp.Z))
                end)
                task.wait(0.05)
            end

            if not C.AutoKen then return end

            Stats.Status = "Recharging..."
            local lastPos
            pcall(function() lastPos = target.HumanoidRootPart.Position end)
            if lastPos then flyTo(lastPos, C.FlyHeight) end

            Stats.Status = "Cooldown " .. C.RechargeTime .. "s..."
            task.wait(C.RechargeTime)

            Stats.CycleCount = Stats.CycleCount + 1
        end)

        if not ok then
            warn("[Ken Training] " .. tostring(err))
            Stats.Status = "Error (retrying...)"
            task.wait(1)
        end
    end
end)

-- ==================== INIT ====================
spawn(function()
    task.wait(2)
    startLevelMonitor()
end)

StarterGui:SetCore("SendNotification", {
    Title = "Auto Ken Training v2.0",
    Text = "Press N to toggle | Click K to hide",
    Duration = 4,
})
print("[Ken Training] v2.0 loaded - Press N | Circle button K")
