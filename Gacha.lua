--===================================================================================--
--                    GACHA FRUIT VISUALIZER — X8 CHANCE                              --
--                    Визуальная гача с шансом x8 на легендарный фрукт                 --
--===================================================================================--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")

local plr = Players.LocalPlayer
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

--===================================================================================--
--                              ТАБЛИЦА ФРУКТОВ (АКТУАЛЬНАЯ)                          --
--===================================================================================--

local FruitDatabase = {
    -- Common (7)
    {name = "Rocket",      rarity = "Common",      color = Color3.fromRGB(180,180,180), chance = 20},
    {name = "Spin",        rarity = "Common",      color = Color3.fromRGB(160,160,160), chance = 20},
    {name = "Blade",       rarity = "Common",      color = Color3.fromRGB(170,170,170), chance = 20},
    {name = "Spring",      rarity = "Common",      color = Color3.fromRGB(150,200,150), chance = 20},
    {name = "Bomb",        rarity = "Common",      color = Color3.fromRGB(140,140,140), chance = 20},
    {name = "Smoke",       rarity = "Common",      color = Color3.fromRGB(130,130,130), chance = 20},
    {name = "Spike",       rarity = "Common",      color = Color3.fromRGB(120,120,120), chance = 20},

    -- Uncommon (6)
    {name = "Flame",       rarity = "Uncommon",    color = Color3.fromRGB(255,100,30), chance = 15},
    {name = "Ice",         rarity = "Uncommon",    color = Color3.fromRGB(80,200,255), chance = 15},
    {name = "Sand",        rarity = "Uncommon",    color = Color3.fromRGB(210,180,100), chance = 15},
    {name = "Dark",        rarity = "Uncommon",    color = Color3.fromRGB(60,60,80), chance = 15},
    {name = "Eagle",       rarity = "Uncommon",    color = Color3.fromRGB(200,180,100), chance = 15},
    {name = "Diamond",     rarity = "Uncommon",    color = Color3.fromRGB(130,230,255), chance = 15},

    -- Rare (4)
    {name = "Light",       rarity = "Rare",        color = Color3.fromRGB(255,255,150), chance = 10},
    {name = "Rubber",      rarity = "Rare",        color = Color3.fromRGB(200,80,80), chance = 10},
    {name = "Ghost",       rarity = "Rare",        color = Color3.fromRGB(200,200,255), chance = 10},
    {name = "Magma",       rarity = "Rare",        color = Color3.fromRGB(255,80,20), chance = 10},

    -- Legendary (11)
    {name = "Quake",       rarity = "Legendary",   color = Color3.fromRGB(100,200,255), chance = 5},
    {name = "Buddha",      rarity = "Legendary",   color = Color3.fromRGB(255,215,0), chance = 5},
    {name = "Love",        rarity = "Legendary",   color = Color3.fromRGB(255,100,150), chance = 5},
    {name = "Creation",    rarity = "Legendary",   color = Color3.fromRGB(100,200,100), chance = 5},
    {name = "Spider",      rarity = "Legendary",   color = Color3.fromRGB(180,50,50), chance = 5},
    {name = "Sound",       rarity = "Legendary",   color = Color3.fromRGB(180,100,255), chance = 5},
    {name = "Phoenix",     rarity = "Legendary",   color = Color3.fromRGB(0,180,255), chance = 5},
    {name = "Portal",      rarity = "Legendary",   color = Color3.fromRGB(150,50,200), chance = 5},
    {name = "Lightning",   rarity = "Legendary",   color = Color3.fromRGB(255,255,0), chance = 5},
    {name = "Pain",        rarity = "Legendary",   color = Color3.fromRGB(200,0,200), chance = 5},
    {name = "Blizzard",    rarity = "Legendary",   color = Color3.fromRGB(150,220,255), chance = 5},

    -- Mythical (13)
    {name = "Gravity",     rarity = "Mythical",    color = Color3.fromRGB(150,50,200), chance = 2},
    {name = "Mammoth",     rarity = "Mythical",    color = Color3.fromRGB(139,90,43), chance = 2},
    {name = "T-Rex",       rarity = "Mythical",    color = Color3.fromRGB(80,150,50), chance = 2},
    {name = "Dough",       rarity = "Mythical",    color = Color3.fromRGB(255,180,220), chance = 2},
    {name = "Shadow",      rarity = "Mythical",    color = Color3.fromRGB(80,50,120), chance = 2},
    {name = "Venom",       rarity = "Mythical",    color = Color3.fromRGB(100,200,50), chance = 2},
    {name = "Gas",         rarity = "Mythical",    color = Color3.fromRGB(180,220,100), chance = 2},
    {name = "Tiger",       rarity = "Mythical",    color = Color3.fromRGB(255,150,0), chance = 2},
    {name = "Yeti",        rarity = "Mythical",    color = Color3.fromRGB(200,230,255), chance = 2},
    {name = "Kitsune",     rarity = "Mythical",    color = Color3.fromRGB(0,150,255), chance = 2},
    {name = "Control",     rarity = "Mythical",    color = Color3.fromRGB(0,100,200), chance = 2},
    {name = "Dragon",      rarity = "Mythical",    color = Color3.fromRGB(200,50,50), chance = 2},
    {name = "Leopard",     rarity = "Mythical",    color = Color3.fromRGB(255,200,50), chance = 2},
}

--===================================================================================--
--                              МНОЖИТЕЛЬ x8                                          --
--===================================================================================--

local X8_MULTIPLIER = 8

local function getX8Fruit()
    local legendary = {}
    local mythical = {}
    for _, f in ipairs(FruitDatabase) do
        if f.rarity == "Legendary" then
            table.insert(legendary, f)
        elseif f.rarity == "Mythical" then
            table.insert(mythical, f)
        end
    end

    local roll = math.random(1, 10)
    if roll <= 8 and #mythical > 0 then
        return mythical[math.random(1, #mythical)]
    elseif #legendary > 0 then
        return legendary[math.random(1, #legendary)]
    end

    return FruitDatabase[math.random(1, #FruitDatabase)]
end

local function getRandomFruit()
    local totalChance = 0
    for _, f in ipairs(FruitDatabase) do
        totalChance = totalChance + f.chance
    end

    local roll = math.random(1, totalChance)
    local cumulative = 0
    for _, f in ipairs(FruitDatabase) do
        cumulative = cumulative + f.chance
        if roll <= cumulative then
            return f
        end
    end

    return FruitDatabase[1]
end

--===================================================================================--
--                              ЗВУКИ                                                  --
--===================================================================================--

local function playSpinSound()
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://6042053626"
        s.Volume = 0.8
        s.Parent = SoundService
        s:Play()
        game:GetService("Debris"):AddItem(s, 2)
    end)
end

local function playWinSound(rarity)
    pcall(function()
        local id
        if rarity == "Mythical" then
            id = "rbxassetid://6042053886"
        elseif rarity == "Legendary" then
            id = "rbxassetid://6042053626"
        elseif rarity == "Rare" then
            id = "rbxassetid://6042053332"
        else
            id = "rbxassetid://6042053088"
        end
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume = 1
        s.Parent = SoundService
        s:Play()
        game:GetService("Debris"):AddItem(s, 3)
    end)
end

--===================================================================================--
--                              UI                                                     --
--===================================================================================--

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FruitGachaUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = plr:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 650)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -325)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Color = Color3.fromRGB(100, 50, 200)
mainStroke.Thickness = 3

local TitleLabel = Instance.new("TextLabel", MainFrame)
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, 0, 0, 50)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "FRUIT GACHA — x8 CHANCE"
TitleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
TitleLabel.TextScaled = true
TitleLabel.Font = Enum.Font.GothamBold

local SubtitleLabel = Instance.new("TextLabel", MainFrame)
SubtitleLabel.Name = "Subtitle"
SubtitleLabel.Size = UDim2.new(1, 0, 0, 25)
SubtitleLabel.Position = UDim2.new(0, 0, 0, 50)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Text = "x8 шанс на Legendary/Mythical!"
SubtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
SubtitleLabel.TextScaled = true
SubtitleLabel.Font = Enum.Font.Gotham

local ScrollFrame = Instance.new("Frame", MainFrame)
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(0.85, 0, 0, 200)
ScrollFrame.Position = UDim2.new(0.075, 0, 0, 85)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ClipsDescendants = true

Instance.new("UICorner", ScrollFrame).CornerRadius = UDim.new(0, 12)
local scrollStroke = Instance.new("UIStroke", ScrollFrame)
scrollStroke.Color = Color3.fromRGB(80, 40, 160)
scrollStroke.Thickness = 2

local Arrow = Instance.new("TextLabel", ScrollFrame)
Arrow.Name = "Arrow"
Arrow.Size = UDim2.new(0, 40, 0, 30)
Arrow.Position = UDim2.new(0.5, -20, 1, -30)
Arrow.BackgroundTransparency = 1
Arrow.Text = "▼"
Arrow.TextColor3 = Color3.fromRGB(255, 50, 50)
Arrow.TextScaled = true
Arrow.Font = Enum.Font.GothamBold
Arrow.ZIndex = 5

local CardsContainer = Instance.new("Frame", ScrollFrame)
CardsContainer.Name = "CardsContainer"
CardsContainer.Size = UDim2.new(3, 0, 1, 0)
CardsContainer.BackgroundTransparency = 1

local ResultFrame = Instance.new("Frame", MainFrame)
ResultFrame.Name = "ResultFrame"
ResultFrame.Size = UDim2.new(0.85, 0, 0, 80)
ResultFrame.Position = UDim2.new(0.075, 0, 0, 300)
ResultFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
ResultFrame.BorderSizePixel = 0
Instance.new("UICorner", ResultFrame).CornerRadius = UDim.new(0, 12)

local FruitNameLabel = Instance.new("TextLabel", ResultFrame)
FruitNameLabel.Name = "FruitName"
FruitNameLabel.Size = UDim2.new(1, 0, 0, 35)
FruitNameLabel.Position = UDim2.new(0, 0, 0, 5)
FruitNameLabel.BackgroundTransparency = 1
FruitNameLabel.Text = "Нажми кнопку!"
FruitNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FruitNameLabel.TextScaled = true
FruitNameLabel.Font = Enum.Font.GothamBold

local RarityLabel = Instance.new("TextLabel", ResultFrame)
RarityLabel.Name = "Rarity"
RarityLabel.Size = UDim2.new(1, 0, 0, 25)
RarityLabel.Position = UDim2.new(0, 0, 0, 42)
RarityLabel.BackgroundTransparency = 1
RarityLabel.Text = ""
RarityLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
RarityLabel.TextScaled = true
RarityLabel.Font = Enum.Font.Gotham

local ChanceLabel = Instance.new("TextLabel", ResultFrame)
ChanceLabel.Name = "Chance"
ChanceLabel.Size = UDim2.new(1, 0, 0, 20)
ChanceLabel.Position = UDim2.new(0, 0, 0, 60)
ChanceLabel.BackgroundTransparency = 1
ChanceLabel.Text = ""
ChanceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
ChanceLabel.TextScaled = true
ChanceLabel.Font = Enum.Font.GothamBold

local SpinButton = Instance.new("TextButton", MainFrame)
SpinButton.Name = "SpinButton"
SpinButton.Size = UDim2.new(0.85, 0, 0, 55)
SpinButton.Position = UDim2.new(0.075, 0, 0, 400)
SpinButton.BackgroundColor3 = Color3.fromRGB(100, 40, 200)
SpinButton.BorderSizePixel = 0
SpinButton.Text = "КРУТИТЬ (x8)"
SpinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SpinButton.TextScaled = true
SpinButton.Font = Enum.Font.GothamBold
Instance.new("UICorner", SpinButton).CornerRadius = UDim.new(0, 12)

local ClaimButton = Instance.new("TextButton", MainFrame)
ClaimButton.Name = "ClaimButton"
ClaimButton.Size = UDim2.new(0.85, 0, 0, 45)
ClaimButton.Position = UDim2.new(0.075, 0, 0, 470)
ClaimButton.BackgroundColor3 = Color3.fromRGB(30, 150, 50)
ClaimButton.BorderSizePixel = 0
ClaimButton.Text = "ЗАБРАТЬ В ИНВЕНТАРЬ"
ClaimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClaimButton.TextScaled = true
ClaimButton.Font = Enum.Font.GothamBold
ClaimButton.Visible = false
Instance.new("UICorner", ClaimButton).CornerRadius = UDim.new(0, 12)

local BuyButton = Instance.new("TextButton", MainFrame)
BuyButton.Name = "BuyButton"
BuyButton.Size = UDim2.new(0.85, 0, 0, 40)
BuyButton.Position = UDim2.new(0.075, 0, 0, 525)
BuyButton.BackgroundColor3 = Color3.fromRGB(200, 120, 30)
BuyButton.BorderSizePixel = 0
BuyButton.Text = "КУПИТЬ У БЕЛИ (NPC)"
BuyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BuyButton.TextScaled = true
BuyButton.Font = Enum.Font.GothamBold
Instance.new("UICorner", BuyButton).CornerRadius = UDim.new(0, 12)

local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 60, 0, 60)
ToggleButton.Position = UDim2.new(1, -70, 0.5, -30)
ToggleButton.BackgroundColor3 = Color3.fromRGB(100, 40, 200)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "GACHA"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextScaled = true
ToggleButton.Font = Enum.Font.GothamBold
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 30)
local toggleStroke = Instance.new("UIStroke", ToggleButton)
toggleStroke.Color = Color3.fromRGB(200, 150, 255)
toggleStroke.Thickness = 2

--===================================================================================--
--                              АНИМАЦИЯ ПРОКРУТКИ                                     --
--===================================================================================--

local isSpinning = false
local currentFruit = nil

local function createFruitCard(fruit, index)
    local card = Instance.new("Frame")
    card.Name = fruit.name
    card.Size = UDim2.new(0, 140, 0, 180)
    card.Position = UDim2.new(0, (index - 1) * 155, 0, 10)
    card.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    card.BorderSizePixel = 0
    card.Parent = CardsContainer

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    local cs = Instance.new("UIStroke", card)
    cs.Color = fruit.color
    cs.Thickness = 2

    local icon = Instance.new("Frame", card)
    icon.Size = UDim2.new(0, 70, 0, 70)
    icon.Position = UDim2.new(0.5, -35, 0, 15)
    icon.BackgroundColor3 = fruit.color
    icon.BorderSizePixel = 0
    Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)

    local nl = Instance.new("TextLabel", card)
    nl.Size = UDim2.new(1, 0, 0, 25)
    nl.Position = UDim2.new(0, 0, 0, 95)
    nl.BackgroundTransparency = 1
    nl.Text = fruit.name
    nl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nl.TextScaled = true
    nl.Font = Enum.Font.GothamBold

    local rl = Instance.new("TextLabel", card)
    rl.Size = UDim2.new(1, 0, 0, 20)
    rl.Position = UDim2.new(0, 0, 0, 122)
    rl.BackgroundTransparency = 1
    rl.Text = fruit.rarity
    rl.TextColor3 = fruit.color
    rl.TextScaled = true
    rl.Font = Enum.Font.Gotham

    local cl = Instance.new("TextLabel", card)
    cl.Size = UDim2.new(1, 0, 0, 18)
    cl.Position = UDim2.new(0, 0, 0, 145)
    cl.BackgroundTransparency = 1
    cl.Text = "x8: " .. tostring(fruit.chance * X8_MULTIPLIER) .. "%"
    cl.TextColor3 = Color3.fromRGB(255, 215, 0)
    cl.TextScaled = true
    cl.Font = Enum.Font.GothamBold

    return card
end

local function populateCards()
    for _, child in ipairs(CardsContainer:GetChildren()) do
        child:Destroy()
    end
    local totalFruits = #FruitDatabase
    for i = 1, totalFruits * 3 do
        local fruit = FruitDatabase[((i - 1) % totalFruits) + 1]
        createFruitCard(fruit, i)
    end
    CardsContainer.Position = UDim2.new(0, 0, 0, 0)
end

local function spinAnimation()
    if isSpinning then return end
    isSpinning = true

    playSpinSound()
    populateCards()

    local resultFruit
    if math.random(1, 10) <= 8 then
        resultFruit = getX8Fruit()
    else
        resultFruit = getRandomFruit()
    end

    local totalFruits = #FruitDatabase
    local targetIndex = math.random(1, totalFruits)
    local winPosition = (targetIndex - 1) * 155 + 75

    CardsContainer.Position = UDim2.new(0, 0, 0, 0)

    local totalSpins = 3
    local finalPos = -(totalFruits * totalSpins * 155) + winPosition

    local tweenInfo = TweenInfo.new(4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local tween = TweenService:Create(CardsContainer, tweenInfo, {Position = UDim2.new(0, finalPos, 0, 0)})

    local flashCount = 0
    local flashConn
    flashConn = game:GetService("RunService").Heartbeat:Connect(function()
        flashCount = flashCount + 1
        if flashCount % 8 == 0 then
            local ri = math.random(1, totalFruits)
            FruitNameLabel.Text = FruitDatabase[ri].name
            FruitNameLabel.TextColor3 = FruitDatabase[ri].color
        end
    end)

    tween:Play()
    tween.Completed:Wait()
    flashConn:Disconnect()

    currentFruit = resultFruit
    FruitNameLabel.Text = resultFruit.name
    FruitNameLabel.TextColor3 = resultFruit.color

    local rarityColors = {
        Common = Color3.fromRGB(150,150,150),
        Uncommon = Color3.fromRGB(80,200,100),
        Rare = Color3.fromRGB(50,150,255),
        Legendary = Color3.fromRGB(255,150,0),
        Mythical = Color3.fromRGB(200,50,255),
    }

    RarityLabel.Text = resultFruit.rarity
    RarityLabel.TextColor3 = rarityColors[resultFruit.rarity] or Color3.fromRGB(255,255,255)
    ChanceLabel.Text = "x8 шанс: " .. tostring(resultFruit.chance * X8_MULTIPLIER) .. "%"

    playWinSound(resultFruit.rarity)

    if resultFruit.rarity == "Mythical" then
        task.spawn(function()
            for _ = 1, 5 do
                mainStroke.Color = Color3.fromRGB(200, 50, 255)
                task.wait(0.2)
                mainStroke.Color = Color3.fromRGB(255, 215, 0)
                task.wait(0.2)
            end
            mainStroke.Color = Color3.fromRGB(100, 50, 200)
        end)
    end

    ClaimButton.Visible = true
    SpinButton.Text = "КРУТИТЬ СНОВА (x8)"
    isSpinning = false
end

--===================================================================================--
--                              ИНВЕНТАРЬ                                              --
--===================================================================================--

local function claimFruit(fruit)
    if not fruit then return false end

    local ok = pcall(function()
        CommF:InvokeServer("BuyUnverifiedCompassItem", fruit.name)
    end)

    if not ok then
        pcall(function()
            CommF:InvokeServer("AddToInventory", fruit.name)
        end)
    end

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "GACHA WIN!",
            Text = fruit.name .. " (" .. fruit.rarity .. ")",
            Duration = 5
        })
    end)

    return true
end

--===================================================================================--
--                              КНОПКИ                                                 --
--===================================================================================--

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

SpinButton.MouseButton1Click:Connect(function()
    spinAnimation()
end)

ClaimButton.MouseButton1Click:Connect(function()
    if currentFruit then
        claimFruit(currentFruit)
        ClaimButton.Text = "ЗАБРАНО!"
        ClaimButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        task.delay(2, function()
            ClaimButton.Text = "ЗАБРАТЬ В ИНВЕНТАРЬ"
            ClaimButton.BackgroundColor3 = Color3.fromRGB(30, 150, 50)
        end)
    end
end)

BuyButton.MouseButton1Click:Connect(function()
    pcall(function()
        CommF:InvokeServer("BuyUnverifiedCompassItem")
    end)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "GACHA",
            Text = "Покупка у Бели...",
            Duration = 3
        })
    end)
end)

--===================================================================================--
--                              СТАРТ                                                 --
--===================================================================================--

populateCards()

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Fruit Gacha",
        Text = "Нажми GACHA чтобы открыть!",
        Duration = 3
    })
end)

print("[GACHA] Загружен! x8 шанс на Legendary/Mythical.")
