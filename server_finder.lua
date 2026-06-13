--===================================================================================--
--                    SERVER FINDER — ВАЛИДАЦИЯ ЖИВЫХ СЕРВЕРОВ                        --
--                    СОВМЕСТИМОСТЬ: XENON / DELTA / MULTI-API                         --
--===================================================================================--

local HttpService = game:GetService("HttpService")
local PlaceId = game.PlaceId

print("[SERVER FINDER] Поиск живого публичного сервера для PlaceId: " .. PlaceId)

-- HTTP запрос с авто-определением API
local function httpGet(url)
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local res = req({Url = url, Method = "GET"})
        return res and res.Body
    end
    return game:HttpGet(url, true)
end

-- Поиск с валидацией
local function findValidServer()
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

    for _, v in ipairs(data.data) do
        local playing = v.playing
        local ping = v.ping
        local jobId = v.id

        -- ЖЕСТКИЕ ФИЛЬТРЫ
        if playing == 0 then
            print("[ФИЛЬТР] Пропущен приватный/служебный (0 игроков): " .. jobId)
        elseif not ping or ping == 0 then
            print("[ФИЛЬТР] Пропущен недоступный (нет пинга): " .. jobId)
        elseif playing >= 1 and playing <= 3 and ping > 0 then
            print("[ВАЛИД] Живой сервер: " .. playing .. " игр., пинг " .. ping .. " | " .. jobId)
            if playing < minPlayers then
                minPlayers = playing
                best = v
            end
        end
    end

    return best
end

-- Основная логика
local server = findValidServer()

if server then
    local deepLink = string.format(
        "roblox://placeId=%d&gameInstanceId=%s",
        PlaceId,
        server.id
    )

    if setclipboard then
        setclipboard(deepLink)
    end

    print("[УСПЕХ] Найдена живая публичная локация с " .. server.playing .. " игр.")
    print("[PING] " .. server.ping .. "ms | [JOB_ID] " .. server.id)
    print("[ССЫЛКА] " .. deepLink)
else
    warn("[-] Живой публичный сервер не найден. Все инстансы 0 игроков или недоступны.")
end
