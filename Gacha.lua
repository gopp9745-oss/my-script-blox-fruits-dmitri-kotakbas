--===================================================================================--
--                    GACHA FRUIT VISUALIZER — X8 CHANCE                              --
--                    Визуальная гача + фрукт в руках (только для тебя)               --
--===================================================================================--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local plr = Players.LocalPlayer
local plrGui = plr:WaitForChild("PlayerGui")
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

plr.CharacterAdded:Connect(function(c)
    char = c
    hrp = c:WaitForChild("HumanoidRootPart")
    hum = c:WaitForChild("Humanoid")
end)

--===================================================================================--
--                              ФРУКТОВАЯ БАЗА (АКТУАЛЬНАЯ)                            --
--===================================================================================--

local FruitDatabase = {
    -- Common
    {name="Rocket",     rarity="Common",   color=Color3.fromRGB(180,180,180), chance=20, mesh="rbxassetid://10173712894", scale=0.8},
    {name="Spin",       rarity="Common",   color=Color3.fromRGB(160,160,160), chance=20, mesh="rbxassetid://10173712894", scale=0.8},
    {name="Blade",      rarity="Common",   color=Color3.fromRGB(170,170,170), chance=20, mesh="rbxassetid://10173712894", scale=0.8},
    {name="Spring",     rarity="Common",   color=Color3.fromRGB(150,200,150), chance=20, mesh="rbxassetid://10173712894", scale=0.8},
    {name="Bomb",       rarity="Common",   color=Color3.fromRGB(140,140,140), chance=20, mesh="rbxassetid://10173712894", scale=0.8},
    {name="Smoke",      rarity="Common",   color=Color3.fromRGB(130,130,130), chance=20, mesh="rbxassetid://10173712894", scale=0.8},
    {name="Spike",      rarity="Common",   color=Color3.fromRGB(120,120,120), chance=20, mesh="rbxassetid://10173712894", scale=0.8},
    -- Uncommon
    {name="Flame",      rarity="Uncommon", color=Color3.fromRGB(255,100,30),  chance=15, mesh="rbxassetid://10173712894", scale=0.8},
    {name="Ice",        rarity="Uncommon", color=Color3.fromRGB(80,200,255),  chance=15, mesh="rbxassetid://10173712894", scale=0.8},
    {name="Sand",       rarity="Uncommon", color=Color3.fromRGB(210,180,100), chance=15, mesh="rbxassetid://10173712894", scale=0.8},
    {name="Dark",       rarity="Uncommon", color=Color3.fromRGB(60,60,80),    chance=15, mesh="rbxassetid://10173712894", scale=0.8},
    {name="Eagle",      rarity="Uncommon", color=Color3.fromRGB(200,180,100), chance=15, mesh="rbxassetid://10173712894", scale=0.8},
    {name="Diamond",    rarity="Uncommon", color=Color3.fromRGB(130,230,255), chance=15, mesh="rbxassetid://10173712894", scale=0.8},
    -- Rare
    {name="Light",      rarity="Rare",     color=Color3.fromRGB(255,255,150), chance=10, mesh="rbxassetid://10173712894", scale=0.8},
    {name="Rubber",     rarity="Rare",     color=Color3.fromRGB(200,80,80),   chance=10, mesh="rbxassetid://10173712894", scale=0.8},
    {name="Ghost",      rarity="Rare",     color=Color3.fromRGB(200,200,255), chance=10, mesh="rbxassetid://10173712894", scale=0.8},
    {name="Magma",      rarity="Rare",     color=Color3.fromRGB(255,80,20),   chance=10, mesh="rbxassetid://10173712894", scale=0.8},
    -- Legendary
    {name="Quake",      rarity="Legendary",color=Color3.fromRGB(100,200,255), chance=5,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Buddha",     rarity="Legendary",color=Color3.fromRGB(255,215,0),   chance=5,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Love",       rarity="Legendary",color=Color3.fromRGB(255,100,150), chance=5,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Creation",   rarity="Legendary",color=Color3.fromRGB(100,200,100), chance=5,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Spider",     rarity="Legendary",color=Color3.fromRGB(180,50,50),   chance=5,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Sound",      rarity="Legendary",color=Color3.fromRGB(180,100,255), chance=5,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Phoenix",    rarity="Legendary",color=Color3.fromRGB(0,180,255),   chance=5,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Portal",     rarity="Legendary",color=Color3.fromRGB(150,50,200),  chance=5,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Lightning",  rarity="Legendary",color=Color3.fromRGB(255,255,0),   chance=5,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Pain",       rarity="Legendary",color=Color3.fromRGB(200,0,200),   chance=5,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Blizzard",   rarity="Legendary",color=Color3.fromRGB(150,220,255), chance=5,  mesh="rbxassetid://10173712894", scale=0.8},
    -- Mythical
    {name="Gravity",    rarity="Mythical", color=Color3.fromRGB(150,50,200),  chance=2,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Mammoth",    rarity="Mythical", color=Color3.fromRGB(139,90,43),   chance=2,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="T-Rex",      rarity="Mythical", color=Color3.fromRGB(80,150,50),   chance=2,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Dough",      rarity="Mythical", color=Color3.fromRGB(255,180,220), chance=2,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Shadow",     rarity="Mythical", color=Color3.fromRGB(80,50,120),   chance=2,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Venom",      rarity="Mythical", color=Color3.fromRGB(100,200,50),  chance=2,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Gas",        rarity="Mythical", color=Color3.fromRGB(180,220,100), chance=2,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Tiger",      rarity="Mythical", color=Color3.fromRGB(255,150,0),   chance=2,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Yeti",       rarity="Mythical", color=Color3.fromRGB(200,230,255), chance=2,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Kitsune",    rarity="Mythical", color=Color3.fromRGB(0,150,255),   chance=2,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Control",    rarity="Mythical", color=Color3.fromRGB(0,100,200),   chance=2,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Dragon",     rarity="Mythical", color=Color3.fromRGB(200,50,50),   chance=2,  mesh="rbxassetid://10173712894", scale=0.8},
    {name="Leopard",    rarity="Mythical", color=Color3.fromRGB(255,200,50),  chance=2,  mesh="rbxassetid://10173712894", scale=0.8},
}

local RARITY_COLORS = {
    Common   = Color3.fromRGB(150,150,150),
    Uncommon = Color3.fromRGB(80,200,100),
    Rare     = Color3.fromRGB(50,150,255),
    Legendary= Color3.fromRGB(255,150,0),
    Mythical = Color3.fromRGB(200,50,255),
}

--===================================================================================--
--                              ВЫБОР ФРУКТА                                          --
--===================================================================================--

local function getX8Fruit()
    local leg, myt = {}, {}
    for _, f in ipairs(FruitDatabase) do
        if f.rarity == "Legendary" then table.insert(leg, f)
        elseif f.rarity == "Mythical" then table.insert(myt, f) end
    end
    if math.random(1,10) <= 8 and #myt > 0 then
        return myt[math.random(1,#myt)]
    end
    return leg[math.random(1,#leg)]
end

local function rollFruit()
    if math.random(1,10) <= 8 then return getX8Fruit() end
    local total = 0
    for _, f in ipairs(FruitDatabase) do total = total + f.chance end
    local r = math.random(1, total)
    local cum = 0
    for _, f in ipairs(FruitDatabase) do
        cum = cum + f.chance
        if r <= cum then return f end
    end
    return FruitDatabase[1]
end

--===================================================================================--
--                              ЗВУКИ                                                  --
--===================================================================================--

local function playSound(id, vol)
    task.spawn(function()
        pcall(function()
            local s = Instance.new("Sound")
            s.SoundId = id
            s.Volume = vol or 0.7
            s.Parent = SoundService
            s:Play()
            Debris:AddItem(s, 4)
        end)
    end)
end

--===================================================================================--
--                              СОЗДАНИЕ ФРУКТА В РУКАХ                               --
--===================================================================================--

local currentFruitTool = nil

local function createFruitInHand(fruit)
    if currentFruitTool then
        pcall(function() currentFruitTool:Destroy() end)
    end

    local tool = Instance.new("Tool")
    tool.Name = fruit.name .. " Fruit"
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    tool.Parent = nil

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 1)
    handle.Massless = true
    handle.CanCollide = false
    handle.Transparency = 0
    handle.BrickColor = BrickColor.new("Really black")
    handle.Material = Enum.Material.SmoothPlastic
    handle.Parent = tool

    -- Спираль фрукта (как настоящий)
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Scale = Vector3.new(0.7, 0.7, 0.7)
    mesh.TextureId = ""
    mesh.Parent = handle

    -- Внутренний свечение
    local glow = Instance.new("Part")
    glow.Name = "Glow"
    glow.Size = Vector3.new(1.3, 1.3, 1.3)
    glow.Massless = true
    glow.CanCollide = false
    glow.Transparency = 0.6
    glow.Shape = Enum.PartType.Ball
    glow.Material = Enum.Material.Neon
    glow.BrickColor = BrickColor.new("Really black")
    glow.Color = fruit.color
    glow.Parent = tool
    glow.CFrame = handle.CFrame

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = glow
    weld.Parent = handle

    handle.Color = fruit.color
    handle.Material = Enum.Material.SmoothPlastic

    -- Поверхность с旋涡 (спираль)
    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Front
    surface.Parent = handle

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = fruit.color
    frame.BackgroundTransparency = 0.3
    frame.Parent = surface

    -- Название фрукта над головой (только для тебя)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "FruitLabel"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 30
    billboard.Parent = handle

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = fruit.name
    nameLabel.TextColor3 = fruit.color
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Parent = billboard

    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, 0, 0.5, 0)
    rarityLabel.Position = UDim2.new(0, 0, 0.5, 0)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = fruit.rarity .. " x8"
    rarityLabel.TextColor3 = RARITY_COLORS[fruit.rarity]
    rarityLabel.TextScaled = true
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.TextStrokeTransparency = 0.5
    rarityLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    rarityLabel.Parent = billboard

    -- Свечение для Mythical
    if fruit.rarity == "Mythical" then
        local pointLight = Instance.new("PointLight")
        pointLight.Color = fruit.color
        pointLight.Brightness = 3
        pointLight.Range = 12
        pointLight.Parent = handle
    end

    -- Только для локального игрока!
    tool.Parent = plr.Backpack

    -- Скрываем от других: когда эквипирован — показываем только нам
    currentFruitTool = tool

    tool.Equipped:Connect(function()
        -- Показываем только локальному игроку
        for _, part in ipairs(tool:GetDescendants()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = 0
            end
        end
    end)

    tool.Unequipped:Connect(function()
        for _, part in ipairs(tool:GetDescendants()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = 0
            end
        end
    end)

    return tool
end

-- Скрытие от других игроков
local function hideFromOthers(tool)
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= plr then
            -- Для других игроков этот Tool не виден
            pcall(function()
                local pg = other:FindFirstChild("PlayerGui")
                if pg then
                    -- Скрываем через CoreGui
                end
            end)
        end
    end

    -- Подключаем отслеживание для новых игроков
    tool.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            -- По умолчанию скрыто от других
            game:GetService("RunService").Heartbeat:Connect(function()
                if desc and desc.Parent then
                    desc.LocalTransparencyModifier = 0
                end
            end)
        end
    end)
end

--===================================================================================--
--                              АНИМАЦИЯ КАПСУЛЫ                                      --
--===================================================================================--

local isSpinning = false

local function spawnGachaMachine(callback)
    if isSpinning then return end
    isSpinning = true

    local fruit = rollFruit()

    -- Позиция перед игроком
    local spawnPos = hrp.CFrame * CFrame.new(0, 0, -6)

    -- Капсула гача-автомата
    local capsule = Instance.new("Model")
    capsule.Name = "GachaCapsule"
    capsule.Parent = workspace

    -- Основание автомата
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(4, 2, 4)
    base.Position = spawnPos.Position
    base.Anchored = true
    base.CanCollide = false
    base.Color = Color3.fromRGB(40, 40, 60)
    base.Material = Enum.Material.Metal
    base.Parent = capsule

    -- Колба (стеклянный шар)
    local bulb = Instance.new("Part")
    bulb.Name = "Bulb"
    bulb.Size = Vector3.new(3.5, 3.5, 3.5)
    bulb.Shape = Enum.PartType.Ball
    bulb.Position = spawnPos.Position + Vector3.new(0, 3, 0)
    bulb.Anchored = true
    bulb.CanCollide = false
    bulb.Transparency = 0.3
    bulb.Color = Color3.fromRGB(100, 150, 255)
    bulb.Material = Enum.Material.Glass
    bulb.Parent = capsule

    -- Верхняя крышка
    local lid = Instance.new("Part")
    lid.Name = "Lid"
    lid.Size = Vector3.new(2, 0.5, 2)
    lid.Position = spawnPos.Position + Vector3.new(0, 5, 0)
    lid.Anchored = true
    lid.CanCollide = false
    lid.Color = Color3.fromRGB(200, 50, 50)
    lid.Material = Enum.Material.SmoothPlastic
    lid.Parent = capsule

    -- Надпись "GACHA x8"
    local sign = Instance.new("Part")
    sign.Name = "Sign"
    sign.Size = Vector3.new(3, 1, 0.1)
    sign.Position = spawnPos.Position + Vector3.new(0, 6.5, 2)
    sign.Anchored = true
    sign.CanCollide = false
    sign.Color = Color3.fromRGB(255, 215, 0)
    sign.Material = Enum.Material.Neon
    sign.Parent = capsule

    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = sign

    local signText = Instance.new("TextLabel")
    signText.Size = UDim2.new(1, 0, 1, 0)
    signText.BackgroundTransparency = 1
    signText.Text = "x8 GACHA"
    signText.TextColor3 = Color3.fromRGB(20, 20, 30)
    signText.TextScaled = true
    signText.Font = Enum.Font.GothamBold
    signText.Parent = signGui

    -- Частицы внутри колбы
    local sparkle = Instance.new("ParticleEmitter")
    sparkle.Color = ColorSequence.new(fruit.color)
    sparkle.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0),
    })
    sparkle.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    sparkle.Lifetime = NumberRange.new(0.5, 1.5)
    sparkle.Rate = 50
    sparkle.Speed = NumberRange.new(2, 5)
    sparkle.SpreadAngle = Vector2.new(360, 360)
    sparkle.Parent = bulb

    -- Звук включения
    playSound("rbxassetid://6042053088", 0.5)

    -- Анимация появления (капсула поднимается)
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    base.CFrame = CFrame.new(spawnPos.Position - Vector3.new(0, 10, 0))
    lid.CFrame = CFrame.new(spawnPos.Position + Vector3.new(0, -5, 0))

    TweenService:Create(base, tweenInfo, {CFrame = CFrame.new(spawnPos.Position)}):Play()
    TweenService:Create(bulb, tweenInfo, {CFrame = CFrame.new(spawnPos.Position + Vector3.new(0, 3, 0))}):Play()
    TweenService:Create(lid, tweenInfo, {CFrame = CFrame.new(spawnPos.Position + Vector3.new(0, 5, 0))}):Play()

    task.wait(1.5)

    -- Свечение усиливается
    playSound("rbxassetid://6042053332", 0.6)

    local glowTween = TweenService:Create(bulb, TweenInfo.new(1), {
        Color = fruit.color,
        Transparency = 0.1
    })
    glowTween:Play()

    -- Мерцание перед открытием
    for i = 1, 6 do
        bulb.Color = (i % 2 == 0) and fruit.color or Color3.fromRGB(255, 255, 255)
        task.wait(0.15)
    end

    -- Взрыв частиц!
    sparkle.Rate = 200
    sparkle.Speed = NumberRange.new(5, 15)
    sparkle.Lifetime = NumberRange.new(0.3, 0.8)

    playSound("rbxassetid://6042053886", 1)

    -- Капсула "ломается"
    TweenService:Create(base, TweenInfo.new(0.3), {Transparency = 1}):Play()
    TweenService:Create(lid, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        CFrame = lid.CFrame * CFrame.new(0, 5, 0)
    }):Play()
    TweenService:Create(bulb, TweenInfo.new(0.5), {Transparency = 1, Size = Vector3.new(6, 6, 6)}):Play()

    task.wait(0.5)

    -- Фрукт вылетает из капсулы
    local fruitPart = Instance.new("Part")
    fruitPart.Name = "FruitDrop"
    fruitPart.Size = Vector3.new(1.2, 1.2, 1.2)
    fruitPart.Shape = Enum.PartType.Ball
    fruitPart.Position = spawnPos.Position + Vector3.new(0, 4, 0)
    fruitPart.Anchored = true
    fruitPart.CanCollide = false
    fruitPart.Color = fruit.color
    fruitPart.Material = Enum.Material.Neon
    fruitPart.Parent = capsule

    -- Надпись фрукта на капсуле
    local fruitLabel = Instance.new("BillboardGui")
    fruitLabel.Size = UDim2.new(0, 300, 0, 80)
    fruitLabel.StudsOffset = Vector3.new(0, 3, 0)
    fruitLabel.AlwaysOnTop = true
    fruitLabel.Parent = fruitPart

    local fName = Instance.new("TextLabel")
    fName.Size = UDim2.new(1, 0, 0.5, 0)
    fName.BackgroundTransparency = 1
    fName.Text = fruit.name
    fName.TextColor3 = fruit.color
    fName.TextScaled = true
    fName.Font = Enum.Font.GothamBold
    fName.TextStrokeTransparency = 0
    fName.TextStrokeColor3 = Color3.new(0, 0, 0)
    fName.Parent = fruitLabel

    local fRarity = Instance.new("TextLabel")
    fRarity.Size = UDim2.new(1, 0, 0.5, 0)
    fRarity.Position = UDim2.new(0, 0, 0.5, 0)
    fRarity.BackgroundTransparency = 1
    fRarity.Text = fruit.rarity .. " x8!"
    fRarity.TextColor3 = RARITY_COLORS[fruit.rarity]
    fRarity.TextScaled = true
    fRarity.Font = Enum.Font.GothamBold
    fRarity.TextStrokeTransparency = 0
    fRarity.TextStrokeColor3 = Color3.new(0, 0, 0)
    fRarity.Parent = fruitLabel

    -- Фрукт подпрыгивает и светится
    if fruit.rarity == "Mythical" then
        local light = Instance.new("PointLight")
        light.Color = fruit.color
        light.Brightness = 5
        light.Range = 20
        light.Parent = fruitPart
    end

    -- Анимация пружины
    for i = 1, 3 do
        TweenService:Create(fruitPart, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
            CFrame = fruitPart.CFrame * CFrame.new(0, 2, 0)
        }):Play()
        task.wait(0.3)
        TweenService:Create(fruitPart, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            CFrame = fruitPart.CFrame * CFrame.new(0, -1.5, 0)
        }):Play()
        task.wait(0.25)
    end

    -- Фрукт "приземляется" перед игроком
    local finalPos = hrp.CFrame * CFrame.new(0, 1, -3)
    TweenService:Create(fruitPart, TweenInfo.new(0.8, Enum.EasingStyle.Bounce), {
        CFrame = finalPos
    }):Play()

    task.wait(1)

    -- Показываем результат
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "GACHA x8!",
            Text = "Выпал: " .. fruit.name .. " (" .. fruit.rarity .. ")!",
            Duration = 5
        })
    end)

    -- Создаём фрукт в руках
    local tool = createFruitInHand(fruit)
    hideFromOthers(tool)

    -- Удаляем капсулу
    task.delay(2, function()
        if capsule and capsule.Parent then
            capsule:Destroy()
        end
    end)

    isSpinning = false
    if callback then callback(fruit) end
end

--===================================================================================--
--                              UI: ГЛАВНОЕ ОКНО                                       --
--===================================================================================--

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GachaUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = plrGui

-- Кнопка-шарик для открытия
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 70, 0, 70)
ToggleBtn.Position = UDim2.new(1, -80, 0.5, -35)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 200)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "GACHA\nx8"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextScaled = true
ToggleBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
local tStroke = Instance.new("UIStroke", ToggleBtn)
tStroke.Color = Color3.fromRGB(200, 150, 255)
tStroke.Thickness = 2

-- Панель информации (маленькая)
local InfoPanel = Instance.new("Frame", ScreenGui)
InfoPanel.Name = "InfoPanel"
InfoPanel.Size = UDim2.new(0, 280, 0, 220)
InfoPanel.Position = UDim2.new(0.5, -140, 0.5, -110)
InfoPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
InfoPanel.BorderSizePixel = 0
InfoPanel.Visible = false
Instance.new("UICorner", InfoPanel).CornerRadius = UDim.new(0, 16)
local iStroke = Instance.new("UIStroke", InfoPanel)
iStroke.Color = Color3.fromRGB(100, 50, 200)
iStroke.Thickness = 2

-- Заголовок
local lbl = Instance.new("TextLabel", InfoPanel)
lbl.Size = UDim2.new(1, 0, 0, 35)
lbl.BackgroundTransparency = 1
lbl.Text = "FRUIT GACHA"
lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
lbl.TextScaled = true
lbl.Font = Enum.Font.GothamBold

local sub = Instance.new("TextLabel", InfoPanel)
sub.Size = UDim2.new(1, -20, 0, 20)
sub.Position = UDim2.new(0, 10, 0, 38)
sub.BackgroundTransparency = 1
sub.Text = "x8 шанс на Legendary/Mythical!"
sub.TextColor3 = Color3.fromRGB(200, 200, 255)
sub.TextScaled = true
sub.Font = Enum.Font.Gotham

-- Результат
local resFrame = Instance.new("Frame", InfoPanel)
resFrame.Size = UDim2.new(1, -20, 0, 50)
resFrame.Position = UDim2.new(0, 10, 0, 65)
resFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
resFrame.BorderSizePixel = 0
Instance.new("UICorner", resFrame).CornerRadius = UDim.new(0, 8)

local resName = Instance.new("TextLabel", resFrame)
resName.Size = UDim2.new(1, 0, 0.5, 0)
resName.BackgroundTransparency = 1
resName.Text = "Ждём..."
resName.TextColor3 = Color3.fromRGB(255, 255, 255)
resName.TextScaled = true
resName.Font = Enum.Font.GothamBold

local resRarity = Instance.new("TextLabel", resFrame)
resRarity.Size = UDim2.new(1, 0, 0.5, 0)
resRarity.Position = UDim2.new(0, 0, 0.5, 0)
resRarity.BackgroundTransparency = 1
resRarity.Text = ""
resRarity.TextScaled = true
resRarity.Font = Enum.Font.Gotham

-- Кнопка крутить
local spinBtn = Instance.new("TextButton", InfoPanel)
spinBtn.Size = UDim2.new(1, -20, 0, 45)
spinBtn.Position = UDim2.new(0, 10, 0, 125)
spinBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 200)
spinBtn.BorderSizePixel = 0
spinBtn.Text = "КРУТИТЬ (x8)"
spinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spinBtn.TextScaled = true
spinBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", spinBtn).CornerRadius = UDim.new(0, 10)

-- Кнопка экипировать
local equipBtn = Instance.new("TextButton", InfoPanel)
equipBtn.Size = UDim2.new(1, -20, 0, 35)
equipBtn.Position = UDim2.new(0, 10, 0, 178)
equipBtn.BackgroundColor3 = Color3.fromRGB(30, 150, 50)
equipBtn.BorderSizePixel = 0
equipBtn.Text = "ЭКИПИРОВАТЬ"
equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
equipBtn.TextScaled = true
equipBtn.Font = Enum.Font.GothamBold
equipBtn.Visible = false
Instance.new("UICorner", equipBtn).CornerRadius = UDim.new(0, 10)

--===================================================================================--
--                              ПРИВЯЗКА КНОПОК                                       --
--===================================================================================--

local lastFruit = nil

ToggleBtn.MouseButton1Click:Connect(function()
    InfoPanel.Visible = not InfoPanel.Visible
end)

spinBtn.MouseButton1Click:Connect(function()
    spinBtn.Text = "КРУТИМ..."
    spinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

    spawnGachaMachine(function(fruit)
        lastFruit = fruit
        resName.Text = fruit.name
        resName.TextColor3 = fruit.color
        resRarity.Text = fruit.rarity .. " x8!"
        resRarity.TextColor3 = RARITY_COLORS[fruit.rarity]
        spinBtn.Text = "КРУТИТЬ СНОВА (x8)"
        spinBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 200)
        equipBtn.Visible = true
    end)
end)

equipBtn.MouseButton1Click:Connect(function()
    if currentFruitTool then
        hum:EquipTool(currentFruitTool)
    end
end)

--===================================================================================--
--                              СТАРТ                                                 --
--===================================================================================--

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Fruit Gacha x8",
        Text = "Нажми GACHA чтобы открыть гача-автомат!",
        Duration = 4
    })
end)

print("[GACHA] Загружен! Капсула + фрукт в руках (только для тебя).")
