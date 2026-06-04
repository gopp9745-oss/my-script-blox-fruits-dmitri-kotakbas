local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Blox Fruits - Dmitri Kotakbass", "DarkTheme")

local plr = game.Players.LocalPlayer
local CommF = game:GetService("ReplicatedStorage").Remotes.CommF_
local RunS = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local TweenS = game:GetService("TweenService")

--- ENEMY FINDER
local function findEnemies()
    local list = {}
    local e = workspace:FindFirstChild("Enemies")
    if e then
        for _, v in pairs(e:GetChildren()) do
            if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                table.insert(list, v)
            end
        end
    end
    return list
end

--- CLICK
local function click()
    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.02)
    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

--- ATTACK
local function atk()
    local char = plr.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
    end
    for _ = 1, 4 do
        pcall(click)
        task.wait(0.03)
    end
end

--- FLY TO
local function fly(targetPos, spd)
    spd = spd or 250
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local dist = (targetPos - hrp.Position).Magnitude
    if dist < 1 then return end
    local t = math.clamp(dist / spd, 0.2, 3)
    local tw = TweenS:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {Position = targetPos})
    tw:Play()
    tw.Completed:Wait()
end

--- LEVEL MAP
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
    {1300,2000,"Castle on the Sea", CFrame.new(-5300,20,7000)},
}

local function getArea()
    local lvl = plr.Data.Level.Value
    for _, a in pairs(lvlMap) do
        if lvl >= a[1] and lvl <= a[2] then return a end
    end
    return lvlMap[#lvlMap]
end

--- MAIN TAB
local MTab = Window:NewTab("Main")
local MS = MTab:NewSection("Farming")

MS:NewToggle("Auto Farm", nil, function(state)
    _G.Farm = state
    while _G.Farm and task.wait(0.12) do
        pcall(function()
            local char = plr.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            local enemies = findEnemies()
            local best, bd = nil, math.huge
            for _, e in pairs(enemies) do
                local d = (e.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < bd then bd = d; best = e end
            end
            if best and bd < 300 then
                if bd > 7 then
                    fly(best.HumanoidRootPart.Position + Vector3.new(0, 22, 0))
                end
                hrp.CFrame = CFrame.new(hrp.Position, best.HumanoidRootPart.Position)
                atk()
            end
        end)
    end
end)

MS:NewToggle("Auto Level", nil, function(state)
    _G.LevelFarm = state
    while _G.LevelFarm and task.wait(0.2) do
        pcall(function()
            local char = plr.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            local lvl = plr.Data.Level.Value
            local area = getArea()
            -- quest
            for _, q in pairs(workspace:GetDescendants()) do
                if q:IsA("Model") and q.Name:lower():find("quest") and q:FindFirstChild("HumanoidRootPart") then
                    local d = (q.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < 20 then
                        local p = q:FindFirstChildWhichIsA("ProximityPrompt")
                        if p then fireproximityprompt(p); task.wait(0.3) end
                    end
                end
            end
            -- enemies by level
            local enemies = findEnemies()
            local target, md = nil, math.huge
            for _, e in pairs(enemies) do
                local el = e:FindFirstChild("Level") and e.Level.Value or lvl
                if math.abs(el - lvl) <= 10 then
                    local d = (e.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < md then md = d; target = e end
                end
            end
            if not target then
                fly(area[4].Position)
            else
                if md > 7 then
                    fly(target.HumanoidRootPart.Position + Vector3.new(0, 22, 0))
                end
                hrp.CFrame = CFrame.new(hrp.Position, target.HumanoidRootPart.Position)
                atk()
            end
        end)
    end
end)

--- STATS TAB
local STab = Window:NewTab("Stats")
local SS = STab:NewSection("Auto Stats")

for _, s in pairs({"Melee","Defense","Sword","Demon Fruit"}) do
    local lbl = s == "Demon Fruit" and "Fruit" or s
    SS:NewToggle("Auto " .. lbl, nil, function(state)
        _G["S"..s] = state
        while _G["S"..s] and task.wait(0.3) do
            pcall(function()
                if plr.Data.StatPoints.Value > 0 then
                    CommF:InvokeServer("AddPoint", s, 1)
                end
            end)
        end
    end)
end

--- TELEPORT TAB
local TTab = Window:NewTab("Teleports")
local TS = TTab:NewSection("Islands")

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
}

for _, d in pairs(islands) do
    TS:NewButton(d[1], nil, function()
        pcall(function()
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                fly(d[2].Position)
            end
        end)
    end)
end

--- MISC TAB
local MiTab = Window:NewTab("Misc")
local MiS = MiTab:NewSection("Utilities")

MiS:NewButton("Rejoin", nil, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, plr)
end)

MiS:NewButton("Server Hop", nil, function()
    local d = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
    for _, v in pairs(d.data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, v.id, plr)
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

MiS:NewSlider("Walk Speed", nil, 250, 16, function(s) _G.WS = s end)
MiS:NewSlider("Jump Power", nil, 500, 50, function(s) _G.JP = s end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Blox Fruits",
    Text = "Dmitri Kotakbass loaded!",
    Duration = 3
})
