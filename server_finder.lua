--===================================================================================--
--                    SERVER FINDER v2 — ССЫЛКА НА ПУСТОЙ СЕРВЕР                       --
--                    СОВМЕСТИМОСТЬ: XENON / DELTA / MULTI-API                         --
--===================================================================================--

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local PlaceId = game.PlaceId

print("[SERVER FINDER] Поиск пустого сервера для PlaceId: " .. PlaceId)

-- HTTP запрос с авто-определением API
local function httpGet(url)
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local res = req({Url = url, Method = "GET"})
        return res and res.Body
    end
    return game:HttpGet(url, true)
end

-- Поиск минимального сервера (1-2 игрока, не заполнен)
local function findMinServer()
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
        PlaceId
    )

    local success, body = pcall(function() return httpGet(url) end)
    if not success or not body then
        warn("[-] HTTP запрос не удался")
        return nil
    end

    local data = HttpService:JSONDecode(body)
    if not data or not data.data then
        warn("[-] Нет данных от API")
        return nil
    end

    local best = nil
    local minPlayers = math.huge

    for _, server in ipairs(data.data) do
        local playing = server.playing or 0
        local maxPlayers = server.maxPlayers or 0
        local id = server.id

        if playing > 0 and playing <= 2 and playing < minPlayers and id ~= game.JobId and maxPlayers > playing then
            minPlayers = playing
            best = server
        end
    end

    return best
end

-- Основная логика
local server = findMinServer()

if server then
    local deepLink = string.format(
        "roblox://placeId=%d&gameInstanceId=%s",
        PlaceId,
        server.id
    )

    if setclipboard then
        setclipboard(deepLink)
    end

    print("[УСПЕХ] Ссылка на пустой сервер скопирована! Вставьте её в браузер или Discord.")
    print("[ИГРОКОВ] " .. server.playing .. "/" .. server.maxPlayers .. " | [JOB_ID] " .. server.id)
    print("[ССЫЛКА] " .. deepLink)
else
    warn("[-] Подходящий сервер не найден (1-2 игрока). Попробуйте позже.")
end
