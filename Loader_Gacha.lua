--===================================================================================--
--                    LOADER — GACHA FRUIT VISUALIZER                                 --
--===================================================================================--

local url = "https://raw.githubusercontent.com/gopp9745-oss/my-script-blox-fruits-dmitri-kotakbas/master/Gacha.lua"
local content = nil

-- Метод 1: game:HttpGet (самый надёжный в Xeno)
pcall(function()
    content = game:HttpGet(url, true)
end)

-- Метод 2: game:HttpGet без sync
if not content or #content < 100 then
    pcall(function()
        content = game:HttpGet(url)
    end)
end

-- Метод 3: syn.request / http.request
if not content or #content < 100 then
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if req then
            local res = req({Url = url, Method = "GET"})
            if res and res.Body then
                content = res.Body
            end
        end
    end)
end

if content and #content > 100 then
    loadstring(content)()
    print("[GACHA LOADER] OK")
else
    warn("[GACHA LOADER] GetHttp не сработал. Вставь Gacha.lua вручную в консоль Xeno.")
end
