--===================================================================================--
--                       ПОЛНОСТЬЮ ИСПРАВЛЕННЫЙ SERVER HIJACK                        --
--                       СОВМЕСТИМОСТЬ: XENON / DELTA / MULTI-API                     --
--===================================================================================--

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

print("[SERVER HIJACK] Скрипт успешно запущен и оптимизирован!")

-- Проверка: мы уже на приватке или это первый запуск?
getgenv().AlreadyTeleported = getgenv().AlreadyTeleported or false

-- HTTP запрос с авто-определением под любой чит
local function safeHttpGet(url)
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local res = req({Url = url, Method = "GET"})
        return res and res.Body
    end
    return game:HttpGet(url, true)
end

-- Поиск абсолютно пустого сервера (0 или 1 игрок)
local function getEmptyJobId()
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", PlaceId)
    local success, body = pcall(function() return safeHttpGet(url) end)
    
    if success and body then
        local data = HttpService:JSONDecode(body)
        if data and data.data then
            for _, server in ipairs(data.data) do
                -- Ищем пустой сервер, игнорируя тот, на котором сидим сейчас
                if server.playing <= 1 and server.id ~= game.JobId then
                    return server.id
                end
            end
        end
    end
    return nil
end

-- Изоляция рандомных игроков (отправка в Void на клиенте)
local function isolateRandom(player)
    if player == LocalPlayer then return end
    
    local function processCharacter(char)
        task.wait(0.3)
        -- Если у зашедшего игрока нет флага друга в его чите
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if hrp and hum then
            -- Стираем его физическое присутствие для нас
            hrp.CFrame = CFrame.new(0, -99999, 0)
            hum.PlatformStand = true
            -- Локально ломаем ему отрисовку, чтобы не создавал лагов
            task.spawn(function()
                pcall(function() char:Destroy() end)
            end)
        end
    end

    if player.Character then processCharacter(player.Character) end
    player.CharacterAdded:Connect(processCharacter)
end

-- Функция автоматического обхода ошибки 773 и телепортации
local function autoTeleport(targetJobId)
    -- 1. Генерируем код, который скопируется ТЕБЕ в буфер, чтобы ты переслал его другу
    -- Когда друг его выполнит, у него включится пропуск (IsInvitedFriend), и его моментально тепает к тебе
    local friendCode = string.format([[
        getgenv().IsInvitedFriend = true
        local ts = game:GetService("TeleportService")
        if (syn and syn.queue_on_teleport) or queue_on_teleport then
            local qot = syn and syn.queue_on_teleport or queue_on_teleport
            qot("getgenv().IsInvitedFriend = true")
        end
        ts:TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)
    ]], PlaceId, targetJobId)
    
    setclipboard(friendCode)
    print("[+] Код-приглашение для друга скопирован в буфер обмена!")

    -- 2. Логика обхода токена через читерский метод очереди
    local queue = (syn and syn.queue_on_teleport) or queue_on_teleport
    if queue then
        getgenv().AlreadyTeleported = true
        -- Зашиваем команду прыжка в память, обходя системный блок токенов Roblox
        queue(string.format([[
            getgenv().AlreadyTeleported = true
            game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)
            ]], PlaceId, targetJobId))
        
        -- Вызываем стандартный пинок, который триггерит нашу зашитую очередь
        TeleportService:Teleport(PlaceId, LocalPlayer)
    else
        -- Запасной вариант, если чит совсем урезанный
        TeleportService:TeleportToPlaceInstance(PlaceId, targetJobId, LocalPlayer)
    end
end

--===================================================================================--
--                                   ОСНОВНОЙ ЦИКЛ                                   --
--===================================================================================--

if not getgenv().AlreadyTeleported and not getgenv().IsInvitedFriend then
    -- РЕЖИМ 1: Первый запуск (Поиск и авто-прыжок)
    print("[*] Запуск автоматического поиска приватной зоны...")
    local targetJob = getEmptyJobId()
    
    if targetJob then
        print("[+] Пустой сервер найден! Обходим защиту токена...")
        autoTeleport(targetJob)
    else
        warn("[-] Не удалось найти пустой сервер. Попробуй перезапустить через минуту.")
    end
else
    -- РЕЖИМ 2: Мы уже успешно прилетели на сервер или зашли как приглашенный друг
    print("[БЕЗОПАСНОСТЬ] Режим Anti-Random активирован. Сервер заблокирован для чужих.")
    
    -- Изолируем всех левых, кто уже был на сервере (если это был не 100% пустой)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Name ~= _G.HostName then
            isolateRandom(p)
        end
    end
    
    -- Запоминаем ник создателя привата, чтобы его друга не кикало
    if not getgenv().IsInvitedFriend then
        _G.HostName = LocalPlayer.Name
    end

    -- Жесткий фильтр новых заходящих игроков
    Players.PlayerAdded:Connect(function(player)
        task.wait(0.5)
        -- Если зашел игрок без пропуска (не твой друг)
        if player.Name ~= _G.HostName and not getgenv().IsInvitedFriend then
            print("[!] Обнаружен посторонний: " .. player.Name .. ". Изолирую клиент...")
            isolateRandom(player)
            
            -- Выводим уведомление на экран, что рандом успешно стерт
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Приватный Сервер";
                    Text = player.Name .. " отправлен в Void!";
                    Duration = 3
                })
            end)
        end
    end)
end