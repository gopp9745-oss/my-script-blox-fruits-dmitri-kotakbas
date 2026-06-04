local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Blox Fruits - Dmitri Kotakbass", "DarkTheme")

local player = game.Players.LocalPlayer
local CommF = game:GetService("ReplicatedStorage").Remotes.CommF_
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

--- ENEMIES
local function getEnemies()
    local list = {}
    local folder = workspace:FindFirstChild("Enemies")
    if folder then
        for _, v in pairs(folder:GetChildren()) do
            if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                table.insert(list, v)
            end
        end
    end
    return list
end

--- ATTACK
local function doClick()
    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.03)
    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

local function doAttack()
    local char = player.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
        task.wait(0.05)
    end
    for i = 1, 3 do
        doClick()
        task.wait(0.05)
    end
end

--- MOVEMENT
local function flyTo(targetPos)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local dist = (targetPos - hrp.Position).Magnitude
    if dist < 1 then return end
    local time = math.clamp(dist / 200, 0.2, 2)
    local tween = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear), {Position = targetPos})
    tween:Play()
    tween.Completed:Wait()
end

--- LEVEL MAP
local levelMap = {
    {min=0, max=15, name="Jungle", cf=CFrame.new(-1242, 30, -452)},
    {min=15, max=35, name="Pirate Village", cf=CFrame.new(-1120, 15, 510)},
    {min=35, max=65, name="Desert", cf=CFrame.new(840, 25, 1250)},
    {min=65, max=95, name="Frozen Village", cf=CFrame.new(820, 70, -1590)},
    {min=95, max=125, name="Marine Fortress", cf=CFrame.new(-920, 40, 3320)},
    {min=125, max=155, name="Sky Island 1", cf=CFrame.new(-5100, 320, 530)},
    {min=155, max=230, name="Sky Island 2", cf=CFrame.new(-7900, 550, 530)},
    {min=230, max=300, name="Prison", cf=CFrame.new(4900, 8, 900)},
    {min=300, max=375, name="Magma Village", cf=CFrame.new(-5300, 15, 1300)},
    {min=375, max=450, name="Graveyard", cf=CFrame.new(-2950, 50, -3650)},
    {min=450, max=525, name="Snow Mountain", cf=CFrame.new(550, 90, -2220)},
    {min=525, max=625, name="Fishman Island", cf=CFrame.new(550, 125, 2820)},
    {min=625, max=700, name="Mansion", cf=CFrame.new(-12700, 380, -500)},
    {min=700, max=850, name="Sea of Treats", cf=CFrame.new(622, 25, 3970)},
    {min=850, max=950, name="Fountain City", cf=CFrame.new(5160, 20, 3020)},
    {min=950, max=1100, name="Hydra Island", cf=CFrame.new(5550, 25, -520)},
    {min=1100, max=1300, name="Great Tree", cf=CFrame.new(8700, 130, 1750)},
    {min=1300, max=2000, name="Castle on the Sea", cf=CFrame.new(-5300, 20, 7000)},
}

local function currentArea()
    local lvl = player.Data.Level.Value
    for _, a in pairs(levelMap) do
        if lvl >= a.min and lvl <= a.max then return a end
    end
    return levelMap[#levelMap]
end

--- MAIN TAB
local MainTab = Window:NewTab("Main")
local M = MainTab:NewSection("Auto Farm")

M:NewToggle("Auto Farm NPC", nil, function(state)
    _G.NPCFarm = state
    while _G.NPCFarm and task.wait(0.15) do
        pcall(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            local enemies = getEnemies()
            local best, bestDist = nil, math.huge
            for _, e in pairs(enemies) do
                local d = (e.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < bestDist then bestDist = d; best = e end
            end
            if best and bestDist < 300 then
                if bestDist > 8 then
                    local pos = best.HumanoidRootPart.Position + Vector3.new(0, 20, 0)
                    flyTo(pos)
                end
                hrp.CFrame = CFrame.new(hrp.Position, best.HumanoidRootPart.Position)
                doAttack()
            end
        end)
    end
end)

M:NewToggle("Auto Farm Level", nil, function(state)
    _G.LevelFarm = state
    while _G.LevelFarm and task.wait(0.25) do
        pcall(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            local lvl = player.Data.Level.Value
            local area = currentArea()

            -- квесты
            for _, q in pairs(workspace:GetDescendants()) do
                if q:IsA("Model") and q.Name:lower():find("quest") and q:FindFirstChild("HumanoidRootPart") then
                    local d = (q.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < 25 then
                        local p = q:FindFirstChildWhichIsA("ProximityPrompt")
                        if p then fireproximityprompt(p); task.wait(0.3) end
                    end
                end
            end

            -- враги по уровню
            local enemies = getEnemies()
            local target, minD = nil, math.huge
            for _, e in pairs(enemies) do
                local el = e:FindFirstChild("Level") and e.Level.Value or lvl
                if math.abs(el - lvl) <= 10 then
                    local d = (e.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < minD then minD = d; target = e end
                end
            end

            if not target then
                flyTo(area.cf.Position)
            else
                if minD > 8 then
                    flyTo(target.HumanoidRootPart.Position + Vector3.new(0, 20, 0))
                end
                hrp.CFrame = CFrame.new(hrp.Position, target.HumanoidRootPart.Position)
                doAttack()
            end
        end)
    end
end)

--- STATS TAB
local StatsTab = Window:NewTab("Stats")
local S = StatsTab:NewSection("Auto Stats")

local statNames = {"Melee","Defense","Sword","Demon Fruit"}
for _, name in pairs(statNames) do
    local label = name == "Demon Fruit" and "Fruit" or name
    S:NewToggle("Auto " .. label, nil, function(state)
        _G["S"..name] = state
        while _G["S"..name] and task.wait(0.3) do
            pcall(function()
                if player.Data.StatPoints.Value > 0 then
                    CommF:InvokeServer("AddPoint", name, 1)
                end
            end)
        end
    end)
end

--- TELEPORT TAB
local TeleportTab = Window:NewTab("Teleports")
local T = TeleportTab:NewSection("Islands")

local islands = {
    {"Jungle", CFrame.new(-1242, 30, -452)},
    {"Pirate Village", CFrame.new(-1120, 15, 510)},
    {"Desert", CFrame.new(840, 25, 1250)},
    {"Frozen Village", CFrame.new(820, 70, -1590)},
    {"Marine Fortress", CFrame.new(-920, 40, 3320)},
    {"Sky Island 1", CFrame.new(-5100, 320, 530)},
    {"Sky Island 2", CFrame.new(-7900, 550, 530)},
    {"Prison", CFrame.new(4900, 8, 900)},
    {"Magma Village", CFrame.new(-5300, 15, 1300)},
    {"Colosseum", CFrame.new(-1420, 15, -2940)},
    {"Graveyard", CFrame.new(-2950, 50, -3650)},
    {"Snow Mountain", CFrame.new(550, 90, -2220)},
    {"Fishman Island", CFrame.new(550, 125, 2820)},
    {"Mansion", CFrame.new(-12700, 380, -500)},
    {"Sea of Treats", CFrame.new(622, 25, 3970)},
    {"Fountain City", CFrame.new(5160, 20, 3020)},
    {"Hydra Island", CFrame.new(5550, 25, -520)},
    {"Great Tree", CFrame.new(8700, 130, 1750)},
    {"Castle on the Sea", CFrame.new(-5300, 20, 7000)},
}

for _, data in pairs(islands) do
    T:NewButton(data[1], nil, function()
        pcall(function()
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                flyTo(data[2].Position)
            end
        end)
    end)
end

--- MISC TAB
local MiscTab = Window:NewTab("Misc")
local Misc = MiscTab:NewSection("Utilities")

Misc:NewButton("Rejoin", nil, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, player)
end)

Misc:NewButton("Server Hop", nil, function()
    local data = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
    for _, v in pairs(data.data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, v.id, player)
            break
        end
    end
end)

_G.WS = 16
_G.JP = 50

RunService.Heartbeat:Connect(function()
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = _G.WS
        char.Humanoid.JumpPower = _G.JP
    end
end)

Misc:NewSlider("Walk Speed", nil, 250, 16, function(s) _G.WS = s end)
Misc:NewSlider("Jump Power", nil, 500, 50, function(s) _G.JP = s end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Blox Fruits",
    Text = "Dmitri Kotakbass loaded!",
    Duration = 3
})
