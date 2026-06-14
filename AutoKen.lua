--[[
    Auto Ken Training v4.0
    Blox Fruits — Auto Observation Haki V1 Training
    Executor: Xeno / Delta
    Simple, stable, no external dependencies
]]

getgenv().KenConfig = getgenv().KenConfig or {
    AutoKen = false,
    Location = "Prison",
    StayTime = 4,
    RechargeTime = 14,
    SafeRange = 15,
}
local C = getgenv().KenConfig

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local plr = Players.LocalPlayer

-- ==================== LOCATIONS ====================
local locations = {
    {"Jungle",           CFrame.new(-1242, 30, -452)},
    {"Pirate Village",   CFrame.new(-1120, 15, 510)},
    {"Desert",           CFrame.new(840, 25, 1250)},
    {"Frozen Village",   CFrame.new(820, 70, -1590)},
    {"Marine Fortress",  CFrame.new(-920, 40, 3320)},
    {"Prison",           CFrame.new(4900, 8, 900)},
    {"Colosseum",        CFrame.new(-1420, 15, -2940)},
    {"Magma Village",    CFrame.new(-5300, 15, 1300)},
    {"Graveyard",        CFrame.new(-2950, 50, -3650)},
    {"Snow Mountain",    CFrame.new(550, 90, -2220)},
    {"Fishman Island",   CFrame.new(550, 125, 2820)},
    {"Mansion",          CFrame.new(-12700, 380, -500)},
    {"Sea of Treats",    CFrame.new(622, 25, 3970)},
    {"Fountain City",    CFrame.new(5160, 20, 3020)},
    {"Hydra Island",     CFrame.new(5550, 25, -520)},
    {"Great Tree",       CFrame.new(8700, 130, 1750)},
    {"Castle on Sea",    CFrame.new(-5300, 20, 7000)},
    {"Haunted Castle",   CFrame.new(-9500, 145, 6150)},
}

local function getLocCF(name)
    for _, l in ipairs(locations) do
        if l[1] == name then return l[2] end
    end
    return locations[1][2]
end

-- ==================== COLORS ====================
local BG    = Color3.fromRGB(20, 20, 32)
local BG2   = Color3.fromRGB(28, 28, 46)
local BG3   = Color3.fromRGB(35, 35, 55)
local ACC   = Color3.fromRGB(80, 140, 255)
local ACC2  = Color3.fromRGB(120, 170, 255)
local TXT   = Color3.fromRGB(225, 230, 245)
local DIM   = Color3.fromRGB(130, 135, 160)
local GRN   = Color3.fromRGB(70, 210, 110)
local RED   = Color3.fromRGB(230, 70, 70)
local YEL   = Color3.fromRGB(255, 200, 50)
local ON_C  = Color3.fromRGB(50, 170, 90)
local OFF_C = Color3.fromRGB(70, 70, 90)

-- ==================== CORE HELPERS ====================
local function getHRP()
    local c = plr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function alive()
    local c = plr.Character
    return c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") and c:FindFirstChildOfClass("Humanoid").Health > 0
end

local function tp(cf)
    local h = getHRP()
    if h then h.CFrame = cf + Vector3.new(0, 5, 0) end
end

local function fly(pos, off)
    local h = getHRP()
    if not h then return end
    local t = pos + Vector3.new(0, off or 0, 0)
    local d = (t - h.Position).Magnitude
    if d < 2 then return end
    local tw = TweenService:Create(h, TweenInfo.new(math.clamp(d / 200, 0.1, 2.5), Enum.EasingStyle.Linear), {Position = t})
    tw:Play()
    tw.Completed:Wait()
end

-- ==================== OBSERVATION ====================
local function tryActivateObs()
    local ch = plr.Character
    if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local tool = nil

    for _, cont in ipairs({plr:FindFirstChild("Backpack"), ch}) do
        if cont then
            for _, obj in ipairs(cont:GetChildren()) do
                if obj:IsA("Tool") then
                    local n = obj.Name:lower()
                    if n:find("ken") or n:find("obs") or n:find("haki") then
                        tool = obj
                        break
                    end
                end
            end
        end
        if tool then break end
    end

    if not tool then
        local bp = plr:FindFirstChild("Backpack")
        if bp then
            for _, obj in ipairs(bp:GetChildren()) do
                if obj:IsA("Tool") then tool = obj; break end
            end
        end
    end

    if tool then
        hum:EquipTool(tool)
        task.wait(0.4)
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            task.wait(0.08)
            VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
        task.wait(0.3)
    end
end

-- ==================== FIND ENEMY ====================
local function findEnemy()
    local e = workspace:FindFirstChild("Enemies")
    if not e then return nil end
    local h = getHRP()
    if not h then return nil end

    local best, bestS = nil, -1e9
    for _, v in ipairs(e:GetChildren()) do
        local hum = v:FindFirstChild("Humanoid")
        local hrp = v:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 then
            local d = (hrp.Position - h.Position).Magnitude
            if d < 500 and d > bestS then
                bestS = d
                best = v
            end
        end
    end
    return best
end

-- ==================== STATS ====================
local Stats = {
    Start = os.clock(),
    Cycles = 0,
    Target = nil,
    Status = "Idle",
    Obs = "Unknown",
}

-- ==================== UI ====================
local gui = Instance.new("ScreenGui")
gui.Name = "KenUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 460)
frame.Position = UDim2.new(0.5, -140, 0.5, -230)
frame.BackgroundColor3 = BG
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 1
stroke.Color = ACC
stroke.Transparency = 0.5

-- Title
local tb = Instance.new("Frame", frame)
tb.Size = UDim2.new(1, 0, 0, 34)
tb.BackgroundColor3 = BG2
tb.BorderSizePixel = 0
Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 10)

local tf = Instance.new("Frame", tb)
tf.Size = UDim2.new(1, 0, 0, 10)
tf.Position = UDim2.new(0, 0, 1, -10)
tf.BackgroundColor3 = BG2
tf.BorderSizePixel = 0

local tl = Instance.new("TextLabel", tb)
tl.Size = UDim2.new(1, -34, 1, 0)
tl.BackgroundTransparency = 1
tl.Text = "Ken Training v4.0"
tl.TextColor3 = ACC2
tl.Font = Enum.Font.GothamBold
tl.TextSize = 14
tl.TextXAlignment = Enum.TextXAlignment.Left
tl.Position = UDim2.new(0, 10, 0, 0)

local xbtn = Instance.new("TextButton", tb)
xbtn.Size = UDim2.new(0, 24, 0, 24)
xbtn.Position = UDim2.new(1, -28, 0, 5)
xbtn.BackgroundColor3 = RED
xbtn.Text = "X"
xbtn.TextColor3 = Color3.new(1,1,1)
xbtn.Font = Enum.Font.GothamBold
xbtn.TextSize = 11
xbtn.BorderSizePixel = 0
Instance.new("UICorner", xbtn).CornerRadius = UDim.new(0, 5)

-- Content
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, -12, 1, -40)
scroll.Position = UDim2.new(0, 6, 0, 38)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = ACC
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 4)
Instance.new("UIPadding", scroll).PaddingBottom = UDim.new(0, 6)

-- ==================== UI BUILDERS ====================
local function section(parent, text)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, 0, 0, 22)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = ACC2
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function label(parent, text)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, 0, 0, 18)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = TXT
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local function divider(parent)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 1)
    f.BackgroundColor3 = BG3
    f.BorderSizePixel = 0
end

local function btn(parent, text, cb)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, 0, 0, 30)
    b.BackgroundColor3 = ACC
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(cb)
end

local function toggle(parent, text, def, cb)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, 0, 0, 32)
    fr.BackgroundColor3 = BG3
    fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel", fr)
    l.Size = UDim2.new(1, -52, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = TXT
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left

    local tog = Instance.new("TextButton", fr)
    tog.Size = UDim2.new(0, 42, 0, 20)
    tog.Position = UDim2.new(1, -50, 0.5, -10)
    tog.BorderSizePixel = 0
    tog.Text = ""
    Instance.new("UICorner", tog).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", tog)
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local s = def or false
    local function upd()
        tog.BackgroundColor3 = s and ON_C or OFF_C
        TweenService:Create(dot, TweenInfo.new(0.12), {
            Position = s and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        }):Play()
    end
    upd()
    tog.MouseButton1Click:Connect(function() s = not s; upd(); if cb then cb(s) end end)
    return {Set = function(_, v) s = v; upd() end}
end

local function slider(parent, text, mn, mx, def, cb)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, 0, 0, 42)
    fr.BackgroundColor3 = BG3
    fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel", fr)
    l.Size = UDim2.new(1, -46, 0, 18)
    l.Position = UDim2.new(0, 10, 0, 3)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = TXT
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left

    local vl = Instance.new("TextLabel", fr)
    vl.Size = UDim2.new(0, 36, 0, 18)
    vl.Position = UDim2.new(1, -44, 0, 3)
    vl.BackgroundTransparency = 1
    vl.Text = tostring(def)
    vl.TextColor3 = ACC2
    vl.Font = Enum.Font.GothamBold
    vl.TextSize = 12
    vl.TextXAlignment = Enum.TextXAlignment.Right

    local bg = Instance.new("Frame", fr)
    bg.Size = UDim2.new(1, -20, 0, 5)
    bg.Position = UDim2.new(0, 10, 0, 28)
    bg.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", bg)
    fill.Size = UDim2.new((def - mn) / (mx - mn), 0, 1, 0)
    fill.BackgroundColor3 = ACC
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local hit = Instance.new("TextButton", bg)
    hit.Size = UDim2.new(1, 0, 0, 16)
    hit.Position = UDim2.new(0, 0, 0.5, -8)
    hit.BackgroundTransparency = 1
    hit.Text = ""

    local cur = def
    local drag = false
    hit.MouseButton1Down:Connect(function() drag = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local x = math.clamp((i.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
            cur = math.floor(mn + (mx - mn) * x + 0.5)
            fill.Size = UDim2.new((cur - mn) / (mx - mn), 0, 1, 0)
            vl.Text = tostring(cur)
            if cb then cb(cur) end
        end
    end)
    return {Get = function() return cur end}
end

local function dropdown(parent, text, opts, def, cb)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, 0, 0, 32)
    fr.BackgroundColor3 = BG3
    fr.BorderSizePixel = 0
    fr.ZIndex = 5
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel", fr)
    l.Size = UDim2.new(0.35, 0, 1, 0)
    l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = TXT
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 5

    local sel = Instance.new("TextButton", fr)
    sel.Size = UDim2.new(0.6, -6, 0, 22)
    sel.Position = UDim2.new(0.38, 0, 0.5, -11)
    sel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    sel.Text = def
    sel.TextColor3 = ACC2
    sel.Font = Enum.Font.GothamMedium
    sel.TextSize = 11
    sel.TextTruncate = Enum.TextTruncate.AtEnd
    sel.BorderSizePixel = 0
    sel.ZIndex = 5
    Instance.new("UICorner", sel).CornerRadius = UDim.new(0, 5)

    local list = Instance.new("ScrollingFrame", fr)
    list.Size = UDim2.new(1, -4, 0, 150)
    list.Position = UDim2.new(0, 2, 0, 34)
    list.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 10
    list.ScrollBarThickness = 3
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)
    Instance.new("UIListLayout", list).Padding = UDim.new(0, 1)

    for _, o in ipairs(opts) do
        local ob = Instance.new("TextButton", list)
        ob.Size = UDim2.new(1, 0, 0, 22)
        ob.BackgroundColor3 = (o == def) and BG3 or Color3.fromRGB(25, 25, 40)
        ob.Text = o
        ob.TextColor3 = (o == def) and ACC2 or TXT
        ob.Font = Enum.Font.GothamMedium
        ob.TextSize = 11
        ob.BorderSizePixel = 0
        ob.ZIndex = 11
        ob.MouseButton1Click:Connect(function()
            sel.Text = o
            list.Visible = false
            if cb then cb(o) end
        end)
    end

    sel.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
end

-- ==================== BUILD UI ====================
-- 1. LOCATION
section(scroll, "Location")

local locOpts = {}
for _, l in ipairs(locations) do table.insert(locOpts, l[1]) end

dropdown(scroll, "Place", locOpts, C.Location, function(v) C.Location = v end)
btn(scroll, "Teleport", function() tp(getLocCF(C.Location)) end)

divider(scroll)

-- 2. OBSERVATION
section(scroll, "Observation")
btn(scroll, "Activate Observation", function()
    Stats.Obs = "Activating..."
    task.wait(0.1)
    tryActivateObs()
    Stats.Obs = "Attempted"
end)

divider(scroll)

-- 3. TRAINING
section(scroll, "Training")

local togAuto = toggle(scroll, "Auto Ken Training (N)", false, function(s)
    C.AutoKen = s
    Stats.Status = s and "Starting..." or "Stopped"
    if not s then Stats.Target = nil end
end)

divider(scroll)

-- 4. STATUS
section(scroll, "Status")
local lStatus = label(scroll, "Status: Idle")
local lObs    = label(scroll, "Obs: Unknown")
local lTarget = label(scroll, "Target: None")
local lCycles = label(scroll, "Cycles: 0")
local lTime   = label(scroll, "Time: 0m 0s")
local lLoc    = label(scroll, "Location: Prison")

divider(scroll)

-- 5. SETTINGS
section(scroll, "Settings")
slider(scroll, "Stay near enemy", 2, 8, 4, function(v) C.StayTime = v end)
slider(scroll, "Recharge wait", 8, 20, 14, function(v) C.RechargeTime = v end)
slider(scroll, "Safe range", 8, 30, 15, function(v) C.SafeRange = v end)

-- ==================== CIRCLE ====================
local cGui = Instance.new("ScreenGui")
cGui.Name = "KenCircle"
cGui.ResetOnSpawn = false
cGui.Parent = CoreGui

local circ = Instance.new("TextButton", cGui)
circ.Size = UDim2.new(0, 50, 0, 50)
circ.Position = UDim2.new(0.93, 0, 0.82, 0)
circ.Text = "K"
circ.Font = Enum.Font.GothamBold
circ.TextSize = 24
circ.TextColor3 = Color3.fromRGB(180, 210, 255)
circ.BackgroundColor3 = BG
circ.BackgroundTransparency = 0.15
circ.BorderSizePixel = 0
circ.Active = true
circ.Draggable = true
Instance.new("UICorner", circ).CornerRadius = UDim.new(1, 0)

local cs = Instance.new("UIStroke", circ)
cs.Thickness = 1.5
cs.Color = ACC
cs.Transparency = 0.4

xbtn.MouseButton1Click:Connect(function() frame.Visible = false end)
circ.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)

spawn(function()
    while circ and circ.Parent do
        if C.AutoKen then
            local a = math.abs(math.sin(os.clock() * 3))
            cs.Transparency = 0.05 + a * 0.3
            cs.Thickness = 1.5 + a
            circ.TextTransparency = 0.05
            circ.Text = string.char(9679)
        else
            cs.Transparency = 0.4
            cs.Thickness = 1.5
            circ.TextTransparency = 0.3
            circ.Text = "K"
        end
        task.wait(0.05)
    end
end)

-- ==================== KEYBIND ====================
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.N then
        C.AutoKen = not C.AutoKen
        Stats.Status = C.AutoKen and "Starting..." or "Stopped"
        if not C.AutoKen then Stats.Target = nil end
        pcall(function() togAuto:Set(C.AutoKen) end)
    end
end)

-- ==================== STATS ====================
spawn(function()
    while task.wait(0.5) do
        local e = os.clock() - Stats.Start
        pcall(function()
            lStatus.Text = "Status: " .. Stats.Status
            lObs.Text = "Obs: " .. Stats.Obs
            lTarget.Text = "Target: " .. (Stats.Target and Stats.Target.Name or "None")
            lCycles.Text = "Cycles: " .. Stats.Cycles
            lTime.Text = "Time: " .. math.floor(e/60) .. "m " .. math.floor(e%60) .. "s"
            lLoc.Text = "Location: " .. C.Location
        end)
    end
end)

-- ==================== MAIN LOOP ====================
spawn(function()
    while true do
        task.wait(0.2)
        if not C.AutoKen then task.wait(0.5) continue end

        local ok, err = pcall(function()
            if not alive() then
                Stats.Status = "Waiting for character..."
                task.wait(1)
                return
            end

            Stats.Status = "Activating Obs..."
            tryActivateObs()
            task.wait(0.5)

            Stats.Status = "Teleporting..."
            tp(getLocCF(C.Location))
            task.wait(2)

            Stats.Status = "Ready. Finding enemy..."

            while C.AutoKen do
                if not alive() then
                    Stats.Status = "Dead, waiting..."
                    task.wait(3)
                    continue
                end

                local ch = plr.Character
                local hrp = ch.HumanoidRootPart

                local target = findEnemy()
                if not target then
                    Stats.Status = "No enemies, waiting..."
                    task.wait(1)
                    continue
                end

                Stats.Target = target
                Stats.Status = "Approaching " .. target.Name

                pcall(function()
                    fly(target.HumanoidRootPart.Position, 2)
                end)
                task.wait(0.3)

                Stats.Status = "Dodging attacks (" .. C.StayTime .. "s)"
                local t0 = os.clock()
                while os.clock() - t0 < C.StayTime and C.AutoKen do
                    pcall(function()
                        if alive() and target and target.Parent and target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
                            local tp2 = target.HumanoidRootPart.Position
                            local d = (tp2 - hrp.Position).Magnitude
                            if d > C.SafeRange then
                                hrp.CFrame = CFrame.new(tp2 + Vector3.new(0, 3, 0))
                            end
                            hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(tp2.X, hrp.Position.Y, tp2.Z))
                        end
                    end)
                    task.wait(0.15)
                end

                if not C.AutoKen then break end

                Stats.Status = "Flying up to recharge..."
                pcall(function()
                    if target and target.Parent and target:FindFirstChild("HumanoidRootPart") then
                        fly(target.HumanoidRootPart.Position, 60)
                    end
                end)

                Stats.Status = "Recharging (" .. C.RechargeTime .. "s)..."
                task.wait(C.RechargeTime)

                Stats.Cycles = Stats.Cycles + 1
                Stats.Status = "Cycle " .. Stats.Cycles .. " done"
                task.wait(0.3)
            end
        end)

        if not ok then
            warn("[Ken] " .. tostring(err))
            Stats.Status = "Error"
            task.wait(2)
        end
    end
end)

-- ==================== INIT ====================
StarterGui:SetCore("SendNotification", {
    Title = "Ken Training v4.0",
    Text = "N = toggle | K = menu",
    Duration = 4,
})
print("[Ken] v4.0 loaded")
