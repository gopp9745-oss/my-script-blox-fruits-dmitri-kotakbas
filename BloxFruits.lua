local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Blox Fruits - Dmitri Kotakbass", "DarkTheme")

local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local function tweenTeleport(cframe)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local tween = TweenService:Create(hrp, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {CFrame = cframe})
    tween:Play()
end

local function getNearestEnemy()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local nearest = nil
    local dist = math.huge
    for _, mob in pairs(workspace:GetDescendants()) do
        if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") then
            if mob.Humanoid.Health > 0 and not mob:FindFirstChild("Player") then
                local d = (mob.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = mob
                end
            end
        end
    end
    return nearest
end

-- Main
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Auto Farm")

MainSection:NewToggle("Auto Farm", "Automatically farm enemies", function(state)
    _G.AutoFarm = state
    while _G.AutoFarm do
        pcall(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local nearest = getNearestEnemy()
            if nearest then
                local hrp = char.HumanoidRootPart
                local targetCF = nearest.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
                local dist = (nearest.HumanoidRootPart.Position - hrp.Position).Magnitude
                if dist > 10 then
                    tweenTeleport(targetCF)
                end
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate()
                end
            end
        end)
        task.wait()
    end
end)

MainSection:NewToggle("Auto Quest", "Auto accept and complete quests", function(state)
    _G.AutoQuest = state
    while _G.AutoQuest do
        pcall(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            for _, quest in pairs(workspace:GetDescendants()) do
                if quest:IsA("Model") and quest.Name:find("Quest") and quest:FindFirstChild("HumanoidRootPart") then
                    local d = (quest.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < 25 then
                        local prompt = quest:FindFirstChildWhichIsA("ProximityPrompt")
                        if prompt then fireproximityprompt(prompt) end
                    elseif d > 50 then
                        tweenTeleport(quest.HumanoidRootPart.CFrame)
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)

-- Stats
local StatsTab = Window:NewTab("Stats")
local StatsSection = StatsTab:NewSection("Auto Stats")

StatsSection:NewToggle("Auto Melee", "Auto assign stats to melee", function(state)
    _G.AutoMelee = state
    while _G.AutoMelee do
        pcall(function()
            if player.Data.StatPoints.Value > 0 then
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("AddPoint", "Melee", 1)
            end
        end)
        task.wait(0.5)
    end
end)

StatsSection:NewToggle("Auto Defense", "Auto assign stats to defense", function(state)
    _G.AutoDefense = state
    while _G.AutoDefense do
        pcall(function()
            if player.Data.StatPoints.Value > 0 then
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("AddPoint", "Defense", 1)
            end
        end)
        task.wait(0.5)
    end
end)

StatsSection:NewToggle("Auto Sword", "Auto assign stats to sword", function(state)
    _G.AutoSword = state
    while _G.AutoSword do
        pcall(function()
            if player.Data.StatPoints.Value > 0 then
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("AddPoint", "Sword", 1)
            end
        end)
        task.wait(0.5)
    end
end)

StatsSection:NewToggle("Auto Fruit", "Auto assign stats to fruit", function(state)
    _G.AutoFruit = state
    while _G.AutoFruit do
        pcall(function()
            if player.Data.StatPoints.Value > 0 then
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("AddPoint", "Demon Fruit", 1)
            end
        end)
        task.wait(0.5)
    end
end)

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
    TeleportSection:NewButton(data[1], "Teleport to " .. data[1], function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = data[2]
        end
    end)
end

-- Misc
local MiscTab = Window:NewTab("Misc")
local MiscSection = MiscTab:NewSection("Utilities")

MiscSection:NewButton("Rejoin Server", "Rejoin the current server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, player)
end)

MiscSection:NewButton("Server Hop", "Hop to another server", function()
    local req = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
    for _, server in pairs(req.data) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, player)
            break
        end
    end
end)

-- WalkSpeed / JumpPower loop (anti-reset)
_G.WalkSpeed = 16
_G.JumpPower = 50

RunService.Heartbeat:Connect(function()
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = _G.WalkSpeed
        char.Humanoid.JumpPower = _G.JumpPower
    end
end)

MiscSection:NewSlider("Walk Speed", "Change walk speed", 250, 16, function(s)
    _G.WalkSpeed = s
end)

MiscSection:NewSlider("Jump Power", "Change jump power", 500, 50, function(s)
    _G.JumpPower = s
end)

-- Notify
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Blox Fruits",
    Text = "Script loaded successfully!",
    Duration = 3
})
