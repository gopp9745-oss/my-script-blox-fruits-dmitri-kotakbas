--===================================================================================--
--                    BLOX FRUITS — Dmitri Kotakbass                                   --
--                    NATIVE GUI (no external dependencies)                            --
--===================================================================================--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local plr = Players.LocalPlayer

local guiParent = plr:WaitForChild("PlayerGui")
pcall(function()
    local cg = game:GetService("CoreGui")
    if cg then guiParent = cg end
end)

local CommF
pcall(function() CommF = ReplicatedStorage.Remotes.CommF_ end)
local RigEvent
pcall(function() RigEvent = ReplicatedStorage.RigControllerEvent end)
local Validator
pcall(function() Validator = ReplicatedStorage.Remotes.Validator end)

--- CombatFramework init
local CbFw2, cfOK
pcall(function()
    CbFw2 = debug.getupvalues(require(plr.PlayerScripts.CombatFramework))[2]
    cfOK = true
end)

local function fastAtk()
    if not cfOK then return false end
    local ok, ac = pcall(function() return CbFw2.activeController end)
    if not ok or not ac then return false end
    local ok2, hits = pcall(function()
        return require(game.ReplicatedStorage.CombatFramework.RigLib).getBladeHits(plr.Character, {plr.Character.HumanoidRootPart}, 60)
    end)
    if not ok2 then return false end
    local filtered, seen = {}, {}
    for _, v in pairs(hits) do
        local p = v.Parent
        if p and p:FindFirstChild("HumanoidRootPart") and not seen[p] then
            table.insert(filtered, p.HumanoidRootPart)
            seen[p] = true
        end
    end
    if #filtered == 0 then return false end
    local ok3, u4, u5, u6, u7 = pcall(function()
        return debug.getupvalue(ac.attack, 4), debug.getupvalue(ac.attack, 5), debug.getupvalue(ac.attack, 6), debug.getupvalue(ac.attack, 7)
    end)
    if not ok3 then return false end
    local r1 = (u5 * 798405 + u4 * 727595) % u6
    r1 = (r1 * u6 + u4 * 798405) % 1099511627776
    u5 = math.floor(r1 / u6)
    u4 = r1 - u5 * u6
    u7 = u7 + 1
    pcall(function()
        debug.setupvalue(ac.attack, 4, u4)
        debug.setupvalue(ac.attack, 5, u5)
        debug.setupvalue(ac.attack, 6, u6)
        debug.setupvalue(ac.attack, 7, u7)
    end)
    local tool = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function()
            local blade = CbFw2.activeController.blades and CbFw2.activeController.blades[1]
            if blade then
                while blade.Parent ~= plr.Character do blade = blade.Parent end
                if RigEvent then RigEvent:FireServer("weaponChange", tostring(blade)) end
            end
        end)
        pcall(function()
            if Validator then Validator:FireServer(math.floor(r1 / 1099511627776 * 16777215), u7) end
            if RigEvent then RigEvent:FireServer("hit", filtered, 1, "") end
        end)
    end
    pcall(function()
        ac.timeToNextAttack = 0
        ac.attacking = false
        ac.hitboxMagnitude = 150
    end)
    return true
end

local function click()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0, 1))
    end)
end

local function atk()
    local used = fastAtk()
    if not used then
        for _ = 1, 5 do pcall(click) task.wait(0.015) end
    end
end

--- Movement
local function fly(pos)
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local d = (pos - hrp.Position).Magnitude
    if d < 1 then return end
    local tw = TweenService:Create(hrp, TweenInfo.new(math.clamp(d / 300, 0.2, 2.5), Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    tw:Play()
    tw.Completed:Wait()
end

--- Enemies
local function getEnemies()
    local e = workspace:FindFirstChild("Enemies")
    if not e then return {} end
    local list = {}
    for _, v in pairs(e:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            table.insert(list, v)
        end
    end
    return list
end

local lvlMap = {
    {0,15,"Jungle", CFrame.new(-1242,30,-452)},
    {15,35,"Pirate Village", CFrame.new(-1120,15,510)},
    {35,65,"Desert", CFrame.new(840,25,1250)},
    {65,95,"Frozen Village", CFrame.new(820,70,-1590)},
    {95,125,"Marine Fortress", CFrame.new(-920,40,3320)},
    {125,155,"Sky Island 1", CFrame.new(-5100,320,530)},
    {155,230,"Sky Island 2", CFrame.new(-7900,550,530)},
    {230,300,"Prison", CFrame.new(4900,8,900)},
    {300,375,"Magma Village", CFrame.new(-5300,15,1300)},
    {375,450,"Graveyard", CFrame.new(-2950,50,-3650)},
    {450,525,"Snow Mountain", CFrame.new(550,90,-2220)},
    {525,625,"Fishman Island", CFrame.new(550,125,2820)},
    {625,700,"Mansion", CFrame.new(-12700,380,-500)},
    {700,850,"Sea of Treats", CFrame.new(622,25,3970)},
    {850,950,"Fountain City", CFrame.new(5160,20,3020)},
    {950,1100,"Hydra Island", CFrame.new(5550,25,-520)},
    {1100,1300,"Great Tree", CFrame.new(8700,130,1750)},
    {1300,1475,"Castle on the Sea", CFrame.new(-5300,20,7000)},
    {1475,2000,"Haunted Castle", CFrame.new(-9500,145,6150)},
}

local function getArea()
    local lvl = plr.Data.Level.Value
    for _, a in pairs(lvlMap) do
        if lvl >= a[1] and lvl <= a[2] then return a end
    end
    return lvlMap[#lvlMap]
end

local function equipWeapon()
    local char = plr.Character
    if not char then return end
    local best = char:FindFirstChildOfClass("Tool")
    if (not best or not best:FindFirstChildOfClass("Handle")) then
        for _, v in pairs(plr.Backpack:GetChildren()) do
            if v:IsA("Tool") then best = v; break end
        end
    end
    if best then pcall(function() char.Humanoid:EquipTool(best) end) end
end

local function acceptQuest()
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, q in pairs(workspace:GetDescendants()) do
        if q:IsA("Model") and q.Name:lower():match("quest") and q:FindFirstChild("HumanoidRootPart") then
            local d = (q.HumanoidRootPart.Position - hrp.Position).Magnitude
            if d < 25 then
                local p = q:FindFirstChildWhichIsA("ProximityPrompt")
                if p then pcall(function() fireproximityprompt(p) end); task.wait(0.2) end
            end
        end
    end
end

--- Bring enemy
_G.Bring = false
RunService.Heartbeat:Connect(function()
    if _G.Bring and _G.Target then
        pcall(function()
            local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                _G.Target.HumanoidRootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 15, -10))
            end
        end)
    end
end)

--===================================================================================--
--                              NATIVE UI FRAMEWORK                                   --
--===================================================================================--

local BG = Color3.fromRGB(20, 20, 32)
local BG2 = Color3.fromRGB(28, 28, 46)
local BG3 = Color3.fromRGB(35, 35, 55)
local ACC = Color3.fromRGB(80, 140, 255)
local TXT = Color3.fromRGB(225, 230, 245)
local GREEN = Color3.fromRGB(50, 170, 90)
local RED = Color3.fromRGB(230, 70, 70)
local GOLD = Color3.fromRGB(255, 215, 0)
local ON_C = Color3.fromRGB(50, 170, 90)
local OFF_C = Color3.fromRGB(70, 70, 90)

local mainGui = Instance.new("ScreenGui")
mainGui.Name = "BloxFruitsUI"
mainGui.ResetOnSpawn = false
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 460)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -230)
mainFrame.BackgroundColor3 = BG
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = mainGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
local mStroke = Instance.new("UIStroke", mainFrame)
mStroke.Thickness = 1
mStroke.Color = ACC
mStroke.Transparency = 0.5

local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = BG2
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleFill = Instance.new("Frame", titleBar)
titleFill.Size = UDim2.new(1, 0, 0, 10)
titleFill.Position = UDim2.new(0, 0, 1, -10)
titleFill.BackgroundColor3 = BG2
titleFill.BorderSizePixel = 0

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1, -60, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Blox Fruits - Dmitri Kotakbass"
titleText.TextColor3 = ACC
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 12
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Position = UDim2.new(0, 10, 0, 0)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -26, 0, 4)
closeBtn.BackgroundColor3 = RED
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 10
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)

local tabBar = Instance.new("Frame", mainFrame)
tabBar.Size = UDim2.new(1, -10, 0, 28)
tabBar.Position = UDim2.new(0, 5, 0, 33)
tabBar.BackgroundColor3 = BG2
tabBar.BorderSizePixel = 0
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 6)

local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.new(1, -10, 1, -70)
contentFrame.Position = UDim2.new(0, 5, 0, 66)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0

local tabs = {}
local tabButtons = {}
local currentTab = nil

local function createTab(name, index)
    local page = Instance.new("ScrollingFrame", contentFrame)
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = ACC
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 3)
    Instance.new("UIPadding", page).PaddingBottom = UDim.new(0, 6)
    tabs[name] = page

    local btn = Instance.new("TextButton", tabBar)
    btn.Size = UDim2.new(0, 60, 1, -4)
    btn.Position = UDim2.new(0, (index - 1) * 63 + 2, 0, 2)
    btn.BackgroundColor3 = BG3
    btn.Text = name
    btn.TextColor3 = TXT
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    tabButtons[name] = btn

    btn.MouseButton1Click:Connect(function()
        if currentTab then
            tabs[currentTab].Visible = false
            tabButtons[currentTab].BackgroundColor3 = BG3
        end
        currentTab = name
        page.Visible = true
        btn.BackgroundColor3 = ACC
    end)

    return page
end

local function switchTab(name)
    if currentTab then
        tabs[currentTab].Visible = false
        tabButtons[currentTab].BackgroundColor3 = BG3
    end
    currentTab = name
    tabs[name].Visible = true
    tabButtons[name].BackgroundColor3 = ACC
end

local function addSection(parent, text)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, 0, 0, 20)
    l.BackgroundTransparency = 1
    l.Text = "  " .. text
    l.TextColor3 = GOLD
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function addLabel(parent, text)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, 0, 0, 18)
    l.BackgroundTransparency = 1
    l.Text = "  " .. text
    l.TextColor3 = TXT
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local function addDivider(parent)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 1)
    f.BackgroundColor3 = BG3
    f.BorderSizePixel = 0
end

local function addToggle(parent, text, default, callback)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, 0, 0, 30)
    fr.BackgroundColor3 = BG3
    fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel", fr)
    l.Size = UDim2.new(1, -54, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = TXT
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 11
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

    local state = default or false
    local function update()
        tog.BackgroundColor3 = state and ON_C or OFF_C
        TweenService:Create(dot, TweenInfo.new(0.12), {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        }):Play()
    end
    update()
    tog.MouseButton1Click:Connect(function()
        state = not state
        update()
        if callback then callback(state) end
    end)
    return {Set = function(_, v) state = v; update() end, Get = function() return state end}
end

local function addButton(parent, text, callback)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, 0, 0, 30)
    b.BackgroundColor3 = ACC
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(callback)
end

local function addSlider(parent, text, min, max, default, callback)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, 0, 0, 40)
    fr.BackgroundColor3 = BG3
    fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel", fr)
    l.Size = UDim2.new(1, -46, 0, 18)
    l.Position = UDim2.new(0, 10, 0, 2)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = TXT
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left

    local vl = Instance.new("TextLabel", fr)
    vl.Size = UDim2.new(0, 36, 0, 18)
    vl.Position = UDim2.new(1, -44, 0, 2)
    vl.BackgroundTransparency = 1
    vl.Text = tostring(default)
    vl.TextColor3 = ACC
    vl.Font = Enum.Font.GothamBold
    vl.TextSize = 11
    vl.TextXAlignment = Enum.TextXAlignment.Right

    local bg = Instance.new("Frame", fr)
    bg.Size = UDim2.new(1, -20, 0, 5)
    bg.Position = UDim2.new(0, 10, 0, 26)
    bg.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", bg)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = ACC
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local hit = Instance.new("TextButton", bg)
    hit.Size = UDim2.new(1, 0, 0, 16)
    hit.Position = UDim2.new(0, 0, 0.5, -8)
    hit.BackgroundTransparency = 1
    hit.Text = ""

    local cur = default
    local dragging = false
    hit.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local x = math.clamp((i.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
            cur = math.floor(min + (max - min) * x + 0.5)
            fill.Size = UDim2.new((cur - min) / (max - min), 0, 1, 0)
            vl.Text = tostring(cur)
            if callback then callback(cur) end
        end
    end)
end

--===================================================================================--
--                              CREATE TABS                                           --
--===================================================================================--

local mainTab = createTab("Main", 1)
local statsTab = createTab("Stats", 2)
local teleTab = createTab("Tele", 3)
local miscTab = createTab("Misc", 4)
local chestTab = createTab("Chest", 5)

-- MAIN TAB
addSection(mainTab, "Auto Farm")

addToggle(mainTab, "Auto Farm", false, function(state)
    _G.Farm = state
    while _G.Farm and task.wait(0.1) do
        pcall(function()
            local char = plr.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            equipWeapon()
            local enemies = getEnemies()
            local best, bd = nil, math.huge
            for _, e in pairs(enemies) do
                local d = (e.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < bd then bd = d; best = e end
            end
            if best and bd < 350 then
                _G.Target = best
                if bd > 8 then fly(best.HumanoidRootPart.Position + Vector3.new(0, 22, 0)) end
                hrp.CFrame = CFrame.new(hrp.Position, best.HumanoidRootPart.Position)
                atk()
            else
                _G.Target = nil
            end
        end)
    end
    _G.Target = nil
end)

addToggle(mainTab, "Auto Level", false, function(state)
    _G.LvlFarm = state
    while _G.LvlFarm and task.wait(0.15) do
        pcall(function()
            local char = plr.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            local lvl = plr.Data.Level.Value
            local area = getArea()
            equipWeapon()
            acceptQuest()
            local enemies = getEnemies()
            local target, md = nil, math.huge
            for _, e in pairs(enemies) do
                local el = e:FindFirstChild("Level") and e.Level.Value or lvl
                if math.abs(el - lvl) <= 10 then
                    local d = (e.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < md then md = d; target = e end
                end
            end
            if not target then
                _G.Target = nil
                fly(area[4].Position)
            else
                _G.Target = target
                if md > 8 then fly(target.HumanoidRootPart.Position + Vector3.new(0, 22, 0)) end
                hrp.CFrame = CFrame.new(hrp.Position, target.HumanoidRootPart.Position)
                atk()
            end
        end)
    end
    _G.Target = nil
end)

addToggle(mainTab, "Auto Quest", false, function(state)
    _G.Quest = state
    while _G.Quest and task.wait(0.3) do pcall(acceptQuest) end
end)

addToggle(mainTab, "Bring Enemy", false, function(state)
    _G.Bring = state
    if not state then _G.Target = nil end
end)

-- STATS TAB
addSection(statsTab, "Auto Points")

for _, s in pairs({"Melee","Defense","Sword","Demon Fruit"}) do
    addToggle(statsTab, "Auto " .. s, false, function(state)
        _G["S" .. s:gsub(" ","")] = state
        coroutine.wrap(function()
            while _G["S" .. s:gsub(" ","")] and task.wait(0.3) do
                pcall(function()
                    if plr.Data.StatPoints.Value and plr.Data.StatPoints.Value > 0 then
                        CommF:InvokeServer("AddPoint", s, tonumber(plr.Data.StatPoints.Value))
                    end
                end)
            end
        end)()
    end)
end

addButton(statsTab, "Melee > 1:1:1:1", function()
    pcall(function()
        local p = plr.Data.StatPoints.Value
        if p and p > 0 then
            local each = math.floor(p / 4)
            CommF:InvokeServer("AddPoint", "Melee", each)
            CommF:InvokeServer("AddPoint", "Defense", each)
            CommF:InvokeServer("AddPoint", "Sword", each)
            CommF:InvokeServer("AddPoint", "Demon Fruit", each)
        end
    end)
end)

-- TELEPORT TAB
addSection(teleTab, "Islands")

local islands = {
    {"Jungle", CFrame.new(-1242,30,-452)},
    {"Pirate Village", CFrame.new(-1120,15,510)},
    {"Desert", CFrame.new(840,25,1250)},
    {"Frozen Village", CFrame.new(820,70,-1590)},
    {"Marine Fortress", CFrame.new(-920,40,3320)},
    {"Prison", CFrame.new(4900,8,900)},
    {"Colosseum", CFrame.new(-1420,15,-2940)},
    {"Magma Village", CFrame.new(-5300,15,1300)},
    {"Graveyard", CFrame.new(-2950,50,-3650)},
    {"Snow Mountain", CFrame.new(550,90,-2220)},
    {"Fishman Island", CFrame.new(550,125,2820)},
    {"Mansion", CFrame.new(-12700,380,-500)},
    {"Sea of Treats", CFrame.new(622,25,3970)},
    {"Fountain City", CFrame.new(5160,20,3020)},
    {"Hydra Island", CFrame.new(5550,25,-520)},
    {"Great Tree", CFrame.new(8700,130,1750)},
    {"Castle on the Sea", CFrame.new(-5300,20,7000)},
    {"Haunted Castle", CFrame.new(-9500,145,6150)},
}

for _, d in pairs(islands) do
    addButton(teleTab, d[1], function()
        pcall(function()
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then fly(d[2].Position) end
        end)
    end)
end

-- MISC TAB
addSection(miscTab, "Utilities")

addButton(miscTab, "Rejoin", function() TeleportService:Teleport(game.PlaceId, plr) end)

addButton(miscTab, "Server Hop", function()
    local suc, d = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
    end)
    if suc and d and d.data then
        for _, v in pairs(d.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, plr)
                break
            end
        end
    end
end)

_G.WS = 16
_G.JP = 50
RunService.Heartbeat:Connect(function()
    local char = plr.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = _G.WS
        char.Humanoid.JumpPower = _G.JP
    end
end)
addSlider(miscTab, "Walk Speed", 16, 250, 16, function(s) _G.WS = s end)
addSlider(miscTab, "Jump Power", 50, 500, 50, function(s) _G.JP = s end)

-- CHEST FARM TAB
_G.ChestFarm = false
_G.AutoChalice = false
local chestStats = {collected = 0, money = 0, chaliceFound = false, chaliceTimer = 14400, lastSpawn = os.clock(), status = "Idle"}

addSection(chestTab, "Auto Chest")

local togChestFarm = addToggle(chestTab, "Auto Chest Farm (C)", false, function(state)
    _G.ChestFarm = state
    chestStats.status = state and "Starting..." or "Stopped"
end)

addToggle(chestTab, "Auto Chalice Search", false, function(state)
    _G.AutoChalice = state
    if state then chestStats.lastSpawn = os.clock() end
end)

addDivider(chestTab)
addSection(chestTab, "Status")

local chestStatusLabel = addLabel(chestTab, "Status: Idle")
local chestCountLabel = addLabel(chestTab, "Chests: 0")
local chestMoneyLabel = addLabel(chestTab, "Money: $0")
local chaliceLabel = addLabel(chestTab, "Chalice: Not found")
local chaliceTimerLabel = addLabel(chestTab, "Timer: 4:00:00")

addDivider(chestTab)
addSection(chestTab, "Actions")

addButton(chestTab, "Find Nearest Chest", function()
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local best, bd = nil, math.huge
    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Part") and obj.Name:find("Chest") and not obj.Name:find("Mirage") and not obj.Name:find("Fragment") and not obj.Name:find("Cursed") then
                local d = (obj.Position - hrp.Position).Magnitude
                if d < bd then bd = d; best = obj end
            end
        end
    end)
    if best then
        chestStats.status = "Nearest: " .. best.Name .. " (" .. math.floor(bd) .. "m)"
        fly(best.Position + Vector3.new(0, 3, 0))
    else
        chestStats.status = "No chests found"
    end
end)

addButton(chestTab, "Collect All Chests", function()
    spawn(function()
        while _G.ChestFarm do
            local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1) continue end

            local chests = {}
            pcall(function()
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("Part") and obj.Name:find("Chest") and not obj.Name:find("Mirage") and not obj.Name:find("Fragment") and not obj.Name:find("Cursed") then
                        local d = (obj.Position - hrp.Position).Magnitude
                        if d < 5000 then
                            table.insert(chests, {part = obj, dist = d})
                        end
                    end
                end
            end)

            table.sort(chests, function(a, b) return a.dist < b.dist end)

            for _, c in ipairs(chests) do
                if not _G.ChestFarm then break end
                if c.part and c.part.Parent then
                    chestStats.status = "Moving to " .. c.part.Name .. " (" .. math.floor(c.dist) .. "m)"
                    fly(c.part.Position + Vector3.new(0, 3, 0))
                    task.wait(1.5)
                    chestStats.collected = chestStats.collected + 1
                    chestStats.money = chestStats.money + 1000
                    chestStats.status = "Collected! Total: " .. chestStats.collected
                end
            end

            task.wait(1)
        end
    end)
end)

-- Chest stats updater
spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            chestStatusLabel.Text = "  Status: " .. chestStats.status
            chestCountLabel.Text = "  Chests: " .. chestStats.collected
            chestMoneyLabel.Text = "  Money: $" .. chestStats.money
            chaliceLabel.Text = "  Chalice: " .. (chestStats.chaliceFound and "FOUND!" or "Not found")
            chaliceLabel.TextColor3 = chestStats.chaliceFound and GOLD or TXT

            local h = math.floor(chestStats.chaliceTimer / 3600)
            local m = math.floor((chestStats.chaliceTimer % 3600) / 60)
            local s = math.floor(chestStats.chaliceTimer % 60)
            chaliceTimerLabel.Text = string.format("  Timer: %d:%02d:%02d", h, m, s)
        end)
    end
end)

-- Chalice timer updater
spawn(function()
    chestStats.lastSpawn = os.clock()
    while true do
        task.wait(3)
        if not _G.AutoChalice then continue end
        pcall(function()
            local elapsed = os.clock() - chestStats.lastSpawn
            chestStats.chaliceTimer = math.max(0, 14400 - elapsed)

            if plr.Backpack:FindFirstChild("God's Chalice") or (plr.Character and plr.Character:FindFirstChild("God's Chalice")) then
                if not chestStats.chaliceFound then
                    chestStats.chaliceFound = true
                    pcall(function()
                        StarterGui:SetCore("SendNotification", {Title = "CHALICE!", Text = "God's Chalice found!", Duration = 5})
                    end)
                end
            end
        end)
    end
end)

-- Close + Toggle
closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

local toggleBtn = Instance.new("TextButton", mainGui)
toggleBtn.Size = UDim2.new(0, 45, 0, 45)
toggleBtn.Position = UDim2.new(0.93, 0, 0.75, 0)
toggleBtn.Text = "BF"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 16
toggleBtn.TextColor3 = ACC
toggleBtn.BackgroundColor3 = BG
toggleBtn.BackgroundTransparency = 0.15
toggleBtn.BorderSizePixel = 0
toggleBtn.Active = true
toggleBtn.Draggable = true
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
local tStroke = Instance.new("UIStroke", toggleBtn)
tStroke.Thickness = 1.5
tStroke.Color = ACC
tStroke.Transparency = 0.4

toggleBtn.MouseButton1Click:Connect(function() mainFrame.Visible = not mainFrame.Visible end)

-- Keybinds
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.C then
        _G.ChestFarm = not _G.ChestFarm
        chestStats.status = _G.ChestFarm and "Starting..." or "Stopped"
        pcall(function() togChestFarm:Set(_G.ChestFarm) end)
    end
end)

-- Start on first tab
switchTab("Chest")

-- Init
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Blox Fruits",
        Text = "Dmitri Kotakbass loaded! Tab BF for menu",
        Duration = 3
    })
end)

print("[BloxFruits] Loaded — Native UI (no dependencies)")
