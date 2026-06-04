local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Blox Fruits - Dmitri Kotakbass", "DarkTheme")

local player = game.Players.LocalPlayer
local CommF = game:GetService("ReplicatedStorage").Remotes.CommF_
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local function flyTo(targetCF, speed)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local dist = (targetCF.Position - hrp.Position).Magnitude
    local time = math.max(dist / (speed or 250), 0.3)
    local tween = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = targetCF})
    tween:Play()
    tween.Completed:Wait()
end

local function getEnemies()
    local seen = {}
    local list = {}
    local folder = workspace:FindFirstChild("Enemies")
    if folder then
        for _, v in pairs(folder:GetChildren()) do
            if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
                table.insert(list, v)
                seen[v] = true
            end
        end
    end
    for _, v in pairs(workspace:GetChildren()) do
        if not seen[v] and v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Humanoid.Health > 0 and not v:FindFirstChild("Player") then
                table.insert(list, v)
            end
        end
    end
    return list
end

-- Main
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Auto Farm")

MainSection:NewToggle("Auto Farm", "Automatically farm enemies", function(state)
    _G.AutoFarm = state
    while _G.AutoFarm and task.wait(0.25) do
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
                if dist > 8 then
                    local targetCF = nearest.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                    local flyTime = math.max(dist / 300, 0.2)
                    local tween = TweenService:Create(hrp, TweenInfo.new(flyTime, Enum.EasingStyle.Linear), {CFrame = targetCF})
                    tween:Play()
                    tween.Completed:Wait()
                end
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate()
                    task.wait()
                    tool:Activate()
                end
            end
        end)
    end
end)

MainSection:NewToggle("Auto Quest", "Auto accept and complete quests", function(state)
    _G.AutoQuest = state
    while _G.AutoQuest and task.wait(0.5) do
        pcall(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            for _, q in pairs(workspace:GetDescendants()) do
                if q:IsA("Model") and q.Name:lower():find("quest") and q:FindFirstChild("HumanoidRootPart") then
                    local d = (q.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < 25 then
                        local p = q:FindFirstChildWhichIsA("ProximityPrompt")
                        if p then fireproximityprompt(p) end
                    elseif d > 40 then
                        flyTo(q.HumanoidRootPart.CFrame, 300)
                    end
                end
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
        pcall(flyTo, data[2], 400)
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
