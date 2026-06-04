local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Blox Fruits - Dmitri Kotakbass", "DarkTheme")

local plr = game.Players.LocalPlayer
local CommF = game:GetService("ReplicatedStorage").Remotes.CommF_
local RunS = game:GetService("RunService")
local TweenS = game:GetService("TweenService")
local TeleS = game:GetService("TeleportService")
local HttpS = game:GetService("HttpService")
local VUser = game:GetService("VirtualUser")
local RigEvent = game:GetService("ReplicatedStorage").RigControllerEvent
local Validator = game:GetService("ReplicatedStorage").Remotes.Validator

--- CombatFramework init
local CbFw = debug.getupvalues(require(plr.PlayerScripts.CombatFramework))
local CbFw2 = CbFw[2]

local function getBlade()
    local ac = CbFw2.activeController
    if not ac or not ac.blades then return end
    local b = ac.blades[1]
    if b then
        while b.Parent ~= plr.Character do b = b.Parent end
    end
    return b
end

local function fastAtk()
    local ac = CbFw2.activeController
    if not ac then return end
    local hits = require(game.ReplicatedStorage.CombatFramework.RigLib).getBladeHits(plr.Character, {plr.Character.HumanoidRootPart}, 60)
    local filtered, seen = {}, {}
    for _, v in pairs(hits) do
        if v.Parent and v.Parent:FindFirstChild("HumanoidRootPart") and not seen[v.Parent] then
            table.insert(filtered, v.Parent.HumanoidRootPart)
            seen[v.Parent] = true
        end
    end
    if #filtered == 0 then return end
    local u4 = debug.getupvalue(ac.attack, 4)
    local u5 = debug.getupvalue(ac.attack, 5)
    local u6 = debug.getupvalue(ac.attack, 6)
    local u7 = debug.getupvalue(ac.attack, 7)
    local r1 = (u5 * 798405 + u4 * 727595) % u6
    local r2 = u4 * 798405
    r1 = (r1 * u6 + r2) % 1099511627776
    u5 = math.floor(r1 / u6)
    u4 = r1 - u5 * u6
    u7 = u7 + 1
    debug.setupvalue(ac.attack, 4, u4)
    debug.setupvalue(ac.attack, 5, u5)
    debug.setupvalue(ac.attack, 6, u6)
    debug.setupvalue(ac.attack, 7, u7)
    local tool = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
    if tool and getBlade() then
        RigEvent:FireServer("weaponChange", tostring(getBlade()))
        Validator:FireServer(math.floor(r1 / 1099511627776 * 16777215), u7)
        RigEvent:FireServer("hit", filtered, 1, "")
    end
    ac.timeToNextAttack = 0
    ac.attacking = false
    ac.hitboxMagnitude = 150
    ac.humanoid.AutoRotate = true
end

local function click()
    pcall(function()
        VUser:CaptureController()
        VUser:Button1Down(Vector2.new(0, 1))
    end)
end

local function atk()
    pcall(fastAtk)
    for _ = 1, 3 do
        pcall(click)
        task.wait(0.01)
    end
end

--- Movement
local function fly(pos)
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local d = (pos - hrp.Position).Magnitude
    if d < 1 then return end
    local tw = TweenS:Create(hrp, TweenInfo.new(math.clamp(d / 300, 0.2, 2.5), Enum.EasingStyle.Linear), {Position = pos})
    tw:Play()
    tw.Completed:Wait()
end

--- World detection
local function getWorld()
    if workspace:FindFirstChild("Map") then
        if workspace.Map:FindFirstChild("Wood") and workspace.Map.Wood:FindFirstChild("Desert") then return 2 end
        if workspace.Map:FindFirstChild("Wood") and workspace.Map.Wood:FindFirstChild("Frost") then return 2 end
    end
    return 1
end

--- Enemy helper
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

--- Level map
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

--- Equip best weapon
local function equipWeapon()
    local char = plr.Character
    if not char then return end
    local backpack = plr.Backpack
    local best = char:FindFirstChildOfClass("Tool")
    if not best or not best:FindFirstChildOfClass("Handle") then
        for _, v in pairs(backpack:GetChildren()) do
            if v:IsA("Tool") then
                best = v
                break
            end
        end
    end
    if best then
        char.Humanoid:EquipTool(best)
    end
end

--- Accept quest
local function acceptQuest()
    for _, q in pairs(workspace:GetDescendants()) do
        if q:IsA("Model") and q.Name:lower():match("quest") and q:FindFirstChild("HumanoidRootPart") then
            local d = (q.HumanoidRootPart.Position - (plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.HumanoidRootPart.Position or Vector3.zero)).Magnitude
            if d < 25 then
                local p = q:FindFirstChildWhichIsA("ProximityPrompt")
                if p then fireproximityprompt(p); task.wait(0.2) end
            end
        end
    end
end

--- Bring enemy
_G.Bring = false
RunS.Heartbeat:Connect(function()
    if _G.Bring and _G.Target then
        pcall(function()
            _G.Target.HumanoidRootPart.CFrame = (plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")) and CFrame.new(plr.Character.HumanoidRootPart.Position + Vector3.new(0, 15, -10)) or _G.Target.HumanoidRootPart.CFrame
        end)
    end
end)

--- ====================
--- MAIN TAB
--- ====================
local T1 = Window:NewTab("Main")
local S1 = T1:NewSection("Auto Farm")

S1:NewToggle("Auto Farm", nil, function(state)
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
                if bd > 8 then
                    fly(best.HumanoidRootPart.Position + Vector3.new(0, 22, 0))
                end
                hrp.CFrame = CFrame.new(hrp.Position, best.HumanoidRootPart.Position)
                atk()
            else
                _G.Target = nil
            end
        end)
    end
    _G.Target = nil
end)

S1:NewToggle("Auto Level", nil, function(state)
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
                if md > 8 then
                    fly(target.HumanoidRootPart.Position + Vector3.new(0, 22, 0))
                end
                hrp.CFrame = CFrame.new(hrp.Position, target.HumanoidRootPart.Position)
                atk()
            end
        end)
    end
    _G.Target = nil
end)

S1:NewToggle("Auto Quest", nil, function(state)
    _G.Quest = state
    while _G.Quest and task.wait(0.3) do
        pcall(acceptQuest)
    end
end)

S1:NewToggle("Bring Enemy", nil, function(state)
    _G.Bring = state
    if not state then _G.Target = nil end
end)

--- ====================
--- STATS TAB
--- ====================
local T2 = Window:NewTab("Stats")
local S2 = T2:NewSection("Auto Points")

local stats = {"Melee","Defense","Sword","Demon Fruit"}
for _, s in pairs(stats) do
    S2:NewToggle("Auto " .. s, nil, function(state)
        _G["S" .. s:gsub(" ","")] = state
        coroutine.wrap(function()
            while _G["S" .. s:gsub(" ","")] and task.wait(0.3) do
                pcall(function()
                    if plr.Data.StatPoints.Value > 0 then
                        CommF:InvokeServer("AddPoint", s, tonumber(plr.Data.StatPoints.Value))
                    end
                end)
            end
        end)()
    end)
end

S2:NewButton("Melee > 1:1:1:1", nil, function()
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

--- ====================
--- TELEPORT TAB
--- ====================
local T3 = Window:NewTab("Teleports")
local S3 = T3:NewSection("Islands")

local islands = {
    {"Jungle", CFrame.new(-1242,30,-452)},
    {"Pirate Village", CFrame.new(-1120,15,510)},
    {"Desert", CFrame.new(840,25,1250)},
    {"Frozen Village", CFrame.new(820,70,-1590)},
    {"Marine Fortress", CFrame.new(-920,40,3320)},
    {"Sky Island 1", CFrame.new(-5100,320,530)},
    {"Sky Island 2", CFrame.new(-7900,550,530)},
    {"Prison", CFrame.new(4900,8,900)},
    {"Magma Village", CFrame.new(-5300,15,1300)},
    {"Colosseum", CFrame.new(-1420,15,-2940)},
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
    {"Ice Castle", CFrame.new(-5100,75,-7800)},
    {"Forgotten Island", CFrame.new(-3000,10,-6500)},
}

for _, d in pairs(islands) do
    S3:NewButton(d[1], nil, function()
        pcall(function()
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                fly(d[2].Position)
            end
        end)
    end)
end

--- ====================
--- MISC TAB
--- ====================
local T4 = Window:NewTab("Misc")
local S4 = T4:NewSection("Utilities")

S4:NewButton("Rejoin", nil, function() TeleS:Teleport(game.PlaceId, plr) end)
S4:NewButton("Server Hop", nil, function()
    local d = HttpS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
    for _, v in pairs(d.data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            TeleS:TeleportToPlaceInstance(game.PlaceId, v.id, plr)
            break
        end
    end
end)

_G.WS = 16
_G.JP = 50
RunS.Heartbeat:Connect(function()
    local char = plr.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = _G.WS
        char.Humanoid.JumpPower = _G.JP
    end
end)
S4:NewSlider("Walk Speed", nil, 250, 16, function(s) _G.WS = s end)
S4:NewSlider("Jump Power", nil, 500, 50, function(s) _G.JP = s end)

--- Teleports section in Misc
local S4b = T4:NewSection("Quick Teleports")
S4b:NewButton("Start Island", nil, function()
    pcall(function() if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then fly(Vector3.new(0, 10, 0)) end end)
end)
S4b:NewButton("Middle Town", nil, function()
    pcall(function() if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then fly(Vector3.new(-80, 10, 1250)) end end)
end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Blox Fruits",
    Text = "Dmitri Kotakbass loaded!",
    Duration = 3
})
