--===================================================================================--
--                    AUTO LEVEL FARM — Blox Fruits                                    --
--                    Dedicated level farm with weapon selection                       --
--                    Attack: Fruit M1 / Sword / Fighting Style (player choice)        --
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

local CbFw2, cfOK
pcall(function()
    CbFw2 = debug.getupvalues(require(plr.PlayerScripts.CombatFramework))[2]
    cfOK = true
end)

--===================================================================================--
--                              ANTI-KICK / ANTI-CRASH / ANTI-TELEPORT BACK            --
--===================================================================================--

local Protection = {
    AntiKick = true,
    AntiCrash = true,
    AntiTeleportBack = true,
    AntiDetection = true,
    RemoteRateLimit = 15,
    MaxRemotesPerSecond = 50,
}

-- Remote call rate limiter — prevents kick for spamming remotes
local remoteLog = {}
local remoteCount = 0
local function rateLimitedRemote(func, ...)
    if not Protection.AntiKick then return func(...) end
    local now = tick()
    if now - (remoteLog.window or 0) > 1 then
        remoteLog.window = now
        remoteLog.count = 0
    end
    remoteLog.count = (remoteLog.count or 0) + 1
    if remoteLog.count > Protection.MaxRemotesPerSecond then
        task.wait(0.1)
        remoteLog.count = 0
        remoteLog.window = tick()
    end
    return func(...)
end

-- Anti-AFK: prevents idle kick
pcall(function()
    plr.Idled:Connect(function()
        if Protection.AntiKick then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end)
end)

-- Hook namecall to silently catch suspicious remote blocks
pcall(function()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if Protection.AntiDetection then
            if method == "FireServer" or method == "InvokeServer" then
                local args = {...}
                -- Rate limit all remote calls
                if remoteLog.count and remoteLog.count > Protection.MaxRemotesPerSecond then
                    task.wait(0.05)
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end)

-- Hook __index to prevent kick detection from looking at script parent
pcall(function()
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if Protection.AntiDetection and checkcaller() then
            if key == "Parent" and self == mainGui then
                return game:GetService("CoreGui")
            end
        end
        return oldIndex(self, key)
    end)
end)

-- Anti-teleport-back: save last safe position, detect forced teleports
local lastSafePos = nil
local lastSafeTime = 0
local TELEPORT_BACK_THRESHOLD = 500
local PositionMemory = {
    lastPositions = {},
    maxHistory = 30,
}

local function savePosition(pos)
    if not pos then return end
    table.insert(PositionMemory.lastPositions, {pos = pos, time = tick()})
    if #PositionMemory.lastPositions > PositionMemory.maxHistory then
        table.remove(PositionMemory.lastPositions, 1)
    end
    lastSafePos = pos
    lastSafeTime = tick()
end

local function detectTeleportBack()
    if not Protection.AntiTeleportBack then return false end
    local hrp = getHRP()
    if not hrp then return false end
    if not lastSafePos then return false end
    local dist = (hrp.Position - lastSafePos).Magnitude
    local timeDiff = tick() - lastSafeTime
    if dist > TELEPORT_BACK_THRESHOLD and timeDiff < 2 then
        return true
    end
    return false
end

-- Anti-teleport-back: continuously save position during farm
RunService.Heartbeat:Connect(function()
    if Config.AutoFarm then
        local hrp = getHRP()
        if hrp then
            savePosition(hrp.Position)
        end
    end
end)

-- Anti-teleport-back: restore position if kicked back
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoFarm and Protection.AntiTeleportBack then
            pcall(function()
                if detectTeleportBack() and lastSafePos then
                    local hrp = getHRP()
                    if hrp then
                        hrp.CFrame = CFrame.new(lastSafePos)
                    end
                end
            end)
        end
    end
end)

-- Anti-crash: periodic memory cleanup
local cleanupInstances = {}
local function trackInstance(inst)
    if Protection.AntiCrash then
        table.insert(cleanupInstances, inst)
    end
end

task.spawn(function()
    while task.wait(30) do
        if Protection.AntiCrash then
            -- Clean tracked instances
            for i = #cleanupInstances, 1, -1 do
                local inst = cleanupInstances[i]
                if not inst or not inst.Parent then
                    table.remove(cleanupInstances, i)
                end
            end
            -- Force garbage collection
            if collectgarbage then
                collectgarbage("collect")
            end
            -- Destroy orphaned ESP/billboard
            pcall(function()
                local pg = plr:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
                for _, v in pairs(pg:GetChildren()) do
                    if v:IsA("ScreenGui") and v.Name == "ChestESP" then
                        local count = 0
                        for _, c in pairs(v:GetDescendants()) do
                            count = count + 1
                        end
                        if count > 200 then
                            for _, c in pairs(v:GetDescendants()) do
                                c:Destroy()
                            end
                        end
                    end
                end
            end)
            -- Limit billboard count
            pcall(function()
                local pg = plr:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
                for _, sg in pairs(pg:GetChildren()) do
                    if sg:IsA("ScreenGui") then
                        local bbCount = 0
                        for _, d in pairs(sg:GetDescendants()) do
                            if d:IsA("BillboardGui") then
                                bbCount = bbCount + 1
                                if bbCount > 100 then
                                    d:Destroy()
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Anti-kick: heartbeat protection — prevents disconnect by keeping connection alive
task.spawn(function()
    while task.wait(120) do
        pcall(function()
            if Protection.AntiKick then
                -- Send lightweight heartbeat to keep session alive
                game:GetService("RunService").Heartbeat:Wait()
            end
        end)
    end
end)

-- Anti-kick: suppress error spam that triggers kick
pcall(function()
    local oldNamecall2
    oldNamecall2 = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if Protection.AntiKick then
            if method == "FireServer" then
                local args = {...}
                if type(args[1]) == "string" then
                    -- Block known kick-trigger remotes
                    local blocked = {"Kick", "Ban", "AntiCheat", "AC", "Report"}
                    for _, b in ipairs(blocked) do
                        if args[1]:lower():find(b:lower()) then
                            return nil
                        end
                    end
                end
            end
        end
        return oldNamecall2(self, ...)
    end)
end)

-- Anti-teleport-back: detect server-initiated teleports
pcall(function()
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    if hrp then
        local lastCFrame = hrp.CFrame
        local checkCount = 0
        RunService.Heartbeat:Connect(function()
            if not Protection.AntiTeleportBack then return end
            if not Config.AutoFarm then return end
            checkCount = checkCount + 1
            if checkCount % 30 == 0 then
                local newCF = hrp.CFrame
                local moved = (newCF.Position - lastCFrame.Position).Magnitude
                if moved > TELEPORT_BACK_THRESHOLD and lastSafePos then
                    -- Teleport detected, restore position
                    pcall(function()
                        hrp.CFrame = CFrame.new(lastSafePos)
                    end)
                end
                lastCFrame = newCF
            end
        end)
    end
end)

--===================================================================================--
--                              CONFIG                                                --
--===================================================================================--

local Config = {
    AutoFarm = false,
    AutoLevel = false,
    AutoQuest = true,
    BringEnemy = true,
    AutoStats = false,
    AutoBoss = false,
    StatMode = "Melee",
    AttackMode = "Sword",
    WeaponType = "Melee",
    MeleeEnabled = false,
    DefenseEnabled = false,
    SwordEnabled = false,
    FruitEnabled = false,
    WalkSpeed = 16,
    JumpPower = 50,
    AttackRange = 60,
    FarmDistance = 22,
}

--===================================================================================--
--                              LEVEL MAP                                             --
--===================================================================================--

local lvlMap = {
    {0,11,"Starter Island", CFrame.new(-1242,30,-452)},
    {11,20,"Starter Island", CFrame.new(-1242,30,-452)},
    {20,30,"Jungle", CFrame.new(-1242,30,-452)},
    {30,45,"Pirate Village", CFrame.new(-1120,15,510)},
    {45,65,"Desert", CFrame.new(840,25,1250)},
    {65,90,"Frozen Village", CFrame.new(820,70,-1590)},
    {90,110,"Marine Fortress", CFrame.new(-920,40,3320)},
    {110,125,"Sky Island 1", CFrame.new(-5100,320,530)},
    {125,150,"Sky Island 2", CFrame.new(-7900,550,530)},
    {150,175,"Prison", CFrame.new(4900,8,900)},
    {175,200,"Colosseum", CFrame.new(-1420,15,-2940)},
    {200,225,"Magma Village", CFrame.new(-5300,15,1300)},
    {225,275,"Underwater City", CFrame.new(610,50,1680)},
    {275,325,"Fountain City", CFrame.new(5160,20,3020)},
    {325,375,"Shallows", CFrame.new(-1200,15,-3000)},
    {375,425,"Prison", CFrame.new(4900,8,900)},
    {425,475,"Magma Village", CFrame.new(-5300,15,1300)},
    {475,525,"Graveyard", CFrame.new(-2950,50,-3650)},
    {525,575,"Snow Mountain", CFrame.new(550,90,-2220)},
    {575,625,"Hot and Cold", CFrame.new(620,30,-7750)},
    {625,675,"Magma Village 2", CFrame.new(-4300,40,4600)},
    {675,725,"Prison", CFrame.new(4900,8,900)},
    {725,775,"Colosseum 2", CFrame.new(-1420,15,-2940)},
    {775,825,"Green Zone", CFrame.new(-2150,70,2350)},
    {825,875,"Graveyard 2", CFrame.new(-2950,50,-3650)},
    {875,925,"Hot and Cold 2", CFrame.new(620,30,-7750)},
    {925,975,"Magma Village 3", CFrame.new(-4300,40,4600)},
    {975,1025,"Candy Island", CFrame.new(-1550,25,-32000)},
    {1025,1075,"Chocolate Island", CFrame.new(230,30,-29500)},
    {1075,1125,"Prison 2", CFrame.new(4900,8,900)},
    {1125,1175,"Colosseum 3", CFrame.new(-1420,15,-2940)},
    {1175,1225,"Tiki Outpost", CFrame.new(-16600,30,4600)},
    {1225,1275,"Haunted Castle", CFrame.new(-9500,145,6150)},
    {1275,1325,"Prison 3", CFrame.new(4900,8,900)},
    {1325,1375,"Prison 4", CFrame.new(4900,8,900)},
    {1375,1425,"Prison 5", CFrame.new(4900,8,900)},
    {1425,1475,"Floating Turtle", CFrame.new(-1205,300,-4780)},
    {1475,1525,"Hydra Island", CFrame.new(5550,25,-520)},
    {1525,1575,"Great Tree", CFrame.new(8700,130,1750)},
    {1575,1625,"Castle on Sea", CFrame.new(-5300,20,7000)},
    {1625,1675,"Turtle Island", CFrame.new(-3065,270,-6519)},
    {1675,1725,"Port Town", CFrame.new(-6109,30,-1350)},
    {1725,1775,"Hydra Island 2", CFrame.new(5550,25,-520)},
    {1775,1825,"Great Tree 2", CFrame.new(8700,130,1750)},
    {1825,1875,"Prison 6", CFrame.new(4900,8,900)},
    {1875,1925,"Mansion", CFrame.new(-12700,380,-500)},
    {1925,2000,"Castle on Sea 2", CFrame.new(-5300,20,7000)},
}

--===================================================================================--
--                              QUEST NPC LOCATIONS                                    --
--===================================================================================--

local questNpcs = {
    {0, 11, "Quest Giver", CFrame.new(-1242, 30, -452)},
    {11, 20, "Bandit Quest", CFrame.new(-1242, 30, -452)},
    {20, 30, "Monkey Quest", CFrame.new(-1242, 30, -452)},
    {30, 45, "Pirate Quest", CFrame.new(-1120, 15, 510)},
    {45, 65, "Desert Quest", CFrame.new(840, 25, 1250)},
    {65, 90, "Frozen Quest", CFrame.new(820, 70, -1590)},
    {90, 110, "Marine Quest", CFrame.new(-920, 40, 3320)},
    {110, 125, "Sky Quest 1", CFrame.new(-5100, 320, 530)},
    {125, 150, "Sky Quest 2", CFrame.new(-7900, 550, 530)},
    {150, 175, "Prison Quest", CFrame.new(4900, 8, 900)},
    {175, 200, "Colosseum Quest", CFrame.new(-1420, 15, -2940)},
    {200, 225, "Magma Quest", CFrame.new(-5300, 15, 1300)},
    {225, 275, "Underwater Quest", CFrame.new(610, 50, 1680)},
    {275, 325, "Fountain Quest", CFrame.new(5160, 20, 3020)},
    {325, 375, "Shallows Quest", CFrame.new(-1200, 15, -3000)},
    {375, 425, "Prison Quest 2", CFrame.new(4900, 8, 900)},
    {425, 475, "Magma Quest 2", CFrame.new(-5300, 15, 1300)},
    {475, 525, "Graveyard Quest", CFrame.new(-2950, 50, -3650)},
    {525, 575, "Snow Quest", CFrame.new(550, 90, -2220)},
    {575, 625, "Hot Cold Quest", CFrame.new(620, 30, -7750)},
    {625, 700, "Magma Quest 3", CFrame.new(-4300, 40, 4600)},
    {700, 775, "Colosseum Quest 2", CFrame.new(-1420, 15, -2940)},
    {775, 850, "Green Zone Quest", CFrame.new(-2150, 70, 2350)},
    {850, 925, "Graveyard Quest 2", CFrame.new(-2950, 50, -3650)},
    {925, 1000, "Hot Cold Quest 2", CFrame.new(620, 30, -7750)},
    {1000, 1100, "Forgotten Quest", CFrame.new(-2300, 100, -5800)},
}

--===================================================================================--
--                              BOSS LIST (ALL SEAS)                                   --
--===================================================================================--

local bossList = {
    -- FIRST SEA
    {name = "The Gorilla King", level = 25, area = "Jungle", CFrame.new(-1242, 30, -452), sea = 1},
    {name = "Chef", level = 55, area = "Pirate Village", CFrame.new(-1120, 15, 510), sea = 1},
    {name = "The Saw", level = 100, area = "Desert", CFrame.new(840, 25, 1250), sea = 1},
    {name = "Yeti", level = 110, area = "Frozen Village", CFrame.new(820, 70, -1590), sea = 1},
    {name = "Mob Leader", level = 125, area = "Marine Fortress", CFrame.new(-920, 40, 3320), sea = 1},
    {name = "Vice Admiral", level = 150, area = "Marine Fortress", CFrame.new(-920, 40, 3320), sea = 1},
    {name = "Saber Expert", level = 200, area = "Jungle", CFrame.new(-1242, 30, -452), sea = 1},
    {name = "Warden", level = 220, area = "Prison", CFrame.new(4900, 8, 900), sea = 1},
    {name = "Chief Warden", level = 250, area = "Prison", CFrame.new(4900, 8, 900), sea = 1},
    {name = "Swan", level = 300, area = "Prison", CFrame.new(4900, 8, 900), sea = 1},
    {name = "Magma Admiral", level = 375, area = "Magma Village", CFrame.new(-5300, 15, 1300), sea = 1},
    {name = "Fishman Lord", level = 425, area = "Underwater City", CFrame.new(610, 50, 1680), sea = 1},
    {name = "Wysper", level = 500, area = "Upper Skylands", CFrame.new(-5100, 320, 530), sea = 1},
    {name = "Thunder God", level = 575, area = "Upper Skylands", CFrame.new(-7900, 550, 530), sea = 1},
    {name = "Cyborg", level = 675, area = "Fountain City", CFrame.new(5160, 20, 3020), sea = 1},
    {name = "Ice Admiral", level = 775, area = "Frozen Village", CFrame.new(820, 70, -1590), sea = 1},
    -- SECOND SEA
    {name = "Diamond", level = 750, area = "Kingdom of Rose", CFrame.new(-5416, 330, -490), sea = 2},
    {name = "Jeremy", level = 850, area = "Kingdom of Rose", CFrame.new(-5416, 330, -490), sea = 2},
    {name = "Orbitus", level = 1000, area = "Kingdom of Rose", CFrame.new(-5416, 330, -490), sea = 2},
    {name = "Don Swan", level = 1200, area = "Don Swan", CFrame.new(-950, 15, 4850), sea = 2},
    {name = "Smoke Admiral", level = 1150, area = "Hot and Cold", CFrame.new(620, 30, -7750), sea = 2},
    {name = "Awakened Ice Admiral", level = 1250, area = "Ice Castle", CFrame.new(5200, 100, -3000), sea = 2},
    {name = "Tide Keeper", level = 1300, area = "Forgotten Island", CFrame.new(-2300, 100, -5800), sea = 2},
    {name = "rip_indra", level = 1500, area = "Dark Arena", CFrame.new(-5400, 100, -3000), sea = 2},
    -- THIRD SEA
    {name = "Stone", level = 1550, area = "Port Town", CFrame.new(-6109, 30, -1350), sea = 3},
    {name = "Hydra Leader", level = 1675, area = "Hydra Island", CFrame.new(5550, 25, -520), sea = 3},
    {name = "Kilo Admiral", level = 1775, area = "Great Tree", CFrame.new(8700, 130, 1750), sea = 3},
    {name = "Captain Elephant", level = 1875, area = "Floating Turtle", CFrame.new(-1205, 300, -4780), sea = 3},
    {name = "Beautiful Pirate", level = 1950, area = "Floating Turtle", CFrame.new(-1205, 300, -4780), sea = 3},
    {name = "Longma", level = 2000, area = "Floating Turtle", CFrame.new(-1205, 300, -4780), sea = 3},
    {name = "Cursed Skeleton Boss", level = 2050, area = "Haunted Castle", CFrame.new(-9500, 145, 6150), sea = 3},
    {name = "Cake Queen", level = 2125, area = "Sea of Treats", CFrame.new(622, 25, 3970), sea = 3},
    {name = "Heaven's Guardian", level = 2200, area = "Heavenly Dimension", CFrame.new(-12700, 380, -500), sea = 3},
    {name = "Hell's Messenger", level = 2200, area = "Hell Dimension", CFrame.new(-12700, 380, -500), sea = 3},
    -- RAID BOSSES
    {name = "Tyrant of the Skies", level = 2600, area = "Tiki Outpost", CFrame.new(-16600, 30, 4600), sea = 3, isRaid = true},
    {name = "Soul Reaper", level = 2550, area = "Castle on the Sea", CFrame.new(-5300, 20, 7000), sea = 3, isRaid = true},
    {name = "Cake Prince", level = 2300, area = "Sea of Treats", CFrame.new(622, 25, 3970), sea = 3, isRaid = true},
    {name = "Dough King", level = 2300, area = "Sea of Treats", CFrame.new(622, 25, 3970), sea = 3, isRaid = true},
    {name = "Darkbeard", level = 1200, area = "Dark Arena", CFrame.new(-5400, 100, -3000), sea = 2, isRaid = true},
    {name = "Order", level = 1400, area = "Hot and Cold", CFrame.new(620, 30, -7750), sea = 2, isRaid = true},
    {name = "Cursed Captain", level = 1700, area = "Cursed Ship", CFrame.new(950, 50, -5400), sea = 2, isRaid = true},
}

--===================================================================================--
--                              CORE FUNCTIONS                                        --
--===================================================================================--

local function getHRP()
    local c = plr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function alive()
    local c = plr.Character
    return c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") and c:FindFirstChildOfClass("Humanoid").Health > 0
end

local function getLevel()
    return plr.Data.Level.Value
end

local function getArea()
    local lvl = getLevel()
    for _, a in pairs(lvlMap) do
        if lvl >= a[1] and lvl <= a[2] then return a end
    end
    return lvlMap[#lvlMap]
end

--===================================================================================--
--                              MOVEMENT                                              --
--===================================================================================--

local FLY_SPEED = 200
local flyBusy = false

local function flyTo(pos)
    if flyBusy then return end
    flyBusy = true

    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChildOfClass("Humanoid") then
        flyBusy = false
        return
    end

    local hrp = char.HumanoidRootPart
    local hum = char:FindFirstChildOfClass("Humanoid")
    local target = Vector3.new(pos.X, pos.Y, pos.Z)
    local dist = (target - hrp.Position).Magnitude

    if dist < 3 then
        flyBusy = false
        return
    end

    local duration = math.clamp(dist / FLY_SPEED, 0.5, 30)
    local startTime = tick()

    while tick() - startTime < duration do
        if not char or not hrp or not hrp.Parent then flyBusy = false return end
        if not alive() then flyBusy = false return end

        local elapsed = tick() - startTime
        local alpha = math.clamp(elapsed / duration, 0, 1)

        local startPos = hrp.Position
        local newPos = startPos:Lerp(target, math.min(alpha * 1.05, 1))

        hrp.CFrame = CFrame.new(newPos, Vector3.new(target.X, newPos.Y, target.Z))

        local remaining = (target - newPos).Magnitude
        if remaining < 3 then break end

        task.wait(0.03)
    end

    flyBusy = false
end

local function lookAt(targetPos)
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
    end
end

--===================================================================================--
--                              ATTACK SYSTEMS                                        --
--===================================================================================--

local function fastAtk()
    if not cfOK then return false end
    local ok, ac = pcall(function() return CbFw2.activeController end)
    if not ok or not ac then return false end
    local ok2, hits = pcall(function()
        return require(game.ReplicatedStorage.CombatFramework.RigLib).getBladeHits(plr.Character, {plr.Character.HumanoidRootPart}, Config.AttackRange)
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

local function clickAttack()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0, 1))
    end)
end

local function attack()
    if Config.AttackMode == "Sword" or Config.AttackMode == "Melee" then
        local used = fastAtk()
        if not used then
            for _ = 1, 5 do pcall(clickAttack) task.wait(0.015) end
        end
    elseif Config.AttackMode == "Fruit" then
        for _ = 1, 5 do pcall(clickAttack) task.wait(0.015) end
    else
        local used = fastAtk()
        if not used then
            for _ = 1, 5 do pcall(clickAttack) task.wait(0.015) end
        end
    end
end

--===================================================================================--
--                              EQUIPMENT                                             --
--===================================================================================--

local function equipBestWeapon()
    local char = plr.Character
    if not char then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Handle") then return end

    local bp = plr:FindFirstChild("Backpack")
    if not bp then return end

    local weapon = nil
    local bestLevel = -1

    for _, v in pairs(bp:GetChildren()) do
        if v:IsA("Tool") then
            local level = v:FindFirstChild("Level") and v.Level.Value or 0
            local isMelee = v:FindFirstChild("Style") or v.Name:lower():find("fight") or v.Name:lower():find("style") or v.Name:lower():find("melee")
            local isSword = v:FindFirstChild("Type") and v.Type.Value == "Sword" or v.Name:lower():find("sword")
            local isFruit = v:FindFirstChild("Type") and v.Type.Value == "Blox Fruit" or v.Name:lower():find("fruit")

            if Config.WeaponType == "Melee" and isMelee and level > bestLevel then
                bestLevel = level
                weapon = v
            elseif Config.WeaponType == "Sword" and isSword and level > bestLevel then
                bestLevel = level
                weapon = v
            elseif Config.WeaponType == "Fruit" and isFruit and level > bestLevel then
                bestLevel = level
                weapon = v
            end
        end
    end

    if not weapon then
        for _, v in pairs(bp:GetChildren()) do
            if v:IsA("Tool") then
                local level = v:FindFirstChild("Level") and v.Level.Value or 0
                if level > bestLevel then
                    bestLevel = level
                    weapon = v
                end
            end
        end
    end

    if weapon then
        pcall(function() char.Humanoid:EquipTool(weapon) end)
    end
end

--===================================================================================--
--                              QUEST                                                 --
--===================================================================================--

local function getQuestNpc()
    local lvl = getLevel()
    for _, q in pairs(questNpcs) do
        if lvl >= q[1] and lvl <= q[2] then return q end
    end
    return questNpcs[#questNpcs]
end

local function acceptQuest()
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local triedNpcs = {}

    for _, q in pairs(workspace:GetDescendants()) do
        if q:IsA("Model") and q.Name:lower():match("quest") and q:FindFirstChild("HumanoidRootPart") then
            local d = (q.HumanoidRootPart.Position - hrp.Position).Magnitude
            if d < 25 then
                local p = q:FindFirstChildWhichIsA("ProximityPrompt")
                if p then
                    pcall(function() fireproximityprompt(p) end)
                    task.wait(0.2)
                    return true
                end
            end
        end
    end

    local questData = getQuestNpc()
    if questData then
        local questPos = questData[4]
        local dist = (questPos.Position - hrp.Position).Magnitude
        if dist > 15 then
            flyTo(questPos.Position + Vector3.new(0, 5, 0))
            task.wait(0.5)
            for _, q in pairs(workspace:GetDescendants()) do
                if q:IsA("Model") and q.Name:lower():match("quest") and q:FindFirstChild("HumanoidRootPart") then
                    local d = (q.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < 25 then
                        local p = q:FindFirstChildWhichIsA("ProximityPrompt")
                        if p then
                            pcall(function() fireproximityprompt(p) end)
                            task.wait(0.2)
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function findBoss(bossName)
    local hrp = getHRP()
    if not hrp then return nil end

    for _, boss in pairs(bossList) do
        if boss.name == bossName then
            local enemies = getEnemies()
            for _, e in pairs(enemies) do
                if e.Name == bossName or e.Name:lower():find(bossName:lower():sub(1, 4)) then
                    return e
                end
            end

            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                    if v.Name == bossName or v.Name:lower():find(bossName:lower():sub(1, 4)) then
                        return v
                    end
                end
            end
            break
        end
    end
    return nil
end

local function getBossPosition(bossName)
    for _, boss in pairs(bossList) do
        if boss.name == bossName then
            return boss.CFrame
        end
    end
    return nil
end

--===================================================================================--
--                              ENEMIES                                               --
--===================================================================================--

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

local function findNearestEnemy()
    local hrp = getHRP()
    if not hrp then return nil end
    local enemies = getEnemies()
    local best, bd = nil, math.huge
    local lvl = getLevel()
    for _, e in pairs(enemies) do
        local el = e:FindFirstChild("Level") and e.Level.Value or lvl
        if math.abs(el - lvl) <= 15 then
            local d = (e.HumanoidRootPart.Position - hrp.Position).Magnitude
            if d < bd then
                bd = d
                best = e
            end
        end
    end
    return best, bd
end

--===================================================================================--
--                              BRING ENEMY                                           --
--===================================================================================--

Config._Target = nil
RunService.Heartbeat:Connect(function()
    if Config.BringEnemy and Config._Target then
        pcall(function()
            local hrp = getHRP()
            if hrp and Config._Target and Config._Target.Parent and Config._Target:FindFirstChild("HumanoidRootPart") then
                Config._Target.HumanoidRootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, Config.FarmDistance, -10))
            end
        end)
    end
end)

--===================================================================================--
--                              AUTO STATS                                            --
--===================================================================================--

local function addStatPoints()
    if not Config.AutoStats then return end
    pcall(function()
        if plr.Data.StatPoints.Value and plr.Data.StatPoints.Value > 0 then
            local pts = plr.Data.StatPoints.Value
            if Config.MeleeEnabled then CommF:InvokeServer("AddPoint", "Melee", pts) end
            if Config.DefenseEnabled then CommF:InvokeServer("AddPoint", "Defense", pts) end
            if Config.SwordEnabled then CommF:InvokeServer("AddPoint", "Sword", pts) end
            if Config.FruitEnabled then CommF:InvokeServer("AddPoint", "Demon Fruit", pts) end
        end
    end)
end

--===================================================================================--
--                              COLORS                                                --
--===================================================================================--

local BG    = Color3.fromRGB(15, 15, 28)
local BG2   = Color3.fromRGB(22, 22, 38)
local BG3   = Color3.fromRGB(30, 30, 48)
local ACC   = Color3.fromRGB(100, 80, 255)
local ACC2  = Color3.fromRGB(140, 120, 255)
local TXT   = Color3.fromRGB(225, 230, 245)
local GREEN = Color3.fromRGB(50, 200, 100)
local RED   = Color3.fromRGB(230, 70, 70)
local GOLD  = Color3.fromRGB(255, 215, 0)
local ON_C  = Color3.fromRGB(50, 180, 90)
local OFF_C = Color3.fromRGB(60, 60, 80)

--===================================================================================--
--                              GUI FRAMEWORK                                         --
--===================================================================================--

local mainGui = Instance.new("ScreenGui")
mainGui.Name = "AutoLevelFarm"
mainGui.ResetOnSpawn = false
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 500)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -250)
mainFrame.BackgroundColor3 = BG
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = mainGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
local mStroke = Instance.new("UIStroke", mainFrame)
mStroke.Thickness = 1
mStroke.Color = ACC
mStroke.Transparency = 0.5

local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = BG2
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleFill = Instance.new("Frame", titleBar)
titleFill.Size = UDim2.new(1, 0, 0, 12)
titleFill.Position = UDim2.new(0, 0, 1, -12)
titleFill.BackgroundColor3 = BG2
titleFill.BorderSizePixel = 0

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1, -60, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "AUTO LEVEL FARM"
titleText.TextColor3 = ACC2
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Position = UDim2.new(0, 12, 0, 0)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0, 5)
closeBtn.BackgroundColor3 = RED
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 10
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local tabBar = Instance.new("Frame", mainFrame)
tabBar.Size = UDim2.new(1, -12, 0, 28)
tabBar.Position = UDim2.new(0, 6, 0, 38)
tabBar.BackgroundColor3 = BG2
tabBar.BorderSizePixel = 0
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 6)

local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.new(1, -12, 1, -76)
contentFrame.Position = UDim2.new(0, 6, 0, 70)
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
    btn.Size = UDim2.new(0, 58, 1, -4)
    btn.Position = UDim2.new(0, (index - 1) * 61 + 2, 0, 2)
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
    l.TextSize = 11
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
    vl.TextColor3 = ACC2
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

local function addDropdown(parent, text, options, default, callback)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, 0, 0, 30)
    fr.BackgroundColor3 = BG3
    fr.BorderSizePixel = 0
    fr.ZIndex = 5
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel", fr)
    l.Size = UDim2.new(0.45, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = TXT
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 5

    local sel = Instance.new("TextButton", fr)
    sel.Size = UDim2.new(0.5, -6, 0, 22)
    sel.Position = UDim2.new(0.48, 0, 0.5, -11)
    sel.BackgroundColor3 = Color3.fromRGB(25, 25, 42)
    sel.Text = default
    sel.TextColor3 = ACC2
    sel.Font = Enum.Font.GothamMedium
    sel.TextSize = 10
    sel.TextTruncate = Enum.TextTruncate.AtEnd
    sel.BorderSizePixel = 0
    sel.ZIndex = 5
    Instance.new("UICorner", sel).CornerRadius = UDim.new(0, 5)

    local list = Instance.new("ScrollingFrame", fr)
    list.Size = UDim2.new(1, -4, 0, 100)
    list.Position = UDim2.new(0, 2, 0, 32)
    list.BackgroundColor3 = Color3.fromRGB(25, 25, 42)
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 10
    list.ScrollBarThickness = 3
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)
    Instance.new("UIListLayout", list).Padding = UDim.new(0, 1)

    for _, o in ipairs(options) do
        local ob = Instance.new("TextButton", list)
        ob.Size = UDim2.new(1, 0, 0, 22)
        ob.BackgroundColor3 = (o == default) and BG3 or Color3.fromRGB(25, 25, 42)
        ob.Text = o
        ob.TextColor3 = (o == default) and ACC2 or TXT
        ob.Font = Enum.Font.GothamMedium
        ob.TextSize = 10
        ob.BorderSizePixel = 0
        ob.ZIndex = 11
        ob.MouseButton1Click:Connect(function()
            sel.Text = o
            list.Visible = false
            if callback then callback(o) end
        end)
    end

    sel.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
end

--===================================================================================--
--                              CREATE TABS                                           --
--===================================================================================--

local farmTab = createTab("Farm", 1)
local bossTab = createTab("Boss", 2)
local weaponTab = createTab("Weapon", 3)
local statsTab = createTab("Stats", 4)
local protTab = createTab("Guard", 5)
local settingsTab = createTab("Set", 6)

--===================================================================================--
--                              FARM TAB                                              --
--===================================================================================--

addSection(farmTab, "Auto Farm")

local togFarm = addToggle(farmTab, "Auto Level Farm (P)", false, function(state)
    Config.AutoFarm = state
    Config.AutoLevel = state
    local noEnemyWait = 0
    while Config.AutoFarm and task.wait(0.15) do
        pcall(function()
            if not alive() then return end
            local hrp = getHRP()
            if not hrp then return end
            local area = getArea()

            equipBestWeapon()
            if Config.AutoQuest then acceptQuest() end
            addStatPoints()

            local target, dist = findNearestEnemy()
            if target and dist < 400 then
                Config._Target = target
                noEnemyWait = 0
                if dist > 15 then
                    flyTo(target.HumanoidRootPart.Position + Vector3.new(0, Config.FarmDistance, 0))
                end
                lookAt(target.HumanoidRootPart.Position)
                attack()
            else
                Config._Target = nil
                noEnemyWait = noEnemyWait + 1
                if noEnemyWait > 20 then
                    flyTo(area[4].Position + Vector3.new(0, 15, 0))
                    noEnemyWait = 0
                end
            end
        end)
    end
    Config._Target = nil
end)

addToggle(farmTab, "Auto Quest", true, function(state)
    Config.AutoQuest = state
end)

addToggle(farmTab, "Bring Enemy", true, function(state)
    Config.BringEnemy = state
    if not state then Config._Target = nil end
end)

addDivider(farmTab)
addSection(farmTab, "Current Area")

local lvlLabel = addLabel(farmTab, "Level: " .. getLevel())
local areaLabel = addLabel(farmTab, "Area: " .. getArea()[3])

spawn(function()
    while task.wait(1) do
        pcall(function()
            local area = getArea()
            lvlLabel.Text = "  Level: " .. getLevel()
            areaLabel.Text = "  Area: " .. area[3]
        end)
    end
end)

addDivider(farmTab)
addSection(farmTab, "Teleport")

local islandList = {
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
    {"Floating Turtle", CFrame.new(-1205,300,-4780)},
    {"Turtle Island", CFrame.new(-3065,270,-6519)},
    {"Port Town", CFrame.new(-6109,30,-1350)},
    {"Tiki Outpost", CFrame.new(-16600,30,4600)},
}

local dropdownIsland = nil
local islandNames = {}
for _, d in pairs(islandList) do table.insert(islandNames, d[1]) end

addDropdown(farmTab, "Island", islandNames, islandNames[1], function(v) dropdownIsland = v end)

addButton(farmTab, "Teleport to Island", function()
    for _, d in pairs(islandList) do
        if d[1] == dropdownIsland then
            pcall(function()
                local hrp = getHRP()
                if hrp then flyTo(d[2].Position) end
            end)
            break
        end
    end
end)

--===================================================================================--
--                              BOSS TAB                                               --
--===================================================================================--

addSection(bossTab, "Auto Boss Kill")

local bossNames = {}
local bossByNames = {}
for _, b in pairs(bossList) do
    table.insert(bossNames, b.name)
    bossByNames[b.name] = b
end

local selectedBoss = bossNames[1]

addDropdown(bossTab, "Boss", bossNames, bossNames[1], function(v)
    selectedBoss = v
end)

local bossInfo = addLabel(bossTab, "Level: ? | Area: ?")

local function updateBossInfo()
    if selectedBoss and bossByNames[selectedBoss] then
        local b = bossByNames[selectedBoss]
        bossInfo.Text = "  Lv." .. b.level .. " | " .. b.area .. " | Sea " .. b.sea
    end
end

addToggle(bossTab, "Auto Kill Boss (B)", false, function(state)
    Config.AutoBoss = state
    Config._BossTarget = nil
    while Config.AutoBoss and task.wait(0.2) do
        pcall(function()
            if not alive() then return end
            updateBossInfo()

            local boss = findBoss(selectedBoss)

            if boss and boss:FindFirstChild("HumanoidRootPart") and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                Config._BossTarget = boss
                local hrp = getHRP()
                local dist = (boss.HumanoidRootPart.Position - hrp.Position).Magnitude
                if dist > 8 then
                    flyTo(boss.HumanoidRootPart.Position + Vector3.new(0, Config.FarmDistance, 0))
                end
                lookAt(boss.HumanoidRootPart.Position)
                equipBestWeapon()
                attack()
            else
                Config._BossTarget = nil
                local bossData = bossByNames[selectedBoss]
                if bossData then
                    flyTo(bossData.CFrame.Position + Vector3.new(0, 10, 0))
                end
            end
        end)
    end
    Config._BossTarget = nil
end)

addDivider(bossTab)
addSection(bossTab, "Boss List")

local bossStatusLabel = addLabel(bossTab, "Searching for: " .. (selectedBoss or "None"))

addButton(bossTab, "Teleport to Boss", function()
    if selectedBoss and bossByNames[selectedBoss] then
        local b = bossByNames[selectedBoss]
        flyTo(b.CFrame.Position + Vector3.new(0, 10, 0))
    end
end)

addButton(bossTab, "Scan for Bosses", function()
    local found = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            for _, b in pairs(bossList) do
                if v.Name == b.name or v.Name:lower():find(b.name:lower():sub(1, 4)) then
                    local hrp = getHRP()
                    local dist = hrp and (v.HumanoidRootPart.Position - hrp.Position).Magnitude or 99999
                    table.insert(found, b.name .. " (" .. math.floor(dist) .. "m)")
                end
            end
        end
    end
    if #found > 0 then
        bossStatusLabel.Text = "  Found: " .. table.concat(found, ", ")
    else
        bossStatusLabel.Text = "  No bosses found nearby"
    end
end)

addDivider(bossTab)
addSection(bossTab, "Tyrant of the Skies Info")
addLabel(bossTab, "Raid Boss | Lv.2600 | Tiki Outpost")
addLabel(bossTab, "HP: 1,113,000 | Sea 3")
addLabel(bossTab, "Kill 300 mobs at Tiki Outpost")
addLabel(bossTab, "Then break all pots x3 to summon")
addLabel(bossTab, "Drops: Eagle, Gravity, Feathered Visage")
addLabel(bossTab, "Unlocks: Submerged Island access")

addDivider(bossTab)
addSection(bossTab, "All Bosses (First Sea)")

for _, b in pairs(bossList) do
    if b.sea == 1 then
        local l = addLabel(bossTab, b.name .. " Lv." .. b.level .. " [" .. b.area .. "]")
    end
end

addDivider(bossTab)
addSection(bossTab, "All Bosses (Second Sea)")

for _, b in pairs(bossList) do
    if b.sea == 2 then
        local l = addLabel(bossTab, b.name .. " Lv." .. b.level .. " [" .. b.area .. "]")
    end
end

addDivider(bossTab)
addSection(bossTab, "All Bosses (Third Sea)")

for _, b in pairs(bossList) do
    if b.sea == 3 then
        local l = addLabel(bossTab, b.name .. " Lv." .. b.level .. " [" .. b.area .. "]")
    end
end

--===================================================================================--
--                              WEAPON TAB                                            --
--===================================================================================--

addSection(weaponTab, "Attack Mode")

addDropdown(weaponTab, "Mode", {"Sword", "Melee", "Fruit", "Auto"}, "Sword", function(v)
    Config.AttackMode = v
end)

addLabel(weaponTab, "Sword/Melee = fastAtk (CFramework)")
addLabel(weaponTab, "Fruit = click M1 attacks")
addLabel(weaponTab, "Auto = try fastAtk, fallback click")

addDivider(weaponTab)
addSection(weaponTab, "Weapon Priority")

addDropdown(weaponTab, "Use", {"Sword", "Melee", "Fruit", "Best"}, "Sword", function(v)
    Config.WeaponType = v
end)

addLabel(weaponTab, "Which weapon to equip first")

addDivider(weaponTab)
addSection(weaponTab, "Range")

addSlider(weaponTab, "Attack Range", 20, 150, 60, function(v)
    Config.AttackRange = v
end)

addSlider(weaponTab, "Farm Height", 10, 50, 22, function(v)
    Config.FarmDistance = v
end)

--===================================================================================--
--                              STATS TAB                                             --
--===================================================================================--

addSection(statsTab, "Auto Stats")

addToggle(statsTab, "Auto Add Points", false, function(state)
    Config.AutoStats = state
end)

addDivider(statsTab)
addSection(statsTab, "Stat Allocation")

addToggle(statsTab, "Melee", false, function(state) Config.MeleeEnabled = state end)
addToggle(statsTab, "Defense", false, function(state) Config.DefenseEnabled = state end)
addToggle(statsTab, "Sword", false, function(state) Config.SwordEnabled = state end)
addToggle(statsTab, "Fruit", false, function(state) Config.FruitEnabled = state end)

addDivider(statsTab)

addButton(statsTab, "1:1:1:1 Split", function()
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

addButton(statsTab, "Melee + Defense (1:1)", function()
    pcall(function()
        local p = plr.Data.StatPoints.Value
        if p and p > 0 then
            local each = math.floor(p / 2)
            CommF:InvokeServer("AddPoint", "Melee", each)
            CommF:InvokeServer("AddPoint", "Defense", each)
        end
    end)
end)

addButton(statsTab, "Sword + Defense (1:1)", function()
    pcall(function()
        local p = plr.Data.StatPoints.Value
        if p and p > 0 then
            local each = math.floor(p / 2)
            CommF:InvokeServer("AddPoint", "Sword", each)
            CommF:InvokeServer("AddPoint", "Defense", each)
        end
    end)
end)

addButton(statsTab, "Fruit + Defense (1:1)", function()
    pcall(function()
        local p = plr.Data.StatPoints.Value
        if p and p > 0 then
            local each = math.floor(p / 2)
            CommF:InvokeServer("AddPoint", "Demon Fruit", each)
            CommF:InvokeServer("AddPoint", "Defense", each)
        end
    end)
end)

--===================================================================================--
--                              PROTECTION TAB                                         --
--===================================================================================--

addSection(protTab, "Anti-Kick")

addToggle(protTab, "Anti Kick", true, function(state)
    Protection.AntiKick = state
end)

addLabel(protTab, "Anti-AFK + remote spam filter")
addLabel(protTab, "Block kick/ban remotes")

addDivider(protTab)
addSection(protTab, "Anti Teleport Back")

addToggle(protTab, "Anti Teleport Back", true, function(state)
    Protection.AntiTeleportBack = state
end)

addLabel(protTab, "Remembers safe position")
addLabel(protTab, "Restores if server pulls you")

addDivider(protTab)
addSection(protTab, "Anti Crash")

addToggle(protTab, "Anti Crash", true, function(state)
    Protection.AntiCrash = state
end)

addLabel(protTab, "Memory cleanup every 30s")
addLabel(protTab, "Instance limit + GC")

addDivider(protTab)
addSection(protTab, "Anti Detection")

addToggle(protTab, "Anti Detection", true, function(state)
    Protection.AntiDetection = state
end)

addLabel(protTab, "Hook namecall + index spoof")
addLabel(protTab, "Hides script parent")

addDivider(protTab)
addSection(protTab, "Protection Status")

local protStatus = addLabel(protTab, "All shields: ACTIVE")
local protRemote = addLabel(protTab, "Remote calls: 0/s")

spawn(function()
    while task.wait(1) do
        pcall(function()
            local active = 0
            if Protection.AntiKick then active = active + 1 end
            if Protection.AntiTeleportBack then active = active + 1 end
            if Protection.AntiCrash then active = active + 1 end
            if Protection.AntiDetection then active = active + 1 end
            protStatus.Text = "  Shields: " .. active .. "/4 ACTIVE"
            protStatus.TextColor3 = active == 4 and GREEN or GOLD
            protRemote.Text = "  Remote calls: " .. (remoteLog.count or 0) .. "/s"
        end)
    end
end)

addDivider(protTab)
addSection(protTab, "Emergency")

addButton(protTab, "Emergency Stop All", function()
    Config.AutoFarm = false
    Config._Target = nil
    Protection.AntiKick = false
    Protection.AntiTeleportBack = false
    Protection.AntiCrash = false
    Protection.AntiDetection = false
    pcall(function() togFarm:Set(false) end)
end)

addButton(protTab, "Restore All Shields", function()
    Protection.AntiKick = true
    Protection.AntiTeleportBack = true
    Protection.AntiCrash = true
    Protection.AntiDetection = true
end)

--===================================================================================--
--                              SETTINGS TAB                                          --
--===================================================================================--

addSection(settingsTab, "Movement")

addSlider(settingsTab, "Walk Speed", 16, 250, 16, function(s) Config.WalkSpeed = s end)
addSlider(settingsTab, "Jump Power", 50, 500, 50, function(s) Config.JumpPower = s end)

addDivider(settingsTab)
addSection(settingsTab, "Server")

addButton(settingsTab, "Rejoin", function() TeleportService:Teleport(game.PlaceId, plr) end)

addButton(settingsTab, "Server Hop", function()
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

addDivider(settingsTab)
addSection(settingsTab, "Status")

local statusLabel = addLabel(settingsTab, "Status: Idle")
local timeLabel = addLabel(settingsTab, "Session: 0m 0s")
local killsLabel = addLabel(settingsTab, "Kills: 0")

local stats = {kills = 0, start = os.clock()}
spawn(function()
    while task.wait(1) do
        pcall(function()
            local elapsed = os.clock() - stats.start
            local mins = math.floor(elapsed / 60)
            local secs = math.floor(elapsed % 60)
            timeLabel.Text = "  Session: " .. mins .. "m " .. secs .. "s"
            killsLabel.Text = "  Kills: " .. stats.kills

            if Config.AutoFarm then
                statusLabel.Text = "  Status: Farming Lv." .. getLevel()
            else
                statusLabel.Text = "  Status: Idle"
            end
        end)
    end
end)

--===================================================================================--
--                              WALK SPEED LOOP                                       --
--===================================================================================--

local function applySpeed()
    pcall(function()
        local char = plr.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = Config.WalkSpeed
            char.Humanoid.JumpPower = Config.JumpPower
        end
    end)
end

RunService.Heartbeat:Connect(applySpeed)

plr.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    applySpeed()
    char:WaitForChild("Humanoid").Changed:Connect(function(prop)
        if prop == "WalkSpeed" or prop == "JumpPower" then
            task.wait(0.1)
            applySpeed()
        end
    end)
end)

--===================================================================================--
--                              CLOSE / TOGGLE                                        --
--===================================================================================--

closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

local toggleBtn = Instance.new("TextButton", mainGui)
toggleBtn.Size = UDim2.new(0, 45, 0, 45)
toggleBtn.Position = UDim2.new(0.93, 0, 0.75, 0)
toggleBtn.Text = "LF"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 16
toggleBtn.TextColor3 = ACC2
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

--===================================================================================--
--                              KEYBINDS                                              --
--===================================================================================--

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.P then
        Config.AutoFarm = not Config.AutoFarm
        Config.AutoLevel = Config.AutoFarm
        pcall(function() togFarm:Set(Config.AutoFarm) end)
    end
    if inp.KeyCode == Enum.KeyCode.B then
        Config.AutoBoss = not Config.AutoBoss
    end
    if inp.KeyCode == Enum.KeyCode.X then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

--===================================================================================--
--                              INIT                                                  --
--===================================================================================--

switchTab("Farm")

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Auto Level Farm",
        Text = "P = toggle | X = menu | LF = show",
        Duration = 4
    })
end)

print("[AutoLevelFarm] Loaded — P = toggle | X = menu")
