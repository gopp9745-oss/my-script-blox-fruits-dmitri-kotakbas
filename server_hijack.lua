--[[ 
    Server Hijack Script
    Roblox (Xenon/Delta)
    Находит пустой сервер → телепортирует → копирует код для друга
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

print("[SERVER HIJACK] Скрипт загружен!")

local ACCESS_KEY = "FRIEND_KEY_2024"
local GAME_ID = game.PlaceId

-- Копирование в буфер обмена
local function toClipboard(text)
    if setclipboard then
        setclipboard(text)
        return true
    end
    return false
end

-- HTTP запрос (совместимость с Xenon/Delta)
local function httpGet(url)
    if http_request then
        local resp = http_request({Url = url, Method = "GET"})
        return resp and resp.Body
    end
    if request then
        local resp = request({Url = url, Method = "GET"})
        return resp and resp.Body
    end
    if syn and syn.request then
        local resp = syn.request({Url = url, Method = "GET"})
        return resp and resp.Body
    end
    local s, r = pcall(function()
        return game:HttpGet(url, true)
    end)
    if s and r then return r end
    return HttpService:GetAsync(url)
end

-- Запрос к API серверов
local function getServers(cursor)
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s",
        GAME_ID,
        cursor and ("&cursor=" .. cursor) or ""
    )
    
    local success, result = pcall(function()
        local body = httpGet(url)
        return HttpService:JSONDecode(body)
    end)
    
    if success and result then
        return result
    end
    return nil
end

-- Поиск самого пустого сервера
local function findEmptyServer()
    local bestServer = nil
    local lowestPlayers = math.huge
    local cursor = nil
    local pages = 0
    
    while pages < 10 do
        local data = getServers(cursor)
        if not data or not data.data then break end
        
        for _, server in ipairs(data.data) do
            if server.playing < lowestPlayers and server.id ~= game.JobId then
                lowestPlayers = server.playing
                bestServer = server
            end
        end
        
        cursor = data.nextPageCursor
        if not cursor then break end
        pages = pages + 1
        wait(0.5)
    end
    
    return bestServer
end

-- Список ID друзей (заполни своими)
local FRIEND_IDS = {}

-- Генерация кода для друга (копируется в буфер обмена)
local function generateFriendCode(jobId)
    local scriptUrl = "https://raw.githubusercontent.com/gopp9745-oss/my-script-blox-fruits-dmitri-kotakbas/master/server_hijack.lua"
    return string.format(
        'getgenv().IsInvitedFriend = true\nloadstring(game:HttpGet("%s"))()',
        scriptUrl
    )
end

-- Проверка: игрок — друг?
local function isFriend(player)
    for _, id in ipairs(FRIEND_IDS) do
        if player.UserId == id then return true end
    end
    return false
end

-- Изоляция рандомного игрока на клиенте
local function isolatePlayer(player)
    if player == LocalPlayer then return end
    if isFriend(player) then return end
    if getgenv().IsInvitedFriend then return end

    player.CharacterAdded:Connect(function(character)
        wait(0.2)
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(0, -99999, 0)
        end
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = true
        end
    end)

    if player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(0, -99999, 0)
        end
    end
end

-- Телепортация на сервер (несколько методов)
local function teleportToServer(jobId)
    -- Метод 1: TeleportToPlaceInstance
    local s1, e1 = pcall(function()
        TeleportService:TeleportToPlaceInstance(GAME_ID, jobId, LocalPlayer)
    end)
    if s1 then return true end

    -- Метод 2: Teleport с сервером
    local s2, e2 = pcall(function()
        TeleportService:Teleport(GAME_ID, LocalPlayer, nil, jobId)
    end)
    if s2 then return true end

    -- Метод 3: Через переменную
    local s3, e3 = pcall(function()
        TeleportService:SetTeleportData({JobId = jobId})
        TeleportService:Teleport(GAME_ID)
    end)
    if s3 then return true end

    warn("[!] Все методы телепорта failed: " .. tostring(e1))
    return false
end

-- Основная логика
local function main()
    print("[*] Поиск пустого сервера...")
    
    local server = findEmptyServer()
    if not server then
        warn("[!] Пустой сервер не найден")
        return
    end
    
    print("[*] Найден сервер с " .. server.playing .. " игроками: " .. server.id)
    
    -- Копируем код для друга
    local friendCode = generateFriendCode(server.id)
    if toClipboard(friendCode) then
        print("[+] Код скопирован в буфер обмена!")
    else
        warn("[!] setclipboard недоступен, код: " .. friendCode)
    end
    
    -- Телепортируемся
    print("[*] Телепортация...")
    local success, err = teleportToServer(server.id)
    
    if not success then
        warn("[!] Ошибка телепортации: " .. tostring(err))
        return
    end
    
    -- Ждём загрузки
    wait(5)
    
    -- Мониторим входящих игроков
    print("[*] Мониторинг игроков...")
    
    -- Изолируем уже присутствующих рандомов
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not isFriend(player) then
            isolatePlayer(player)
        end
    end

    -- Отслеживаем входящих
    Players.PlayerAdded:Connect(function(player)
        if player == LocalPlayer then return end

        if isFriend(player) then
            print("[+] Друг зашёл: " .. player.Name)
            return
        end

        print("[!] Рандом зашёл, изолирую: " .. player.Name)
        isolatePlayer(player)

        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Isolation";
                Text = player.Name .. " voided";
                Duration = 3
            })
        end)
    end)
    
    print("[+] Скрипт активен. Код в буфере обмена.")
end

-- Запуск
local ok, err = pcall(main)
if not ok then
    warn("[SERVER HIJACK] ОШИБКА: " .. tostring(err))
end
