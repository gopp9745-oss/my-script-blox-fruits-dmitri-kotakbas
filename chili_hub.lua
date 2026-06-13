--===================================================================================--
--                    CHILI PRIVATE HUB — BLOX FRUITS                                --
--                    ВНУТРИИГРОВОЙ ИНВАЙТ ПО КОДАМ (DELTA)                           --
--===================================================================================--

--===================================================================================--
--                              НАСТРОЙКА РЕЖИМА                                      --
--===================================================================================--

getgenv().HubMode = "Host"          -- "Host" (создает) | "Client" (подключается)
getgenv().ServerKey = ""            -- Вставь код здесь в режиме Client
getgenv().WhiteList = {"FriendName"} -- Никнеймы, кого НЕ скрывать

--===================================================================================--
--                              СЕРВИСЫ И ПЕРЕМЕННЫЕ                                 --
--===================================================================================--

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local CurrentJobId = game.JobId

--===================================================================================--
--                              HTTP ЗАПРОСЫ                                        --
--===================================================================================--

local function httpGet(url)
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local res = req({Url = url, Method = "GET"})
        return res and res.Body
    end
    return game:HttpGet(url, true)
end

--===================================================================================--
--                              БЛОК ХОСТА                                          --
--===================================================================================--

local function runHost()
    print("[ХОСТ] Поиск старого сервера (2-3 игрока) для обхода 524...")

    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
        PlaceId
    )

    local success, body = pcall(function() return httpGet(url) end)
    if not success or not body then
        warn("[-] HTTP запрос не удался")
        return
    end

    local data = HttpService:JSONDecode(body)
    if not data or not data.data then
        warn("[-] Нет данных от API")
        return
    end

    local target = nil
    for _, v in ipairs(data.data) do
        if (v.playing == 2 or v.playing == 3) and v.id ~= CurrentJobId then
            target = v
            break
        end
    end

    if not target then
        warn("[-] Подходящий сервер не найден (нужно 2-3 игрока).")
        return
    end

    local inviteCode = "CHILI-2026-" .. target.id
    if setclipboard then
        setclipboard(inviteCode)
        print("[ХОСТ] Код сервера скопирован! Скинь его другу: " .. inviteCode)
    else
        warn("[-] setclipboard недоступен. Код: " .. inviteCode)
    end

    print("[ХОСТ] Телепортирую на сервер: " .. target.id .. " (" .. target.playing .. " игроков)")
    TeleportService:TeleportToPlaceInstance(PlaceId, target.id, LocalPlayer)
end

--===================================================================================--
--                              БЛОК КЛИЕНТА                                        --
--===================================================================================--

local function runClient()
    local key = getgenv().ServerKey or ""
    if key == "" then
        warn("[-] ServerKey пуст! Вставь код в настройках.")
        return
    end

    local jobId = key:gsub("CHILI%-2026%-", "")
    if jobId == key then
        warn("[-] Неверный формат кода. Ожидается: CHILI-2026-<JobId>")
        return
    end

    print("[КЛИЕНТ] Подключение к серверу: " .. jobId)
    TeleportService:TeleportToPlaceInstance(PlaceId, jobId, LocalPlayer)
end

--===================================================================================--
--                              БЛОК ЗАЩИТЫ (ИЗОЛЯЦИЯ)                              --
--===================================================================================--

local function isWhitelisted(player)
    if player == LocalPlayer then return true end
    for _, name in ipairs(getgenv().WhiteList) do
        if player.Name == name then return true end
    end
    return false
end

local function isolatePlayer(player)
    if isWhitelisted(player) then return end

    local function processCharacter(char)
        char:WaitForChild("HumanoidRootPart", 10)
        char:WaitForChild("Humanoid", 10)

        -- Невидимость всех частей
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                obj.LocalTransparencyModifier = 1
                obj.Transparency = 1
            end
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
        end

        -- Скрыть ник и ХП
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end

        -- Удалить оружие/аксессуары локально
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") or tool:IsA("Accessory") then
                pcall(function() tool:Destroy() end)
            end
        end

        -- Ловить новые части
        char.ChildAdded:Connect(function(child)
            task.wait(0.1)
            if child:IsA("BasePart") or child:IsA("MeshPart") then
                child.LocalTransparencyModifier = 1
                child.Transparency = 1
            end
            if child:IsA("Tool") or child:IsA("Accessory") then
                pcall(function() child:Destroy() end)
            end
        end)
    end

    if player.Character then
        task.spawn(processCharacter, player.Character)
    end
    player.CharacterAdded:Connect(processCharacter)

    print("[ЗАЩИТА] Скрыт: " .. player.Name)
end

--===================================================================================--
--                              ЗАПУСК                                              --
--===================================================================================--

print("[CHILI HUB] Режим: " .. getgenv().HubMode .. " | PlaceId: " .. PlaceId)

-- Защита работает в обоих режимах
for _, p in ipairs(Players:GetPlayers()) do
    isolatePlayer(p)
end
Players.PlayerAdded:Connect(isolatePlayer)

if getgenv().HubMode == "Host" then
    runHost()
elseif getgenv().HubMode == "Client" then
    runClient()
else
    warn("[-] Неизвестный HubMode: " .. tostring(getgenv().HubMode))
end
