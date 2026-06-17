local ok, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
end)
if not ok then
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Error", Text = "Failed to load UI library", Duration = 5})
    return
end

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

--- CombatFramework init (with safe fallback)
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
                RigEvent:FireServer("weaponChange", tostring(blade))
            end
        end)
        pcall(function()
            Validator:FireServer(math.floor(r1 / 1099511627776 * 16777215), u7)
            RigEvent:FireServer("hit", filtered, 1, "")
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
        VUser:CaptureController()
        VUser:Button1Down(Vector2.new(0, 1))
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
    local tw = TweenS:Create(hrp, TweenInfo.new(math.clamp(d / 300, 0.2, 2.5), Enum.EasingStyle.Linear), {Position = pos})
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
            local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                _G.Target.HumanoidRootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 15, -10))
            end
        end)
    end
end)

--- ====================
--- MAIN TAB
--- ====================
pcall(function()
local T1 = Window:NewTab("Main")
local S1 = T1:NewSection("Auto Farm")

S1:NewToggle("Auto Farm", nil, function(state)
    _G.Farm = state
    while _G.Farm and task.wait(0.1) do
        local suc, err = pcall(function()
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
        if not suc then warn(err) end
    end
    _G.Target = nil
end)

S1:NewToggle("Auto Level", nil, function(state)
    _G.LvlFarm = state
    while _G.LvlFarm and task.wait(0.15) do
        local suc, err = pcall(function()
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
        if not suc then warn(err) end
    end
    _G.Target = nil
end)

S1:NewToggle("Auto Quest", nil, function(state)
    _G.Quest = state
    while _G.Quest and task.wait(0.3) do pcall(acceptQuest) end
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

for _, s in pairs({"Melee","Defense","Sword","Demon Fruit"}) do
    S2:NewToggle("Auto " .. s, nil, function(state)
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
            if char and char:FindFirstChild("HumanoidRootPart") then fly(d[2].Position) end
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
    local suc, d = pcall(function()
        return HttpS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
    end)
    if suc and d and d.data then
        for _, v in pairs(d.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                TeleS:TeleportToPlaceInstance(game.PlaceId, v.id, plr)
                break
            end
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

local S4b = T4:NewSection("Quick Teleports")
S4b:NewButton("Start Island", nil, function()
    pcall(function() if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then fly(Vector3.new(0, 10, 0)) end end)
end)
S4b:NewButton("Middle Town", nil, function()
    pcall(function() if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then fly(Vector3.new(-80, 10, 1250)) end end)
end)

--- ====================
--- CHEST FARM TAB
--- ====================
local T5 = Window:NewTab("Chest Farm")
local S5 = T5:NewSection("Auto Chest")

_G.ChestFarm = false
_G.AutoChalice = false

S5:NewToggle("Auto Chest Farm (C)", nil, function(state)
    _G.ChestFarm = state
end)

S5:NewToggle("Auto Chalice Search", nil, function(state)
    _G.AutoChalice = state
end)

local S5b = T5:NewSection("Chalice Status")
local chaliceLabel = S5b:NewLabel("Chalice: Not found")
local timerLabel = S5b:NewLabel("Chalice Timer: 4:00:00")

spawn(function()
    local lastSpawn = os.clock()
    while true do
        task.wait(1)
        local elapsed = os.clock() - lastSpawn
        local remaining = 14400 - elapsed
        if remaining <= 0 then
            timerLabel:UpdateText("Chalice Timer: AVAILABLE NOW!")
        else
            local h = math.floor(remaining / 3600)
            local m = math.floor((remaining % 3600) / 60)
            local s = math.floor(remaining % 60)
            timerLabel:UpdateText(string.format("Chalice Timer: %d:%02d:%02d", h, m, s))
        end

        pcall(function()
            if plr.Backpack:FindFirstChild("God's Chalice") or (plr.Character and plr.Character:FindFirstChild("God's Chalice")) then
                chaliceLabel:UpdateText("Chalice: FOUND!")
            else
                chaliceLabel:UpdateText("Chalice: Not found")
            end
        end)
    end
end)

S5:NewButton("Find Nearest Chest", nil, function()
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local best, bd = nil, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name:find("Chest") and not obj.Name:find("Mirage") and not obj.Name:find("Fragment") and not obj.Name:find("Cursed") then
            local d = (obj.Position - hrp.Position).Magnitude
            if d < bd then bd = d; best = obj end
        end
    end
    if best then
        fly(best.Position + Vector3.new(0, 3, 0))
    end
end)

S5:NewButton("Collect All Chests", nil, function()
    spawn(function()
        while _G.ChestFarm do
            local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1) continue end

            local chests = {}
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Part") and obj.Name:find("Chest") and not obj.Name:find("Mirage") and not obj.Name:find("Fragment") and not obj.Name:find("Cursed") then
                    local d = (obj.Position - hrp.Position).Magnitude
                    if d < 5000 then
                        table.insert(chests, {part = obj, dist = d})
                    end
                end
            end

            table.sort(chests, function(a, b) return a.dist < b.dist end)

            for _, c in ipairs(chests) do
                if not _G.ChestFarm then break end
                if c.part and c.part.Parent then
                    fly(c.part.Position + Vector3.new(0, 3, 0))
                    task.wait(1.5)
                end
            end

            task.wait(1)
        end
    end)
end)

end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Blox Fruits",
    Text = "Dmitri Kotakbass loaded!",
    Duration = 3
})
