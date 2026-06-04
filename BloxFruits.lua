-- Blox Fruits Script | Kenniel
-- Loadstring: loadstring(game:HttpGet("https://raw.githubusercontent.com/Kenniel123/BloxFruits/refs/heads/main/BloxFruits"))()

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Blox Fruits - Kenniel", "DarkTheme")

-- Main
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Auto Farm")

MainSection:NewToggle("Auto Farm", "Automatically farm enemies", function(state)
    _G.AutoFarm = state
    while _G.AutoFarm do
        pcall(function()
            local player = game.Players.LocalPlayer
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
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
                if nearest then
                    char.HumanoidRootPart.CFrame = nearest.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool and tool:FindFirstChild("ClickToFire") then
                        tool:Activate()
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)

MainSection:NewToggle("Auto Quest", "Auto accept and complete quests", function(state)
    _G.AutoQuest = state
    while _G.AutoQuest do
        pcall(function()
            local player = game.Players.LocalPlayer
            local level = player.Data.Level.Value
            for _, quest in pairs(workspace:GetDescendants()) do
                if quest:IsA("Model") and quest.Name:find("Quest") and quest:FindFirstChild("HumanoidRootPart") then
                    local text = quest:FindFirstChild("Dialog") or quest:FindFirstChild("Part")
                    if text then
                        local d = (quest.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                        if d < 20 then
                            fireproximityprompt(quest:FindFirstChildWhichIsA("ProximityPrompt"))
                        elseif d > 100 then
                            player.Character.HumanoidRootPart.CFrame = quest.HumanoidRootPart.CFrame
                        end
                    end
                end
            end
        end)
        task.wait(1)
    end
end)

-- Stats
local StatsTab = Window:NewTab("Stats")
local StatsSection = StatsTab:NewSection("Auto Stats")

StatsSection:NewToggle("Auto Melee", "Auto assign stats to melee", function(state)
    _G.AutoMelee = state
    while _G.AutoMelee do
        pcall(function()
            local player = game.Players.LocalPlayer
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
            local player = game.Players.LocalPlayer
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
            local player = game.Players.LocalPlayer
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
            local player = game.Players.LocalPlayer
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
        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = data[2]
        end
    end)
end

-- Misc
local MiscTab = Window:NewTab("Misc")
local MiscSection = MiscTab:NewSection("Utilities")

MiscSection:NewButton("Rejoin Server", "Rejoin the current server", function()
    local ts = game:GetService("TeleportService")
    local p = game.Players.LocalPlayer
    ts:Teleport(game.PlaceId, p)
end)

MiscSection:NewButton("Server Hop", "Hop to another server", function()
    local ts = game:GetService("TeleportService")
    local p = game.Players.LocalPlayer
    local http = game:GetService("HttpService")
    local req = http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
    for _, server in pairs(req.data) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            ts:TeleportToPlaceInstance(game.PlaceId, server.id, p)
            break
        end
    end
end)

MiscSection:NewSlider("Walk Speed", "Change walk speed", 250, 16, function(s)
    local player = game.Players.LocalPlayer
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = s
    end
end)

MiscSection:NewSlider("Jump Power", "Change jump power", 500, 50, function(s)
    local player = game.Players.LocalPlayer
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.JumpPower = s
    end
end)

-- Notify
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Blox Fruits",
    Text = "Script loaded successfully!",
    Duration = 3
})
