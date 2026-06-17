--===================================================================================--
--                    LOADER — GACHA FRUIT VISUALIZER                                 --
--                    Запуск через Xeno Executor                                       --
--===================================================================================--

local url = "https://raw.githubusercontent.com/gopp9745-oss/my-script-blox-fruits-dmitri-kotakbas/master/Gacha.lua"
local content = nil

-- Метод 1: syn.request / http.request / request
pcall(function()
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local res = req({Url = url, Method = "GET"})
        if res and res.Body and #res.Body > 100 then
            content = res.Body
        end
    end
end)

-- Метод 2: game:HttpGet
if not content then
    pcall(function()
        local body = game:HttpGet(url, true)
        if body and #body > 100 then
            content = body
        end
    end)
end

-- Метод 3: game:HttpGet без синхронного режима
if not content then
    pcall(function()
        local body = game:HttpGet(url)
        if body and #body > 100 then
            content = body
        end
    end)
end

if content and #content > 100 then
    loadstring(content)()
    print("[GACHA LOADER] Успешно загружен!")
else
    warn("[GACHA LOADER] Ошибка загрузки! Попробуй вставить Gacha.lua вручную.")
end
