--===================================================================================--
--                    GACHA FRUIT VISUALIZER — X8 CHANCE                              --
--                    Визуальная гача с шансом x8 на легендарный фрукт                 --
--===================================================================================--

--===================================================================================--
--                              СЕРВИСЫ                                               --
--===================================================================================--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")

local plr = Players.LocalPlayer
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

--===================================================================================--
--                              ТАБЛИЦА ФРУКТОВ                                       --
--===================================================================================--

local FruitDatabase = {
    -- Обычные (Common) — базовый шанс
    {name = "Spin",        rarity = "Common",      color = Color3.fromRGB(150,150,150), chance = 25},
    {name = "Bomb",        rarity = "Common",      color = Color3.fromRGB(150,150,150), chance = 25},
    {name = "Smoke",       rarity = "Common",      color = Color3.fromRGB(150,150,150), chance = 25},
    {name = "Flame",       rarity = "Common",      color = Color3.fromRGB(150,150,150), chance = 25},
    {name = "Falcon",      rarity = "Common",      color = Color3.fromRGB(150,150,150), chance = 25},

    -- Необычные (Uncommon)
    {name = "Ice",         rarity = "Uncommon",    color = Color3.fromRGB(80,200,255), chance = 15},
    {name = "Sand",        rarity = "Uncommon",    color = Color3.fromRGB(210,180,100), chance = 15},
    {name = "Dark",        rarity = "Uncommon",    color = Color3.fromRGB(60,60,60), chance = 15},
    {name = "Diamond",     rarity = "Uncommon",    color = Color3.fromRGB(130,230,255), chance = 15},
    {name = "Light",       rarity = "Uncommon",    color = Color3.fromRGB(255,255,150), chance = 15},

    -- Редкие (Rare)
    {name = "Magma",       rarity = "Rare",        color = Color3.fromRGB(255,100,30), chance = 8},
    {name = "Quake",       rarity = "Rare",        color = Color3.fromRGB(100,200,255), chance = 8},
    {name = "Buddha",      rarity = "Rare",        color = Color3.fromRGB(255,215,0), chance = 8},
    {name = "Love",        rarity = "Rare",        color = Color3.fromRGB(255,100,150), chance = 8},
    {name = "Spider",      rarity = "Rare",        color = Color3.fromRGB(180,50,50), chance = 8},

    -- Легендарные (Legendary) — x8 шанс!
    {name = "Control",     rarity = "Legendary",   color = Color3.fromRGB(0,100,200), chance = 4},
    {name = "Blizzard",    rarity = "Legendary",   color = Color3.fromRGB(150,220,255), chance = 4},
    {name = "Pain",        rarity = "Legendary",   color = Color3.fromRGB(200,0,200), chance = 4},
    {name = "Ghost",       rarity = "Legendary",   color = Color3.fromRGB(200,200,255), chance = 4},
    {name = "Mammoth",     rarity = "Legendary",   color = Color3.fromRGB(139,90,43), chance = 4},
    {name = "Barrier",     rarity = "Legendary",   color = Color3.fromRGB(255,180,0), chance = 4},

    -- Мифические (Mythical) — x8 шанс на КРУТОЙ фрукт!
    {name = "Dough",       rarity = "Mythical",    color = Color3.fromRGB(255,180,220), chance = 2},
    {name = "Dragon",      rarity = "Mythical",    color = Color3.fromRGB(200,50,50), chance = 2},
    {name = "Spirit",      rarity = "Mythical",    color = Color3.fromRGB(180,100,255), chance = 2},
    {name = "Venom",       rarity = "Mythical",    color = Color3.fromRGB(100,200,50), chance = 2},
    {name = "Leopard",     rarity = "Mythical",    color = Color3.fromRGB(255,200,50), chance = 2},
    {name = "Kitsune",     rarity = "Mythical",    color = Color3.fromRGB(0,150,255), chance = 2},
}

--===================================================================================--
--                              МНОЖИТЕЛЬ x8                                          --
--===================================================================================--

local X8_MULTIPLIER = 8

local function getX8Fruit()
    -- Собираем только Legendary и Mythical
    local legendary = {}
    local mythical = {}
    for _, f in ipairs(FruitDatabase) do
        if f.rarity == "Legendary" then
            table.insert(legendary, f)
        elseif f.rarity == "Mythical" then
            table.insert(mythical, f)
        end
    end

    -- x8 шанс: 8/10 на Mythical, 2/10 на Legendary
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
        s.PlayOnRemove = false
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
--                              UI: СОЗДАНИЕ                                           --
--===================================================================================--

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FruitGachaUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = plr:WaitForChild("PlayerGui")

-- Основной фрейм
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

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 50, 200)
mainStroke.Thickness = 3
mainStroke.Parent = MainFrame

-- Заголовок
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, 0, 0, 50)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "FRUIT GACHA — x8 CHANCE"
TitleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
TitleLabel.TextScaled = true
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = MainFrame

-- Подзаголовок с шансом
local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Name = "Subtitle"
SubtitleLabel.Size = UDim2.new(1, 0, 0, 25)
SubtitleLabel.Position = UDim2.new(0, 0, 0, 50)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Text = "x8 шанс на Legendary/Mythical!"
SubtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
SubtitleLabel.TextScaled = true
SubtitleLabel.Font = Enum.Font.Gotham
SubtitleLabel.Parent = MainFrame

-- Зона прокрутки (барабан)
local ScrollFrame = Instance.new("Frame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(0.85, 0, 0, 200)
ScrollFrame.Position = UDim2.new(0.075, 0, 0, 85)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ClipsDescendants = true
ScrollFrame.Parent = MainFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 12)
scrollCorner.Parent = ScrollFrame

local scrollStroke = Instance.new("UIStroke")
scrollStroke.Color = Color3.fromRGB(80, 40, 160)
scrollStroke.Thickness = 2
scrollStroke.Parent = ScrollFrame

-- Стрелка-указатель
local Arrow = Instance.new("TextLabel")
Arrow.Name = "Arrow"
Arrow.Size = UDim2.new(0, 40, 0, 30)
Arrow.Position = UDim2.new(0.5, -20, 1, -30)
Arrow.BackgroundTransparency = 1
Arrow.Text = "▼"
Arrow.TextColor3 = Color3.fromRGB(255, 50, 50)
Arrow.TextScaled = true
Arrow.Font = Enum.Font.GothamBold
Arrow.ZIndex = 5
Arrow.Parent = ScrollFrame

-- Контейнер для карточек фруктов
local CardsContainer = Instance.new("Frame")
CardsContainer.Name = "CardsContainer"
CardsContainer.Size = UDim2.new(3, 0, 1, 0)
CardsContainer.Position = UDim2.new(0, 0, 0, 0)
CardsContainer.BackgroundTransparency = 1
CardsContainer.Parent = ScrollFrame

-- Текущий результат
local ResultFrame = Instance.new("Frame")
ResultFrame.Name = "ResultFrame"
ResultFrame.Size = UDim2.new(0.85, 0, 0, 80)
ResultFrame.Position = UDim2.new(0.075, 0, 0, 300)
ResultFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
ResultFrame.BorderSizePixel = 0
ResultFrame.Parent = MainFrame

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 12)
resultCorner.Parent = ResultFrame

local FruitNameLabel = Instance.new("TextLabel")
FruitNameLabel.Name = "FruitName"
FruitNameLabel.Size = UDim2.new(1, 0, 0, 35)
FruitNameLabel.Position = UDim2.new(0, 0, 0, 5)
FruitNameLabel.BackgroundTransparency = 1
FruitNameLabel.Text = "Нажми кнопку!"
FruitNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FruitNameLabel.TextScaled = true
FruitNameLabel.Font = Enum.Font.GothamBold
FruitNameLabel.Parent = ResultFrame

local RarityLabel = Instance.new("TextLabel")
RarityLabel.Name = "Rarity"
RarityLabel.Size = UDim2.new(1, 0, 0, 25)
RarityLabel.Position = UDim2.new(0, 0, 0, 42)
RarityLabel.BackgroundTransparency = 1
RarityLabel.Text = ""
RarityLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
RarityLabel.TextScaled = true
RarityLabel.Font = Enum.Font.Gotham
RarityLabel.Parent = ResultFrame

local ChanceLabel = Instance.new("TextLabel")
ChanceLabel.Name = "Chance"
ChanceLabel.Size = UDim2.new(1, 0, 0, 20)
ChanceLabel.Position = UDim2.new(0, 0, 0, 60)
ChanceLabel.BackgroundTransparency = 1
ChanceLabel.Text = ""
ChanceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
ChanceLabel.TextScaled = true
ChanceLabel.Font = Enum.Font.GothamBold
ChanceLabel.Parent = ResultFrame

-- Кнопка "Крутить"
local SpinButton = Instance.new("TextButton")
SpinButton.Name = "SpinButton"
SpinButton.Size = UDim2.new(0.85, 0, 0, 55)
SpinButton.Position = UDim2.new(0.075, 0, 0, 400)
SpinButton.BackgroundColor3 = Color3.fromRGB(100, 40, 200)
SpinButton.BorderSizePixel = 0
SpinButton.Text = "КРУТИТЬ (x8)"
SpinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SpinButton.TextScaled = true
SpinButton.Font = Enum.Font.GothamBold
SpinButton.Parent = MainFrame

local spinCorner = Instance.new("UICorner")
spinCorner.CornerRadius = UDim.new(0, 12)
spinCorner.Parent = SpinButton

-- Кнопка "Забрать в инвентарь"
local ClaimButton = Instance.new("TextButton")
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
ClaimButton.Parent = MainFrame

local claimCorner = Instance.new("UICorner")
claimCorner.CornerRadius = UDim.new(0, 12)
claimCorner.Parent = ClaimButton

-- Кнопка "Купить у Бели (Ближайший NPC)"
local BuyButton = Instance.new("TextButton")
BuyButton.Name = "BuyButton"
BuyButton.Size = UDim2.new(0.85, 0, 0, 40)
BuyButton.Position = UDim2.new(0.075, 0, 0, 525)
BuyButton.BackgroundColor3 = Color3.fromRGB(200, 120, 30)
BuyButton.BorderSizePixel = 0
BuyButton.Text = "КУПИТЬ У БЕЛИ (NPC)"
BuyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BuyButton.TextScaled = true
BuyButton.Font = Enum.Font.GothamBold
BuyButton.Parent = MainFrame

local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 12)
buyCorner.Parent = BuyButton

-- Кнопка открытия/закрытия (мини-кнопка)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 60, 0, 60)
ToggleButton.Position = UDim2.new(1, -70, 0.5, -30)
ToggleButton.BackgroundColor3 = Color3.fromRGB(100, 40, 200)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "GACHA"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextScaled = true
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Parent = ScreenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 30)
toggleCorner.Parent = ToggleButton

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(200, 150, 255)
toggleStroke.Thickness = 2
toggleStroke.Parent = ToggleButton

--===================================================================================--
--                              UI: АНИМАЦИЯ ПРОКРУТКИ                                 --
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

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = fruit.color
    cardStroke.Thickness = 2
    cardStroke.Parent = card

    -- Иконка фрукта (круг с цветом)
    local icon = Instance.new("Frame")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 70, 0, 70)
    icon.Position = UDim2.new(0.5, -35, 0, 15)
    icon.BackgroundColor3 = fruit.color
    icon.BorderSizePixel = 0
    icon.Parent = card

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = icon

    -- Название фрукта
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, 0, 0, 25)
    nameLabel.Position = UDim2.new(0, 0, 0, 95)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = fruit.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = card

    -- Редкость
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Name = "Rarity"
    rarityLabel.Size = UDim2.new(1, 0, 0, 20)
    rarityLabel.Position = UDim2.new(0, 0, 0, 122)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = fruit.rarity
    rarityLabel.TextColor3 = fruit.color
    rarityLabel.TextScaled = true
    rarityLabel.Font = Enum.Font.Gotham
    rarityLabel.Parent = card

    -- Шанс
    local chanceLabel = Instance.new("TextLabel")
    chanceLabel.Name = "Chance"
    chanceLabel.Size = UDim2.new(1, 0, 0, 18)
    chanceLabel.Position = UDim2.new(0, 0, 0, 145)
    chanceLabel.BackgroundTransparency = 1
    chanceLabel.Text = "x8: " .. tostring(fruit.chance * X8_MULTIPLIER) .. "%"
    chanceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    chanceLabel.TextScaled = true
    chanceLabel.Font = Enum.Font.GothamBold
    chanceLabel.Parent = card

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

local function spinAnimation(callback)
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
    local targetFruit = FruitDatabase[targetIndex]

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
            local randIdx = math.random(1, totalFruits)
            local rf = FruitDatabase[randIdx]
            FruitNameLabel.Text = rf.name
            FruitNameLabel.TextColor3 = rf.color
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

    -- Эффект свечения для Mythical
    if resultFruit.rarity == "Mythical" then
        task.spawn(function()
            for i = 1, 5 do
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

    if callback then callback(resultFruit) end

    isSpinning = false
end

--===================================================================================--
--                              ИНВЕНТАРЬ: ДОБАВЛЕНИЕ                                  --
--===================================================================================--

local function claimFruit(fruit)
    if not fruit then
        warn("[GACHA] Нет фрукта для добавления!")
        return false
    end

    local success, err = pcall(function()
        CommF:InvokeServer("BuyUnverifiedCompassItem", fruit.name)
    end)

    if success then
        StarterGui:SetCore("SendNotification", {
            Title = "GACHA WIN!",
            Text = "Получен: " .. fruit.name .. " (" .. fruit.rarity .. ")!",
            Duration = 5
        })
        return true
    else
        -- Попытка через альтернативный метод
        local success2, err2 = pcall(function()
            CommF:InvokeServer("AddToInventory", fruit.name)
        end)

        if success2 then
            StarterGui:SetCore("SendNotification", {
                Title = "GACHA WIN!",
                Text = "Получен: " .. fruit.name .. " (" .. fruit.rarity .. ")!",
                Duration = 5
            })
            return true
        else
            warn("[GACHA] Ошибка добавления: " .. tostring(err) .. " | " .. tostring(err2))
            StarterGui:SetCore("SendNotification", {
                Title = "GACHA",
                Text = "Фрукт: " .. fruit.name .. " — добавь вручную!",
                Duration = 5
            })
            return false
        end
    end
end

--===================================================================================--
--                              КНОПКИ: ПРИВЯЗКА                                      --
--===================================================================================--

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

SpinButton.MouseButton1Click:Connect(function()
    spinAnimation()
end)

ClaimButton.MouseButton1Click:Connect(function()
    if currentFruit then
        local ok = claimFruit(currentFruit)
        if ok then
            ClaimButton.Text = "ЗАБРАНО!"
            ClaimButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            task.delay(2, function()
                ClaimButton.Text = "ЗАБРАТЬ В ИНВЕНТАРЬ"
                ClaimButton.BackgroundColor3 = Color3.fromRGB(30, 150, 50)
            end)
        end
    end
end)

BuyButton.MouseButton1Click:Connect(function()
    StarterGui:SetCore("SendNotification", {
        Title = "GACHA",
        Text = "Ищем Бели (Blox Fruit Gacha NPC)...",
        Duration = 3
    })

    local success, err = pcall(function()
        CommF:InvokeServer("BuyUnverifiedCompassItem")
    end)

    if success then
        StarterGui:SetCore("SendNotification", {
            Title = "GACHA",
            Text = "Фрукт куплен у Бели!",
            Duration = 3
        })
    else
        StarterGui:SetCore("SendNotification", {
            Title = "GACHA",
            Text = "Используй GACHA кнопку для визуальной прокрутки!",
            Duration = 3
        })
    end
end)

--===================================================================================--
--                              ИНИЦИАЛИЗАЦИЯ                                         --
--===================================================================================--

populateCards()

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Fruit Gacha",
    Text = "Gacha загружена! Нажми GACHA чтобы открыть!",
    Duration = 3
})

print("[GACHA] Скрипт загружен успешно!")
print("[GACHA] x8 шанс на Legendary/Mythical фрукты!")
print("[GACHA] Нажми кнопку GACHA чтобы открыть окно.")
