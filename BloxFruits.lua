local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Blox Fruits - Dmitri Kotakbass", "DarkTheme")

local player = game.Players.LocalPlayer
local CommF = game:GetService("ReplicatedStorage").Remotes.CommF_
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

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
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v ~= folder and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            if not v:FindFirstChild("Player") then
                local dup = false
                for _, e in pairs(list) do if e == v then dup = true; break end end
                if not dup then table.insert(list, v) end
            end
        end
    end
    return list
end

local function click()
    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.03)
    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

local function attack()
    local char = player.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
            task.wait(0.05)
        end
    end
    click()
    task.wait(0.05)
    click()
end

local function smoothTP(target, steps)
    steps = steps or 15
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local start = hrp.CFrame
    for i = 1, steps do
        hrp.CFrame = start:Lerp(target, i / steps)
        task.wait()
    end
end

local function teleportTo(cf)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    smoothTP(cf, 15)
end

-- Уровни и острова
local levelAreas = {
    {min=0, max=15, island="Jungle", cf=CFrame.new(-1242, 30, -452)},
    {min=15, max=35, island="Pirate Village", cf=CFrame.new(-1120, 15, 510)},
    {min=35, max=65, island="Desert", cf=CFrame.new(840, 25, 1250)},
    {min=65, max=95, island="Frozen Village", cf=CFrame.new(820, 70, -1590)},
    {min=95, max=125, island="Marine Fortress", cf=CFrame.new(-920, 40, 3320)},
    {min=125, max=155, island="Sky Island 1", cf=CFrame.new(-5100, 320, 530)},
    {min=155, max=230, island="Sky Island 2", cf=CFrame.new(-7900, 550, 530)},
    {min=230, max=300, island="Prison", cf=CFrame.new(4900, 8, 900)},
    {min=300, max=375, island="Magma Village", cf=CFrame.new(-5300, 15, 1300)},
    {min=375, max=450, island="Graveyard", cf=CFrame.new(-2950, 50, -3650)},
    {min=450, max=525, island="Snow Mountain", cf=CFrame.new(550, 90, -2220)},
    {min=525, max=625, island="Fishman Island", cf=CFrame.new(550, 125, 2820)},
    {min=625, max=700, island="Mansion", cf=CFrame.new(-12700, 380, -500)},
    {min=700, max=850, island="Sea of Treats", cf=CFrame.new(622, 25, 3970)},
    {min=850, max=950, island="Fountain City", cf=CFrame.new(5160, 20, 3020)},
    {min=950, max=1100, island="Hydra Island", cf=CFrame.new(5550, 25, -520)},
    {min=1100, max=1300, island="Great Tree", cf=CFrame.new(8700, 130, 1750)},
    {min=1300, max=2000, island="Castle on the Sea", cf=CFrame.new(-5300, 20, 7000)},
}

local function getLevelArea()
    local lvl = player.Data.Level.Value
    for _, area in pairs(levelAreas) do
        if lvl >= area.min and lvl <= area.max then return area end
    end
    return levelAreas[#levelAreas]
end

-- Main Tab
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Farming")

MainSection:NewToggle("Auto Farm NPC", "Farm nearest enemies", function(state)
    _G.AutoFarmNPC = state
    while _G.AutoFarmNPC and task.wait(0.2) do
        pcall(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            local enemies = getEnemies()
            local nearest, dist = nil, math.huge
            for _, mob in pairs(enemies) do
                local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < dist then dist = d; nearest = mob end
            end
            if nearest and dist < 400 then
                if dist > 6 then
                    teleportTo(nearest.HumanoidRootPart.CFrame * CFrame.new(0, 3, 4))
                end
                attack()
                task.wait(0.1)
                attack()
            end
        end)
    end
end)

MainSection:NewToggle("Auto Farm Level", "Auto quest + farm level enemies", function(state)
    _G.AutoFarmLevel = state
    while _G.AutoFarmLevel and task.wait(0.3) do
        pcall(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            local area = getLevelArea()
            if not area then return end

            -- Проверяем квест
            local myLevel = player.Data.Level.Value
            local questInProgress = false
            for _, q in pairs(workspace:GetDescendants()) do
                if q:IsA("Model") and q.Name:lower():find("quest") and q:FindFirstChild("HumanoidRootPart") then
                    local d = (q.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < 50 then
                        local prompt = q:FindFirstChildWhichIsA("ProximityPrompt")
                        if prompt then
                            fireproximityprompt(prompt)
                            questInProgress = true
                            task.wait(0.5)
                        end
                    end
                end
            end

            -- Фармим врагов своего уровня
            local enemies = getEnemies()
            local target = nil
            local minDist = math.huge
            for _, mob in pairs(enemies) do
                local mobLvl = mob:FindFirstChild("Level") and mob.Level.Value or myLevel
                if math.abs(mobLvl - myLevel) <= 10 then
                    local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < minDist then minDist = d; target = mob end
                end
            end

            if not target then
                -- Телепорт на остров по уровню
                teleportTo(area.cf)
            elseif minDist > 6 then
                teleportTo(target.HumanoidRootPart.CFrame * CFrame.new(0, 3, 4))
            else
                attack()
                task.wait(0.1)
                attack()
            end
        end)
    end
end)

-- Stats
local StatsTab = Window:NewTab("Stats")
local StatsSection = StatsTab:NewSection("Auto Stats")

local statsList = {"Melee","Defense","Sword","Demon Fruit"}
for _, s in pairs(statsList) do
    local label = s == "Demon Fruit" and "Fruit" or s
    StatsSection:NewToggle("Auto " .. label, nil, function(state)
        _G["Auto"..s] = state
        while _G["Auto"..s] and task.wait(0.3) do
            pcall(function()
                if player.Data.StatPoints.Value > 0 then
                    CommF:InvokeServer("AddPoint", s, 1)
                end
            end)
        end
    end)
end

-- Teleports
local TeleportTab = Window:NewTab("Teleports")
local TeleportSection = TeleportTab:NewSection("Island Teleports")

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
    TeleportSection:NewButton(data[1], nil, function()
        pcall(teleportTo, data[2])
    end)
end

-- Misc
local MiscTab = Window:NewTab("Misc")
local MiscSection = MiscTab:NewSection("Utilities")

MiscSection:NewButton("Rejoin Server", nil, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, player)
end)

MiscSection:NewButton("Server Hop", nil, function()
    local list = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
    for _, v in pairs(list.data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, v.id, player)
            break
        end
    end
end)

_G.WalkSpeed = 16
_G.JumpPower = 50

RunService.Heartbeat:Connect(function()
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = _G.WalkSpeed
        char.Humanoid.JumpPower = _G.JumpPower
    end
end)

MiscSection:NewSlider("Walk Speed", nil, 250, 16, function(s)
    _G.WalkSpeed = s
end)

MiscSection:NewSlider("Jump Power", nil, 500, 50, function(s)
    _G.JumpPower = s
end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Blox Fruits",
    Text = "Script loaded successfully!",
    Duration = 3
})
