--[[
    Auto Ken Training v3.0
    Blox Fruits — Auto Observation Haki V1 Training
    Executor: Xeno / Delta
    NO external dependencies
]]

getgenv().KenConfig = getgenv().KenConfig or {
    AutoKen = false,
    Location = "Jungle",
    FlyHeight = 80,
    StayTime = 5,
    RechargeTime = 6,
    SafeRange = 12,
}
local C = getgenv().KenConfig

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local plr = Players.LocalPlayer

-- ==================== LOCATIONS ====================
local locations = {
    {"Jungle",           CFrame.new(-1242, 30, -452),     "1-15"},
    {"Pirate Village",   CFrame.new(-1120, 15, 510),      "15-35"},
    {"Desert",           CFrame.new(840, 25, 1250),       "35-65"},
    {"Frozen Village",   CFrame.new(820, 70, -1590),      "65-95"},
    {"Marine Fortress",  CFrame.new(-920, 40, 3320),      "95-125"},
    {"Sky Island",       CFrame.new(-5100, 320, 530),     "125-175"},
    {"Prison",           CFrame.new(4900, 8, 900),        "175-250"},
    {"Colosseum",        CFrame.new(-1420, 15, -2940),    "250-325"},
    {"Magma Village",    CFrame.new(-5300, 15, 1300),     "325-400"},
    {"Graveyard",        CFrame.new(-2950, 50, -3650),    "400-475"},
    {"Snow Mountain",    CFrame.new(550, 90, -2220),      "475-550"},
    {"Fishman Island",   CFrame.new(550, 125, 2820),      "550-675"},
    {"Mansion",          CFrame.new(-12700, 380, -500),   "675-750"},
    {"Sea of Treats",    CFrame.new(622, 25, 3970),       "750-900"},
    {"Fountain City",    CFrame.new(5160, 20, 3020),      "900-1050"},
    {"Hydra Island",     CFrame.new(5550, 25, -520),      "1050-1200"},
    {"Great Tree",       CFrame.new(8700, 130, 1750),     "1200-1450"},
    {"Castle on the Sea",CFrame.new(-5300, 20, 7000),     "1450-1700"},
    {"Haunted Castle",   CFrame.new(-9500, 145, 6150),    "1700+"},
}

local function getLocationCF(name)
    for _, loc in ipairs(locations) do
        if loc[1] == name then return loc[2] end
    end
    return locations[1][2]
end

-- ==================== COLORS ====================
local C_BG      = Color3.fromRGB(18, 18, 30)
local C_BG2     = Color3.fromRGB(24, 24, 42)
local C_BG3     = Color3.fromRGB(30, 30, 50)
local C_ACC     = Color3.fromRGB(70, 130, 255)
local C_ACC2    = Color3.fromRGB(100, 160, 255)
local C_TXT     = Color3.fromRGB(220, 225, 240)
local C_DIM     = Color3.fromRGB(140, 145, 170)
local C_GRN     = Color3.fromRGB(80, 220, 120)
local C_RED     = Color3.fromRGB(240, 80, 80)
local C_ON      = Color3.fromRGB(60, 180, 100)
local C_OFF     = Color3.fromRGB(80, 80, 100)

-- ==================== HELPERS ====================
local function getHRP()
    local ch = plr.Character
    return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function waitForChar()
    local ch = plr.Character
    if ch and ch:FindFirstChild("HumanoidRootPart") and ch:FindFirstChildOfClass("Humanoid") then
        return ch
    end
    return nil
end

local function findObservationTool()
    local bp = plr:FindFirstChild("Backpack")
    local ch = plr.Character
    if not bp then return nil end

    local searchExact = {"Observation", "Ken", "Ken Observation", "Observation V1", "Observation Haki"}
    for _, name in ipairs(searchExact) do
        local t = bp:FindFirstChild(name) or (ch and ch:FindFirstChild(name))
        if t then return t end
    end

    for _, obj in ipairs(bp:GetChildren()) do
        if obj:IsA("Tool") then
            local n = obj.Name:lower()
            if n:find("ken") or n:find("obs") then return obj end
        end
    end
    if ch then
        for _, obj in ipairs(ch:GetChildren()) do
            if obj:IsA("Tool") then
                local n = obj.Name:lower()
                if n:find("ken") or n:find("obs") then return obj end
            end
        end
    end
    return nil
end

local function activateObservation()
    local ch = waitForChar()
    if not ch then return false, "No character" end

    local tool = findObservationTool()
    if tool then
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:EquipTool(tool)
            task.wait(0.4)
        end

        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.12)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        task.wait(0.3)

        return true, "Tool activated"
    end

    local ok, err = pcall(function()
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        if remotes then
            local commF = remotes:FindFirstChild("CommF_")
            if commF then
                commF:InvokeServer("KenSwitch")
                task.wait(0.4)
                commF:InvokeServer("KenOn")
                task.wait(0.3)
            end
        end
    end)

    for _, key in ipairs({Enum.KeyCode.F, Enum.KeyCode.G, Enum.KeyCode.H}) do
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.08)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
        task.wait(0.15)
    end

    return ok, err
end

local function isObservationActive()
    local ch = waitForChar()
    if not ch then return false end

    local tool = ch:FindFirstChildOfClass("Tool")
    if tool then
        local n = tool.Name:lower()
        if n:find("obs") or n:find("ken") then return true end
    end

    local pg = plr:FindFirstChild("PlayerGui")
    if pg then
        for _, g in ipairs(pg:GetDescendants()) do
            if g:IsA("Frame") and g.Name:lower():find("observation") then
                return true
            end
        end
    end

    local data = plr:FindFirstChild("Data")
    if data then
        local ken = data:FindFirstChild("Ken") or data:FindFirstChild("Observation")
        if ken and type(ken.Value) == "number" and ken.Value > 0 then
            return true
        end
    end

    return false
end

local function findBestTarget()
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    local hrp = getHRP()
    if not hrp then return nil end

    local best, bestScore = nil, -math.huge
    for _, e in ipairs(enemies:GetChildren()) do
        local hum = e:FindFirstChild("Humanoid")
        local ehrp = e:FindFirstChild("HumanoidRootPart")
        if hum and ehrp and hum.Health > 0 then
            local dist = (ehrp.Position - hrp.Position).Magnitude
            local lvl = 0
            local lv = e:FindFirstChild("Level")
            if lv then lvl = lv.Value end
            local score = lvl * 2 - dist * 0.3
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
    local speed = math.clamp(d / 250, 0.15, 2)
    local tw = TweenService:Create(hrp, TweenInfo.new(speed, Enum.EasingStyle.Linear), {
        Position = target
    })
    tw:Play()
    tw.Completed:Wait()
end

local function teleportTo(cf)
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = cf + Vector3.new(0, 5, 0)
    end
end

-- ==================== STATS ====================
local Stats = {
    StartTime = os.clock(),
    CycleCount = 0,
    CurrentTarget = nil,
    Status = "Idle",
    ObsStatus = "Unknown",
}

-- ==================== CUSTOM UI ====================
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "KenTrainingUI"
mainGui.ResetOnSpawn = false
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 300, 0, 420)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -210)
mainFrame.BackgroundColor3 = C_BG
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = mainGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Thickness = 1
mainStroke.Color = C_ACC
mainStroke.Transparency = 0.5

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = C_BG2
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 10)
titleFix.Position = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3 = C_BG2
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

Instance.new("TextLabel", titleBar).Size = UDim2.new(1, -36, 1, 0)
local tLbl = titleBar:FindFirstChildOfClass("TextLabel")
tLbl.BackgroundTransparency = 1
tLbl.Text = "Ken Training v3.0"
tLbl.TextColor3 = C_ACC2
tLbl.Font = Enum.Font.GothamBold
tLbl.TextSize = 14
tLbl.TextXAlignment = Enum.TextXAlignment.Left
tLbl.Position = UDim2.new(0, 12, 0, 0)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0, 5)
closeBtn.BackgroundColor3 = C_RED
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)

-- Content area
local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Size = UDim2.new(1, -16, 1, -42)
content.Position = UDim2.new(0, 8, 0, 38)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = C_ACC
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = mainFrame

local cLayout = Instance.new("UIListLayout")
cLayout.Padding = UDim.new(0, 5)
cLayout.Parent = content

local cPad = Instance.new("UIPadding")
cPad.PaddingTop = UDim.new(0, 2)
cPad.PaddingBottom = UDim.new(0, 6)
cPad.Parent = content

-- ==================== UI BUILDERS ====================
local function makeSection(parent, text)
    local f = Instance.new("TextLabel")
    f.Size = UDim2.new(1, 0, 0, 20)
    f.BackgroundTransparency = 1
    f.Text = text
    f.TextColor3 = C_ACC2
    f.Font = Enum.Font.GothamBold
    f.TextSize = 12
    f.TextXAlignment = Enum.TextXAlignment.Left
    f.Parent = parent
    return f
end

local function makeLabel(parent, text)
    local f = Instance.new("TextLabel")
    f.Size = UDim2.new(1, 0, 0, 18)
    f.BackgroundTransparency = 1
    f.Text = text
    f.TextColor3 = C_TXT
    f.Font = Enum.Font.GothamMedium
    f.TextSize = 12
    f.TextXAlignment = Enum.TextXAlignment.Left
    f.Parent = parent
    return f
end

local function makeToggle(parent, text, default, cb)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = C_BG3
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C_TXT
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local tog = Instance.new("TextButton")
    tog.Size = UDim2.new(0, 40, 0, 18)
    tog.Position = UDim2.new(1, -48, 0.5, -9)
    tog.BorderSizePixel = 0
    tog.Text = ""
    tog.Parent = frame
    Instance.new("UICorner", tog).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.BorderSizePixel = 0
    dot.Parent = tog
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local state = default or false
    local function update()
        tog.BackgroundColor3 = state and C_ON or C_OFF
        TweenService:Create(dot, TweenInfo.new(0.12), {
            Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        }):Play()
    end
    update()

    tog.MouseButton1Click:Connect(function()
        state = not state
        update()
        if cb then cb(state) end
    end)

    return {
        Set = function(_, v) state = v; update() end,
        Get = function() return state end,
    }
end

local function makeSlider(parent, text, min, max, default, cb)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = C_BG3
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -46, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C_TXT
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 36, 0, 18)
    valLbl.Position = UDim2.new(1, -44, 0, 1)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = C_ACC2
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = frame

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -20, 0, 5)
    barBg.Position = UDim2.new(0, 10, 0, 24)
    barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    barBg.BorderSizePixel = 0
    barBg.Parent = frame
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    barFill.BackgroundColor3 = C_ACC
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    local barBtn = Instance.new("TextButton")
    barBtn.Size = UDim2.new(1, 0, 0, 16)
    barBtn.Position = UDim2.new(0, 0, 0.5, -8)
    barBtn.BackgroundTransparency = 1
    barBtn.Text = ""
    barBtn.Parent = barBg

    local cur = default
    local dragging = false

    barBtn.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local x = math.clamp((i.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
            cur = math.floor(min + (max - min) * x + 0.5)
            barFill.Size = UDim2.new((cur - min) / (max - min), 0, 1, 0)
            valLbl.Text = tostring(cur)
            if cb then cb(cur) end
        end
    end)

    return { Get = function() return cur end }
end

local function makeButton(parent, text, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = C_ACC
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

local function makeDropdown(parent, text, options, default, cb)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = C_BG3
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.4, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C_TXT
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local selBtn = Instance.new("TextButton")
    selBtn.Size = UDim2.new(0.55, 0, 0, 22)
    selBtn.Position = UDim2.new(0.43, 0, 0.5, -11)
    selBtn.BackgroundColor3 = C_BG
    selBtn.Text = default .. "  >"
    selBtn.TextColor3 = C_ACC2
    selBtn.Font = Enum.Font.GothamMedium
    selBtn.TextSize = 11
    selBtn.BorderSizePixel = 0
    selBtn.Parent = frame
    Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0, 5)

    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(1, -8, 0, 160)
    listFrame.Position = UDim2.new(0, 4, 0, 34)
    listFrame.BackgroundColor3 = C_BG
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.ZIndex = 10
    listFrame.ScrollBarThickness = 3
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listFrame.Parent = frame
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIListLayout", listFrame).Padding = UDim.new(0, 2)

    for _, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1, 0, 0, 24)
        ob.BackgroundColor3 = (opt == default) and C_BG3 or C_BG
        ob.Text = opt
        ob.TextColor3 = (opt == default) and C_ACC2 or C_TXT
        ob.Font = Enum.Font.GothamMedium
        ob.TextSize = 11
        ob.BorderSizePixel = 0
        ob.ZIndex = 11
        ob.Parent = listFrame

        ob.MouseButton1Click:Connect(function()
            selBtn.Text = opt .. "  >"
            listFrame.Visible = false
            if cb then cb(opt) end
        end)
    end

    selBtn.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
    end)

    return { Get = function() return selBtn.Text:gsub("  >", "") end }
end

-- ==================== BUILD UI ====================
-- Location
makeSection(content, "Location")

local locNames = {}
for _, loc in ipairs(locations) do
    table.insert(locNames, loc[1] .. " (Lv " .. loc[3] .. ")")
end

makeDropdown(content, "Place", locNames, locNames[1], function(val)
    local name = val:gsub(" %(Lv .+%)", "")
    C.Location = name
end)

makeButton(content, "Teleport to Location", function()
    teleportTo(getLocationCF(C.Location))
end)

Instance.new("Frame", content).Size = UDim2.new(1, 0, 0, 1)

-- Training
makeSection(content, "Training")

local togAutoKen = makeToggle(content, "Auto Ken Training (N)", false, function(state)
    C.AutoKen = state
    Stats.Status = state and "Starting..." or "Stopped"
    if not state then Stats.CurrentTarget = nil end
end)

makeButton(content, "Activate Observation", function()
    Stats.Status = "Activating Obs..."
    local ok, msg = activateObservation()
    Stats.ObsStatus = ok and "Active" or "Failed"
    Stats.Status = ok and "Observation activated!" or "Activation failed"
end)

Instance.new("Frame", content).Size = UDim2.new(1, 0, 0, 1)

-- Status
makeSection(content, "Status")

local lblStatus  = makeLabel(content, "Status: Idle")
local lblObs     = makeLabel(content, "Observation: Unknown")
local lblTarget  = makeLabel(content, "Target: None")
local lblCycles  = makeLabel(content, "Cycles: 0")
local lblTime    = makeLabel(content, "Time: 0m 0s")
local lblLoc     = makeLabel(content, "Location: Jungle")

Instance.new("Frame", content).Size = UDim2.new(1, 0, 0, 1)

-- Settings
makeSection(content, "Settings")

makeSlider(content, "Fly Height", 40, 150, 80, function(v) C.FlyHeight = v end)
makeSlider(content, "Stay Time", 2, 10, 5, function(v) C.StayTime = v end)
makeSlider(content, "Recharge Time", 3, 12, 6, function(v) C.RechargeTime = v end)
makeSlider(content, "Safe Range", 5, 25, 12, function(v) C.SafeRange = v end)

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
circle.BackgroundColor3 = C_BG
circle.BackgroundTransparency = 0.15
circle.BorderSizePixel = 0
circle.Active = true
circle.Draggable = true
circle.Parent = circleGui
Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

local cStroke = Instance.new("UIStroke", circle)
cStroke.Thickness = 1.5
cStroke.Color = C_ACC
cStroke.Transparency = 0.4

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

circle.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

spawn(function()
    while circle and circle.Parent do
        if C.AutoKen then
            local a = math.abs(math.sin(os.clock() * 3))
            cStroke.Transparency = 0.05 + a * 0.3
            cStroke.Thickness = 1.5 + a * 1.5
            circle.TextTransparency = 0.05
            circle.Text = string.char(9679)
        else
            cStroke.Transparency = 0.4
            cStroke.Thickness = 1.5
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

-- ==================== STATS UPDATER ====================
spawn(function()
    while task.wait(0.5) do
        local elapsed = os.clock() - Stats.StartTime
        local mins = math.floor(elapsed / 60)
        local secs = math.floor(elapsed % 60)
        local obsAct = isObservationActive()
        Stats.ObsStatus = obsAct and "Active" or "Inactive"

        pcall(function()
            lblStatus.Text = "Status: " .. Stats.Status
            lblObs.Text = "Observation: " .. Stats.ObsStatus
            lblTarget.Text = "Target: " .. (Stats.CurrentTarget and Stats.CurrentTarget.Name or "None")
            lblCycles.Text = "Cycles: " .. Stats.CycleCount
            lblTime.Text = "Time: " .. mins .. "m " .. secs .. "s"
            lblLoc.Text = "Location: " .. C.Location
        end)
    end
end)

-- ==================== MAIN LOOP ====================
spawn(function()
    while true do
        task.wait(0.1)
        if not C.AutoKen then task.wait(0.5) continue end

        local ok, err = pcall(function()
            local ch = waitForChar()
            if not ch then
                Stats.Status = "Waiting for respawn..."
                task.wait(1)
                return
            end

            Stats.Status = "Activating Observation..."
            local actOk, actMsg = activateObservation()
            Stats.ObsStatus = actOk and "Active" or "Failed"
            task.wait(0.3)

            Stats.Status = "Teleporting to " .. C.Location
            teleportTo(getLocationCF(C.Location))
            task.wait(1.5)

            Stats.Status = "Searching enemies..."
            task.wait(0.5)

            for cycle = 1, 99999 do
                if not C.AutoKen then break end

                ch = waitForChar()
                if not ch then
                    Stats.Status = "Waiting for respawn..."
                    task.wait(2)
                    continue
                end

                local target = findBestTarget()
                if not target then
                    Stats.Status = "No enemies, searching..."
                    task.wait(1)
                    continue
                end

                Stats.CurrentTarget = target
                Stats.Status = "Moving to " .. target.Name

                pcall(function()
                    flyTo(target.HumanoidRootPart.Position, 3)
                end)
                task.wait(0.2)

                Stats.Status = "Training with " .. target.Name .. "..."
                local start = os.clock()
                while os.clock() - start < C.StayTime and C.AutoKen do
                    pcall(function()
                        ch = waitForChar()
                        if ch and target and target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
                            local hrp = ch.HumanoidRootPart
                            local tpos = target.HumanoidRootPart.Position
                            local dist = (tpos - hrp.Position).Magnitude
                            if dist > C.SafeRange then
                                hrp.CFrame = CFrame.new(tpos + Vector3.new(0, 5, 0))
                            end
                            hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(tpos.X, hrp.Position.Y, tpos.Z))
                        end
                    end)
                    task.wait(0.1)
                end

                if not C.AutoKen then break end

                Stats.Status = "Recharging..."
                pcall(function()
                    if target and target:FindFirstChild("HumanoidRootPart") then
                        flyTo(target.HumanoidRootPart.Position, C.FlyHeight)
                    end
                end)

                Stats.Status = "Cooldown " .. C.RechargeTime .. "s"
                task.wait(C.RechargeTime)

                Stats.CycleCount = Stats.CycleCount + 1
            end
        end)

        if not ok then
            warn("[Ken Training] Error: " .. tostring(err))
            Stats.Status = "Error, retrying..."
            task.wait(2)
        end
    end
end)

-- ==================== INIT ====================
StarterGui:SetCore("SendNotification", {
    Title = "Ken Training v3.0",
    Text = "Press N to toggle | Click K for menu",
    Duration = 4,
})
print("[Ken Training] v3.0 loaded — N toggle | K menu")
