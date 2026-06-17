--===================================================================================--
--                    AUTO CHEST FARM + CHALICE DETECTOR                              --
--                    Blox Fruits — Dmitri Kotakbass                                   --
--                    EXECUTOR: XENON / DELTA / MULTI-API                              --
--===================================================================================--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local plr = Players.LocalPlayer
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

--===================================================================================--
--                              CONFIG                                                --
--===================================================================================--

local Config = {
    AutoChest = false,
    AutoChaliceSearch = false,
    ChestRange = 5000,
    CollectDelay = 1.5,
    MoveSpeed = 300,
    ChaliceCheckInterval = 3,
    ChaliceSpawnInterval = 14400, -- 4 hours in seconds
}

--===================================================================================--
--                              STATS                                                 --
--===================================================================================--

local Stats = {
    ChestsCollected = 0,
    MoneyEarned = 0,
    StartTime = os.clock(),
    ChaliceFound = false,
    ChaliceTimerLeft = 0,
    ChaliceLastSpawn = 0,
    Status = "Idle",
    LastChestType = "None",
}

--===================================================================================--
--                              CHEST TYPES                                          --
--===================================================================================--

local ChestPriority = {
    ["DiamondChest"] = {priority = 1, money = 10000, name = "Diamond"},
    ["GoldChest"] = {priority = 2, money = 4500, name = "Gold"},
    ["SilverChest"] = {priority = 3, money = 1300, name = "Silver"},
    ["Chest"] = {priority = 3, money = 1300, name = "Silver"},
}

local ExcludedChests = {
    "MirageChest",
    "FragmentChest",
    "CursedChest",
    "Mirage Chest",
    "Fragment Chest",
    "Cursed Chest",
}

--===================================================================================--
--                              CORE HELPERS                                          --
--===================================================================================--

local function getHRP()
    local c = plr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function alive()
    local c = plr.Character
    return c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") and c:FindFirstChildOfClass("Humanoid").Health > 0
end

local function playSound(id, vol)
    task.spawn(function()
        pcall(function()
            local s = Instance.new("Sound")
            s.SoundId = id
            s.Volume = vol or 0.5
            s.Parent = SoundService
            s:Play()
            game:GetService("Debris"):AddItem(s, 3)
        end)
    end)
end

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 4,
        })
    end)
end

--===================================================================================--
--                              CHEST SCANNER                                         --
--===================================================================================--

local function isExcluded(chestName)
    for _, excluded in ipairs(ExcludedChests) do
        if chestName:find(excluded) then
            return true
        end
    end
    return false
end

local function getChestType(chestName)
    for pattern, data in pairs(ChestPriority) do
        if chestName:find(pattern) then
            return data
        end
    end
    return {priority = 4, money = 1000, name = "Unknown"}
end

local function findChests()
    local chests = {}
    local hrp = getHRP()
    if not hrp then return chests end

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name:find("Chest") then
            if not isExcluded(obj.Name) then
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

    table.sort(chests, function(a, b)
        if a.priority == b.priority then
            return a.distance < b.distance
        end
        return a.priority < b.priority
    end)

    return chests
end

--===================================================================================--
--                              MOVEMENT                                              --
--===================================================================================--

local function tweenTo(targetPos, offset)
    local hrp = getHRP()
    if not hrp then return false end

    local pos = targetPos + Vector3.new(0, offset or 3, 0)
    local dist = (pos - hrp.Position).Magnitude
    if dist < 2 then return true end

    local duration = math.clamp(dist / Config.MoveSpeed, 0.2, 3)
    local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Position = pos})
    tween:Play()
    tween.Completed:Wait()
    task.wait(0.2)
    return true
end

--===================================================================================--
--                              CHEST COLLECTOR                                       --
--===================================================================================--

local function collectChest(chest)
    if not chest or not chest.part or not chest.part.Parent then
        return false
    end

    Stats.Status = "Moving to " .. chest.name .. " Chest (" .. math.floor(chest.distance) .. "m)"

    local success = tweenTo(chest.part.Position, 2)
    if not success then
        return false
    end

    task.wait(Config.CollectDelay)

    Stats.ChestsCollected = Stats.ChestsCollected + 1
    Stats.MoneyEarned = Stats.MoneyEarned + chest.money
    Stats.LastChestType = chest.name
    Stats.Status = "Collected " .. chest.name .. " (+$" .. chest.money .. ")"

    playSound("rbxassetid://6042053332", 0.3)

    return true
end

--===================================================================================--
--                              CHALICE DETECTOR                                      --
--===================================================================================--

local function checkChaliceInInventory()
    local found = false

    pcall(function()
        if plr.Backpack:FindFirstChild("God's Chalice") then
            found = true
        end
        if plr.Character and plr.Character:FindFirstChild("God's Chalice") then
            found = true
        end
    end)

    return found
end

local function updateChaliceTimer()
    local elapsed = os.clock() - Stats.ChaliceLastSpawn
    local remaining = Config.ChaliceSpawnInterval - elapsed

    if remaining <= 0 then
        Stats.ChaliceTimerLeft = 0
        return true
    else
        Stats.ChaliceTimerLeft = remaining
        return false
    end
end

local function checkChalice()
    if checkChaliceInInventory() then
        if not Stats.ChaliceFound then
            Stats.ChaliceFound = true
            playSound("rbxassetid://6042053886", 0.8)
            notify("GOD'S CHALICE FOUND!", "Check your inventory!", 6)
        end
        return true
    end
    return false
end

--===================================================================================--
--                              CHALICE SCAANNER IN CHESTS                            --
--===================================================================================--

local function scanForChaliceChest()
    local hrp = getHRP()
    if not hrp then return nil end

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name:find("Chest") then
            if not isExcluded(obj.Name) then
                local dist = (obj.Position - hrp.Position).Magnitude
                if dist <= Config.ChestRange then
                    return obj
                end
            end
        end
    end
    return nil
end

--===================================================================================--
--                              UI                                                    --
--===================================================================================--

local gui = Instance.new("ScreenGui")
gui.Name = "ChestFarmUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

local BG = Color3.fromRGB(20, 20, 32)
local BG2 = Color3.fromRGB(28, 28, 46)
local BG3 = Color3.fromRGB(35, 35, 55)
local ACC = Color3.fromRGB(80, 140, 255)
local ACC2 = Color3.fromRGB(120, 170, 255)
local TXT = Color3.fromRGB(225, 230, 245)
local GREEN = Color3.fromRGB(50, 170, 90)
local RED = Color3.fromRGB(230, 70, 70)
local GOLD = Color3.fromRGB(255, 215, 0)
local ON_C = Color3.fromRGB(50, 170, 90)
local OFF_C = Color3.fromRGB(70, 70, 90)

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 420)
frame.Position = UDim2.new(0.5, -130, 0.5, -210)
frame.BackgroundColor3 = BG
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 1
stroke.Color = GOLD
stroke.Transparency = 0.5

-- Title Bar
local tb = Instance.new("Frame", frame)
tb.Size = UDim2.new(1, 0, 0, 32)
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
tl.Text = "CHEST FARM + CHALICE"
tl.TextColor3 = GOLD
tl.Font = Enum.Font.GothamBold
tl.TextSize = 12
tl.TextXAlignment = Enum.TextXAlignment.Left
tl.Position = UDim2.new(0, 10, 0, 0)

local xbtn = Instance.new("TextButton", tb)
xbtn.Size = UDim2.new(0, 22, 0, 22)
xbtn.Position = UDim2.new(1, -26, 0, 5)
xbtn.BackgroundColor3 = RED
xbtn.Text = "X"
xbtn.TextColor3 = Color3.new(1,1,1)
xbtn.Font = Enum.Font.GothamBold
xbtn.TextSize = 10
xbtn.BorderSizePixel = 0
Instance.new("UICorner", xbtn).CornerRadius = UDim.new(0, 5)

-- Toggle Button (Circle)
local circGui = Instance.new("ScreenGui")
circGui.Name = "ChestFarmCircle"
circGui.ResetOnSpawn = false
circGui.Parent = CoreGui

local circ = Instance.new("TextButton", circGui)
circ.Size = UDim2.new(0, 45, 0, 45)
circ.Position = UDim2.new(0.93, 0, 0.75, 0)
circ.Text = "C"
circ.Font = Enum.Font.GothamBold
circ.TextSize = 18
circ.TextColor3 = GOLD
circ.BackgroundColor3 = BG
circ.BackgroundTransparency = 0.15
circ.BorderSizePixel = 0
circ.Active = true
circ.Draggable = true
Instance.new("UICorner", circ).CornerRadius = UDim.new(1, 0)

local cs = Instance.new("UIStroke", circ)
cs.Thickness = 1.5
cs.Color = GOLD
cs.Transparency = 0.4

-- Scroll Frame
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, -12, 1, -38)
scroll.Position = UDim2.new(0, 6, 0, 35)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = GOLD
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 4)
Instance.new("UIPadding", scroll).PaddingBottom = UDim.new(0, 6)

-- UI Helpers
local function section(parent, text)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, 0, 0, 20)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = GOLD
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function label(parent, text)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, 0, 0, 17)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = TXT
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local function divider(parent)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 1)
    f.BackgroundColor3 = BG3
    f.BorderSizePixel = 0
end

local function toggle(parent, text, def, cb)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, 0, 0, 28)
    fr.BackgroundColor3 = BG3
    fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel", fr)
    l.Size = UDim2.new(1, -50, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = TXT
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left

    local tog = Instance.new("TextButton", fr)
    tog.Size = UDim2.new(0, 40, 0, 18)
    tog.Position = UDim2.new(1, -48, 0.5, -9)
    tog.BorderSizePixel = 0
    tog.Text = ""
    Instance.new("UICorner", tog).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", tog)
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local s = def or false
    local function upd()
        tog.BackgroundColor3 = s and ON_C or OFF_C
        TweenService:Create(dot, TweenInfo.new(0.12), {
            Position = s and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        }):Play()
    end
    upd()
    tog.MouseButton1Click:Connect(function() s = not s; upd(); if cb then cb(s) end end)
    return {Set = function(_, v) s = v; upd() end}
end

local function btn(parent, text, cb)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, 0, 0, 28)
    b.BackgroundColor3 = ACC
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(cb)
end

--===================================================================================--
--                              BUILD UI                                              --
--===================================================================================--

section(scroll, "Chest Farm")

local togChest = toggle(scroll, "Auto Chest Farm", false, function(s)
    Config.AutoChest = s
    Stats.Status = s and "Starting..." or "Stopped"
    if not s then
        Stats.Status = "Stopped"
    end
end)

divider(scroll)

section(scroll, "Chalice")

local togChalice = toggle(scroll, "Auto Chalice Search", false, function(s)
    Config.AutoChaliceSearch = s
    if s then
        Stats.ChaliceLastSpawn = os.clock()
    end
end)

divider(scroll)

section(scroll, "Statistics")

local lStatus = label(scroll, "Status: Idle")
local lChests = label(scroll, "Chests: 0")
local lMoney = label(scroll, "Money: $0")
local lChalice = label(scroll, "Chalice: Not found")
local lTimer = label(scroll, "Chalice Timer: 4:00:00")
local lTime = label(scroll, "Time: 0m 0s")

divider(scroll)

section(scroll, "Actions")

btn(scroll, "Find Nearest Chest", function()
    local chests = findChests()
    if #chests > 0 then
        Stats.Status = "Nearest: " .. chests[1].name .. " (" .. math.floor(chests[1].distance) .. "m)"
    else
        Stats.Status = "No chests found"
    end
end)

btn(scroll, "Teleport to Chest", function()
    local chests = findChests()
    if #chests > 0 then
        spawn(function()
            collectChest(chests[1])
        end)
    else
        Stats.Status = "No chests found"
    end
end)

btn(scroll, "Reset Chalice Timer", function()
    Stats.ChaliceLastSpawn = os.clock()
    Stats.ChaliceFound = false
    Stats.Status = "Chalice timer reset"
end)

--===================================================================================--
--                              ANIMATION                                             --
--===================================================================================--

xbtn.MouseButton1Click:Connect(function() frame.Visible = false end)
circ.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)

spawn(function()
    while circ and circ.Parent do
        if Config.AutoChest or Config.AutoChaliceSearch then
            local a = math.abs(math.sin(os.clock() * 3))
            cs.Transparency = 0.05 + a * 0.3
            cs.Thickness = 1.5 + a
            circ.TextTransparency = 0.05
            circ.Text = string.char(9679)
        else
            cs.Transparency = 0.4
            cs.Thickness = 1.5
            circ.TextTransparency = 0.3
            circ.Text = "C"
        end
        task.wait(0.05)
    end
end)

--===================================================================================--
--                              KEYBIND                                               --
--===================================================================================--

game:GetService("UserInputService").InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.C then
        Config.AutoChest = not Config.AutoChest
        Stats.Status = Config.AutoChest and "Starting..." or "Stopped"
        pcall(function() togChest:Set(Config.AutoChest) end)
    end
end)

--===================================================================================--
--                              STATS UPDATER                                         --
--===================================================================================--

spawn(function()
    while task.wait(0.5) do
        local elapsed = os.clock() - Stats.StartTime
        local mins = math.floor(elapsed / 60)
        local secs = math.floor(elapsed % 60)

        pcall(function()
            lStatus.Text = "Status: " .. Stats.Status
            lChests.Text = "Chests: " .. Stats.ChestsCollected
            lMoney.Text = "Money: $" .. tostring(Stats.MoneyEarned):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
            lChalice.Text = "Chalice: " .. (Stats.ChaliceFound and "FOUND!" or "Not found")
            lChalice.TextColor3 = Stats.ChaliceFound and GOLD or TXT

            local timerMins = math.floor(Stats.ChaliceTimerLeft / 3600)
            local timerSecs = math.floor((Stats.ChaliceTimerLeft % 3600) / 60)
            local timerHrs = math.floor(Stats.ChaliceTimerLeft / 3600)
            lTimer.Text = string.format("Chalice Timer: %d:%02d:%02d", timerHrs, timerSecs, timerMins % 60)

            if Stats.ChaliceTimerLeft <= 0 and Config.AutoChaliceSearch then
                lTimer.Text = "Chalice Timer: AVAILABLE NOW!"
                lTimer.TextColor3 = GREEN
            else
                lTimer.TextColor3 = TXT
            end

            lTime.Text = string.format("Time: %dm %ds", mins, secs)
        end)
    end
end)

--===================================================================================--
--                              MAIN CHEST FARM LOOP                                  --
--===================================================================================--

spawn(function()
    while true do
        task.wait(0.3)

        if not Config.AutoChest then
            task.wait(0.5)
            continue
        end

        if not alive() then
            Stats.Status = "Waiting for character..."
            task.wait(1)
            continue
        end

        local ok, err = pcall(function()
            while Config.AutoChest do
                if not alive() then
                    Stats.Status = "Dead, waiting..."
                    task.wait(3)
                    continue
                end

                local chests = findChests()
                if #chests == 0 then
                    Stats.Status = "No chests found, scanning..."
                    task.wait(2)
                    continue
                end

                for _, chest in ipairs(chests) do
                    if not Config.AutoChest then break end
                    if not alive() then break end

                    if chest.part and chest.part.Parent then
                        collectChest(chest)
                        task.wait(0.3)
                    end
                end

                task.wait(0.5)
            end
        end)

        if not ok then
            warn("[ChestFarm] " .. tostring(err))
            Stats.Status = "Error"
            task.wait(2)
        end
    end
end)

--===================================================================================--
--                              MAIN CHALICE LOOP                                     --
--===================================================================================--

spawn(function()
    Stats.ChaliceLastSpawn = os.clock()

    while true do
        task.wait(Config.ChaliceCheckInterval)

        if not Config.AutoChaliceSearch then
            continue
        end

        if not alive() then
            continue
        end

        pcall(function()
            updateChaliceTimer()
            checkChalice()
        end)
    end
end)

--===================================================================================--
--                              INIT                                                  --
--===================================================================================--

StarterGui:SetCore("SendNotification", {
    Title = "Chest Farm + Chalice",
    Text = "C = toggle | Click circle for menu",
    Duration = 4,
})

print("[ChestFarm] Loaded — Auto Chest + Chalice Detection")
