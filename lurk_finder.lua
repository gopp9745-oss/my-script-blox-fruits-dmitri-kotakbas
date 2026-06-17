--===================================================================================--
--                    LURK SERVER FINDER — BLOX FRUITS                               --
--                    ПОИСК СЕРВЕРОВ + INVITE ПО КОДАМ                               --
--===================================================================================--

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

--===================================================================================--
--                              НАСТРОЙКИ                                            --
--===================================================================================--

getgenv().WhiteList = {LocalPlayer.Name} -- Кого НЕ скрывать

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
--                              ПОИСК СЕРВЕРА                                       --
--===================================================================================--

local function findServer()
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
        if v.playing >= 1 and v.playing <= 3 and v.ping > 0 and v.id ~= game.JobId then
            if v.playing < minPlayers then
                minPlayers = v.playing
                best = v
            end
        end
    end

    return best
end

--===================================================================================--
--                              ГЕНЕРАЦИЯ КОДА                                      --
--===================================================================================--

local function generateInvite(jobId)
    local code = "LURK-" .. jobId
    if setclipboard then
        setclipboard(code)
        print("[+] Код скопирован: " .. code)
    else
        print("[-] setclipboard недоступен. Код: " .. code)
    end
    return code
end

--===================================================================================--
--                              ТЕЛЕПОРТ                                             --
--===================================================================================--

local function teleportTo(jobId)
    print("[*] Телепортация на " .. jobId .. "...")
    TeleportService:TeleportToPlaceInstance(PlaceId, jobId, LocalPlayer)
end

--===================================================================================--
--                              ИЗОЛЯЦИЯ РАНДОМОВ                                   --
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

        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                obj.LocalTransparencyModifier = 1
                obj.Transparency = 1
            end
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
        end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end

        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") or tool:IsA("Accessory") then
                pcall(function() tool:Destroy() end)
            end
        end

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
    print("[!] Скрыт: " .. player.Name)
end

--===================================================================================--
--                              ОСНОВНОЙ ЦИКЛ                                       --
--===================================================================================--

print("[LURK] Поиск сервера для PlaceId: " .. PlaceId)

for _, p in ipairs(Players:GetPlayers()) do
    isolatePlayer(p)
end
Players.PlayerAdded:Connect(isolatePlayer)

local server = findServer()

if server then
    local code = generateInvite(server.id)
    print("[УСПЕХ] Сервер: " .. server.playing .. " игр. | Пинг: " .. server.ping .. "ms | JobId: " .. server.id)
    print("[КОД] " .. code)
    teleportTo(server.id)
else
    warn("[-] Сервер не найден. Попробуй позже.")
end
