--===================================================================================--
--                    AUTO CHEST FARM + CHALICE DETECTOR v2                            --
--                    Blox Fruits — Dmitri Kotakbass                                   --
--                    BEAUTIFUL UI + FAST COLLECTION                                   --
--===================================================================================--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer

local guiParent = plr:WaitForChild("PlayerGui")
pcall(function()
    local cg = game:GetService("CoreGui")
    if cg then guiParent = cg end
end)

--===================================================================================--
--                              CONFIG                                                --
--===================================================================================--

local Config = {
    AutoChest = false,
    AutoChaliceSearch = false,
    ChestRange = 3000,
    CollectDelay = 0.8,
    MoveSpeed = 420,
    ChaliceCheckInterval = 3,
    ChaliceSpawnInterval = 14400,
}

local Stats = {
    ChestsCollected = 0,
    MoneyEarned = 0,
    StartMoney = 0,
    StartTime = os.clock(),
    ChaliceFound = false,
    ChaliceTimerLeft = 14400,
    ChaliceLastSpawn = os.clock(),
    Status = "Idle",
}

local ChestPriority = {
    {pattern = "Diamond", priority = 1, money = 10000, name = "Diamond"},
    {pattern = "Gold", priority = 2, money = 4500, name = "Gold"},
    {pattern = "Silver", priority = 3, money = 1300, name = "Silver"},
    {pattern = "Chest", priority = 3, money = 1300, name = "Silver"},
}

local ExcludedChests = {"Mirage", "Fragment", "Cursed"}

--===================================================================================--
--                              CORE                                                  --
--===================================================================================--

local function getHRP()
    local c = plr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function alive()
    local c = plr.Character
    return c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") and c:FindFirstChildOfClass("Humanoid").Health > 0
end

local function isExcluded(chestName)
    for _, excluded in ipairs(ExcludedChests) do
        if chestName:find(excluded) then return true end
    end
    return false
end

local function getChestType(chestName)
    for _, data in ipairs(ChestPriority) do
        if chestName:find(data.pattern) then return data end
    end
    return {priority = 4, money = 1000, name = "Unknown"}
end

local function findChests()
    local chests = {}
    local hrp = getHRP()
    if not hrp then return chests end

    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Part") and obj.Name:find("Chest") and not isExcluded(obj.Name) then
                if obj.Parent and obj.Transparency < 0.5 then
                    local chestData = getChestType(obj.Name)
                    local distance = (obj.Position - hrp.Position).Magnitude
                    if distance <= Config.ChestRange then
                        table.insert(chests, {
                            part = obj,
                            name = chestData.name,
                            priority = chestData.priority,
                            money = chestData.money,
                            distance = distance,
                        })
                    end
                end
            end
        end
    end)

    table.sort(chests, function(a, b)
        if a.priority == b.priority then return a.distance < b.distance end
        return a.priority < b.priority
    end)

    return chests
end

local function tweenTo(targetPos, offset)
    local hrp = getHRP()
    if not hrp then return false end
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    local pos = targetPos + Vector3.new(0, offset or 2, 0)
    local dist = (pos - hrp.Position).Magnitude
    if dist < 3 then return true end

    hum:MoveTo(Vector3.new(pos.X, hrp.Position.Y, pos.Z))

    local start = os.clock()
    local timeout = math.clamp(dist / 15, 2, 12)
    while os.clock() - start < timeout do
        if not alive() then return false end
        local d = (Vector3.new(pos.X, hrp.Position.Y, pos.Z) - hrp.Position).Magnitude
        if d < 4 then return true end
        task.wait(0.15)
    end

    hum:MoveTo(Vector3.new(pos.X, pos.Y, pos.Z))
    task.wait(0.3)
    return true
end

local function getMoney()
    local money = 0
    pcall(function() money = plr.Data.Beli.Value end)
    return money
end

local function collectChest(chest)
    if not chest or not chest.part or not chest.part.Parent then return false end
    if chest.part.Transparency >= 0.5 then return false end

    Stats.Status = "Moving to " .. chest.name .. " (" .. math.floor(chest.distance) .. "m)"
    local moneyBefore = getMoney()

    if tweenTo(chest.part.Position, 2) then
        task.wait(0.5 + math.random() * 0.5)
        local moneyAfter = getMoney()
        local earned = math.max(0, moneyAfter - moneyBefore)
        if earned > 0 then
            Stats.ChestsCollected = Stats.ChestsCollected + 1
            Stats.MoneyEarned = Stats.MoneyEarned + earned
            Stats.Status = "Collected " .. chest.name .. " (+$" .. earned .. ")"
        else
            Stats.Status = "Visited " .. chest.name .. " (no money)"
        end
        return true
    end
    return false
end

--===================================================================================--
--                              BEAUTIFUL UI                                          --
--===================================================================================--

-- Colors
local CLR = {
    bg = Color3.fromRGB(15, 15, 25),
    bg2 = Color3.fromRGB(20, 20, 35),
    glass = Color3.fromRGB(25, 25, 45),
    glass2 = Color3.fromRGB(30, 30, 50),
    accent = Color3.fromRGB(100, 70, 255),
    accent2 = Color3.fromRGB(140, 100, 255),
    accentGlow = Color3.fromRGB(80, 50, 200),
    gold = Color3.fromRGB(255, 215, 0),
    gold2 = Color3.fromRGB(255, 180, 50),
    green = Color3.fromRGB(0, 220, 120),
    red = Color3.fromRGB(255, 60, 80),
    txt = Color3.fromRGB(230, 235, 255),
    txtDim = Color3.fromRGB(140, 145, 170),
    on = Color3.fromRGB(0, 200, 100),
    off = Color3.fromRGB(50, 50, 70),
}

-- Main GUI
local gui = Instance.new("ScreenGui")
gui.Name = "ChestFarmV2"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = guiParent

-- Animation helpers
local function tween(obj, props, duration, style)
    local t = TweenService:Create(obj, TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function fadeIn(obj, dur)
    obj.Visible = true
    obj.GroupTransparency = 1
    tween(obj, {GroupTransparency = 0}, dur or 0.4)
end

local function fadeOut(obj, dur)
    tween(obj, {GroupTransparency = 1}, dur or 0.3)
    task.delay(dur or 0.3, function() obj.Visible = false end)
end

local function scaleIn(obj, dur, targetSize)
    obj.Size = UDim2.new(0, 0, 0, 0)
    obj.Visible = true
    tween(obj, {Size = targetSize}, dur or 0.5, Enum.EasingStyle.Back)
end

-- Floating button
local circGui = Instance.new("ScreenGui")
circGui.Name = "ChestFarmBtn"
circGui.ResetOnSpawn = false
circGui.Parent = guiParent

local circFrame = Instance.new("Frame", circGui)
circFrame.Size = UDim2.new(0, 52, 0, 52)
circFrame.Position = UDim2.new(1, -65, 0.5, -26)
circFrame.BackgroundTransparency = 1
circFrame.BorderSizePixel = 0

local circ = Instance.new("TextButton", circFrame)
circ.Size = UDim2.new(1, 0, 1, 0)
circ.BackgroundColor3 = CLR.bg
circ.BackgroundTransparency = 0.15
circ.Text = ""
circ.BorderSizePixel = 0
circ.Active = true
circ.Draggable = true
Instance.new("UICorner", circ).CornerRadius = UDim.new(1, 0)

local circStroke = Instance.new("UIStroke", circ)
circStroke.Thickness = 2
circStroke.Color = CLR.accent
circStroke.Transparency = 0.3

-- Glow effect
local circGlow = Instance.new("UIStroke", circ)
circGlow.Thickness = 6
circGlow.Color = CLR.accentGlow
circGlow.Transparency = 0.7

-- Icon text
local circIcon = Instance.new("TextLabel", circ)
circIcon.Size = UDim2.new(1, 0, 1, 0)
circIcon.BackgroundTransparency = 1
circIcon.Text = "CF"
circIcon.TextColor3 = CLR.accent2
circIcon.Font = Enum.Font.GothamBlack
circIcon.TextSize = 16

-- Pulse animation
task.spawn(function()
    while circ and circ.Parent do
        if Config.AutoChest or Config.AutoChaliceSearch then
            local t = os.clock()
            local a = math.abs(math.sin(t * 3))
            circStroke.Color = Color3.new(
                CLR.accent.R + a * 0.2,
                CLR.accent.G + a * 0.1,
                CLR.accent.B
            )
            circStroke.Transparency = 0.1 + a * 0.3
            circGlow.Transparency = 0.5 + a * 0.3
            circIcon.Text = string.char(9679)
            circIcon.TextColor3 = CLR.gold
        else
            circStroke.Color = CLR.accent
            circStroke.Transparency = 0.3
            circGlow.Transparency = 0.7
            circIcon.Text = "CF"
            circIcon.TextColor3 = CLR.accent2
        end
        task.wait(0.03)
    end
end)

-- Main Panel
local panel = Instance.new("ScreenGui")
panel.Name = "ChestFarmPanel"
panel.ResetOnSpawn = false
panel.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
panel.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 300, 0, 480)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -240)
mainFrame.BackgroundColor3 = CLR.bg
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = panel
mainFrame.Visible = false
local MAIN_SIZE = UDim2.new(0, 300, 0, 480)
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

-- Glass stroke
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Thickness = 1
mainStroke.Color = CLR.accent
mainStroke.Transparency = 0.6

-- Inner glow
local mainGlow = Instance.new("UIStroke", mainFrame)
mainGlow.Thickness = 4
mainGlow.Color = CLR.accentGlow
mainGlow.Transparency = 0.85

-- Background gradient
local bgGrad = Instance.new("UIGradient", mainFrame)
bgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 20, 50)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 15, 40)),
})
bgGrad.Rotation = 45

-- Title bar
local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = CLR.glass
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 16)

local titleFill = Instance.new("Frame", titleBar)
titleFill.Size = UDim2.new(1, 0, 0, 20)
titleFill.Position = UDim2.new(0, 0, 1, -20)
titleFill.BackgroundColor3 = CLR.glass
titleFill.BackgroundTransparency = 0.3
titleFill.BorderSizePixel = 0

-- Accent line
local accentLine = Instance.new("Frame", mainFrame)
accentLine.Size = UDim2.new(1, -40, 0, 2)
accentLine.Position = UDim2.new(0, 20, 0, 42)
accentLine.BackgroundColor3 = CLR.accent
accentLine.BorderSizePixel = 0
Instance.new("UICorner", accentLine).CornerRadius = UDim.new(1, 0)
Instance.new("UIGradient", accentLine).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, CLR.accent),
    ColorSequenceKeypoint.new(0.5, CLR.gold),
    ColorSequenceKeypoint.new(1, CLR.accent),
})

-- Title text
local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1, -50, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "CHEST FARM"
titleText.TextColor3 = CLR.txt
titleText.Font = Enum.Font.GothamBlack
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Left

local titleSub = Instance.new("TextLabel", titleBar)
titleSub.Size = UDim2.new(0, 80, 0, 12)
titleSub.Position = UDim2.new(0, 15, 1, -14)
titleSub.BackgroundTransparency = 1
titleSub.Text = "v2.0 CHALICE"
titleSub.TextColor3 = CLR.gold
titleSub.Font = Enum.Font.GothamBold
titleSub.TextSize = 8
titleSub.TextXAlignment = Enum.TextXAlignment.Left

-- Close button
local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -35, 0.5, -14)
closeBtn.BackgroundColor3 = CLR.red
closeBtn.BackgroundTransparency = 0.2
closeBtn.Text = ""
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

local closeX = Instance.new("TextLabel", closeBtn)
closeX.Size = UDim2.new(1, 0, 1, 0)
closeX.BackgroundTransparency = 1
closeX.Text = "X"
closeX.TextColor3 = Color3.new(1,1,1)
closeX.Font = Enum.Font.GothamBlack
closeX.TextSize = 12

-- Scroll content
local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -30, 1, -55)
scroll.Position = UDim2.new(0, 15, 0, 50)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = CLR.accent
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 6)
Instance.new("UIPadding", scroll).PaddingBottom = UDim.new(0, 10)

-- UI Builders
local function section(parent, text)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, 0, 0, 24)
    fr.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "  " .. string.upper(text)
    lbl.TextColor3 = CLR.accent2
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local line = Instance.new("Frame", fr)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -2)
    line.BackgroundColor3 = CLR.glass2
    line.BorderSizePixel = 0
end

local function statLabel(parent, text)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, 0, 0, 22)
    fr.BackgroundColor3 = CLR.glass
    fr.BackgroundTransparency = 0.5
    fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = CLR.txt
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    return lbl
end

local function toggle(parent, text, default, callback)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, 0, 0, 36)
    fr.BackgroundColor3 = CLR.glass
    fr.BackgroundTransparency = 0.4
    fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 10)

    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(1, -56, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = CLR.txt
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local togBg = Instance.new("Frame", fr)
    togBg.Size = UDim2.new(0, 44, 0, 22)
    togBg.Position = UDim2.new(1, -54, 0.5, -11)
    togBg.BorderSizePixel = 0
    Instance.new("UICorner", togBg).CornerRadius = UDim.new(1, 0)

    local togDot = Instance.new("Frame", togBg)
    togDot.Size = UDim2.new(0, 18, 0, 18)
    togDot.Position = UDim2.new(0, 2, 0.5, -9)
    togDot.BorderSizePixel = 0
    Instance.new("UICorner", togDot).CornerRadius = UDim.new(1, 0)

    local glowFrame = Instance.new("Frame", togBg)
    glowFrame.Size = UDim2.new(1, 4, 1, 4)
    glowFrame.Position = UDim2.new(0, -2, 0.5, -11)
    glowFrame.BackgroundTransparency = 1
    glowFrame.BorderSizePixel = 0
    Instance.new("UICorner", glowFrame).CornerRadius = UDim.new(1, 0)

    local state = default or false

    local function update(anim)
        local dur = anim and 0.2 or 0
        if state then
            tween(togBg, {BackgroundColor3 = CLR.on}, dur)
            tween(togDot, {Position = UDim2.new(1, -20, 0.5, -9), BackgroundColor3 = Color3.new(1,1,1)}, dur, Enum.EasingStyle.Back)
            tween(glowFrame, {BackgroundTransparency = 0.5, BackgroundColor3 = CLR.on}, dur)
        else
            tween(togBg, {BackgroundColor3 = CLR.off}, dur)
            tween(togDot, {Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = CLR.txtDim}, dur, Enum.EasingStyle.Back)
            tween(glowFrame, {BackgroundTransparency = 1}, dur)
        end
    end

    update(false)

    local btnHit = Instance.new("TextButton", fr)
    btnHit.Size = UDim2.new(1, 0, 1, 0)
    btnHit.BackgroundTransparency = 1
    btnHit.Text = ""

    btnHit.MouseButton1Click:Connect(function()
        state = not state
        update(true)
        if callback then callback(state) end
    end)

    return {Set = function(_, v) state = v; update(true) end, Get = function() return state end}
end

local function button(parent, text, callback, color)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, 0, 0, 34)
    fr.BackgroundTransparency = 1

    local b = Instance.new("TextButton", fr)
    b.Size = UDim2.new(1, 0, 1, 0)
    b.BackgroundColor3 = color or CLR.accent
    b.BackgroundTransparency = 0.1
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)

    local grad = Instance.new("UIGradient", b)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
    })
    grad.Rotation = 90

    b.MouseEnter:Connect(function()
        tween(b, {BackgroundTransparency = 0}, 0.15)
        tween(b, {Size = UDim2.new(1, 4, 1, 2)}, 0.15, Enum.EasingStyle.Back)
    end)
    b.MouseLeave:Connect(function()
        tween(b, {BackgroundTransparency = 0.1}, 0.15)
        tween(b, {Size = UDim2.new(1, 0, 1, 0)}, 0.15)
    end)
    b.MouseButton1Click:Connect(callback)
end

--===================================================================================--
--                              BUILD UI                                              --
--===================================================================================--

section(scroll, "Chest Farm")

local togChest = toggle(scroll, "Auto Chest Farm", false, function(s)
    Config.AutoChest = s
    Stats.Status = s and "Starting..." or "Stopped"
end)

section(scroll, "Chalice Detector")

local togChalice = toggle(scroll, "Auto Chalice Search", false, function(s)
    Config.AutoChaliceSearch = s
    if s then Stats.ChaliceLastSpawn = os.clock() end
end)

section(scroll, "Live Stats")

local lStatus = statLabel(scroll, "Status: Idle")
local lChests = statLabel(scroll, "Chests: 0")
local lMoney = statLabel(scroll, "Money: $0")
local lChalice = statLabel(scroll, "Chalice: Not found")
local lTimer = statLabel(scroll, "Timer: 4:00:00")
local lTime = statLabel(scroll, "Session: 0m 0s")

section(scroll, "Quick Actions")

button(scroll, "Find Nearest Chest", function()
    local chests = findChests()
    if #chests > 0 then
        Stats.Status = "Nearest: " .. chests[1].name .. " (" .. math.floor(chests[1].distance) .. "m)"
    else
        Stats.Status = "No chests found"
    end
end, CLR.glass2)

button(scroll, "Collect All Chests", function()
    Config.AutoChest = true
    pcall(function() togChest:Set(true) end)
    Stats.Status = "Starting..."
end, CLR.accent)

button(scroll, "Reset Chalice Timer", function()
    Stats.ChaliceLastSpawn = os.clock()
    Stats.ChaliceFound = false
    Stats.Status = "Timer reset"
end, CLR.gold2)

--===================================================================================--
--                              ANIMATIONS                                            --
--===================================================================================--

local panelOpen = false

local function openPanel()
    if panelOpen then return end
    panelOpen = true
    scaleIn(mainFrame, 0.4, MAIN_SIZE)
end

local function closePanel()
    if not panelOpen then return end
    panelOpen = false
    mainFrame.Visible = false
end

circ.MouseButton1Click:Connect(function()
    if panelOpen then closePanel() else openPanel() end
end)

closeBtn.MouseButton1Click:Connect(closePanel)

closeBtn.MouseEnter:Connect(function()
    tween(closeBtn, {BackgroundTransparency = 0}, 0.15)
end)
closeBtn.MouseLeave:Connect(function()
    tween(closeBtn, {BackgroundTransparency = 0.2}, 0.15)
end)

-- Keybind
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.C then
        Config.AutoChest = not Config.AutoChest
        Stats.Status = Config.AutoChest and "Starting..." or "Stopped"
        pcall(function() togChest:Set(Config.AutoChest) end)
    end
    if inp.KeyCode == Enum.KeyCode.X then
        if panelOpen then closePanel() else openPanel() end
    end
end)

--===================================================================================--
--                              STATS LOOP                                            --
--===================================================================================--

spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            local elapsed = os.clock() - Stats.StartTime
            lStatus.Text = "Status: " .. Stats.Status
            lChests.Text = "Chests: " .. Stats.ChestsCollected
            local realMoney = getMoney()
            lMoney.Text = "Money: $" .. tostring(realMoney)
            lChalice.Text = "Chalice: " .. (Stats.ChaliceFound and "FOUND!" or "Not found")
            lChalice.TextColor3 = Stats.ChaliceFound and CLR.gold or CLR.txt

            local h = math.floor(Stats.ChaliceTimerLeft / 3600)
            local m = math.floor((Stats.ChaliceTimerLeft % 3600) / 60)
            local s = math.floor(Stats.ChaliceTimerLeft % 60)
            lTimer.Text = string.format("Timer: %d:%02d:%02d", h, m, s)

            if Stats.ChaliceTimerLeft <= 0 then
                lTimer.Text = "Timer: SPAWN POSSIBLE!"
                lTimer.TextColor3 = CLR.green
            else
                lTimer.TextColor3 = CLR.txt
            end

            lTime.Text = string.format("Session: %dm %ds", math.floor(elapsed / 60), math.floor(elapsed % 60))
        end)
    end
end)

--===================================================================================--
--                              CHEST FARM LOOP                                       --
--===================================================================================--

spawn(function()
    while true do
        task.wait(0.5)
        if not Config.AutoChest then task.wait(1) continue end
        if not alive() then task.wait(2) continue end

        local ok, err = pcall(function()
            while Config.AutoChest do
                if not alive() then task.wait(2) continue end
                local chests = findChests()
                if #chests == 0 then
                    Stats.Status = "Scanning..."
                    task.wait(2 + math.random() * 2)
                    continue
                end
                for _, chest in ipairs(chests) do
                    if not Config.AutoChest or not alive() then break end
                    if chest.part and chest.part.Parent and chest.part.Transparency < 0.5 then
                        collectChest(chest)
                        task.wait(0.5 + math.random() * 1)
                    end
                end
                task.wait(1 + math.random() * 2)
            end
        end)

        if not ok then
            Stats.Status = "Error"
            task.wait(2)
        end
    end
end)

--===================================================================================--
--                              CHALICE LOOP                                          --
--===================================================================================--

spawn(function()
    Stats.ChaliceLastSpawn = os.clock()
    while true do
        task.wait(1)
        pcall(function()
            local elapsed = os.clock() - Stats.ChaliceLastSpawn
            Stats.ChaliceTimerLeft = math.max(0, Config.ChaliceSpawnInterval - elapsed)
        end)
    end
end)

spawn(function()
    while true do
        task.wait(Config.ChaliceCheckInterval)
        if not alive() then continue end
        pcall(function()
            if plr.Backpack:FindFirstChild("God's Chalice") or (plr.Character and plr.Character:FindFirstChild("God's Chalice")) then
                if not Stats.ChaliceFound then
                    Stats.ChaliceFound = true
                    pcall(function()
                        StarterGui:SetCore("SendNotification", {Title = "CHALICE!", Text = "God's Chalice found!", Duration = 5})
                    end)
                end
            end
        end)
    end
end)

--===================================================================================--
--                              INIT                                                  --
--===================================================================================--

print("[ChestFarm v2] Loaded — C toggle | X menu")
pcall(function()
    StarterGui:SetCore("SendNotification", {Title = "Chest Farm v2", Text = "C = auto farm | X = menu", Duration = 4})
end)
