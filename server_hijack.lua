--===================================================================================--
--                       SERVER HIJACK v3 — LOCAL ISOLATION                          --
--                       СОВМЕСТИМОСТЬ: XENON / DELTA / MULTI-API                     --
--===================================================================================--

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

print("[SERVER HIJACK] Сервер: " .. JobId)

--===================================================================================--
--                         ГЕНЕРАЦИЯ КОДА ДЛЯ ДРУГА                                  --
--===================================================================================--

local function generateFriendCode()
    local code = string.format([[
        getgenv().IsInvitedFriend = true
        game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)
    ]], PlaceId, JobId)

    if setclipboard then
        setclipboard(code)
        print("[+] Код для друга скопирован в буфер обмена!")
    else
        warn("[-] setclipboard недоступен. Скопируй вручную:")
        print(code)
    end
end

--===================================================================================--
--                         ИЗОЛЯЦИЯ РАНДОМНЫХ ИГРОКОВ                                --
--===================================================================================--

local HostName = LocalPlayer.Name

local function isolatePlayer(player)
    if player == LocalPlayer then return end
    if player.Name == HostName then return end
    if getgenv().IsInvitedFriend and player ~= LocalPlayer then return end

    local function processCharacter(char)
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        local hum = char:WaitForChild("Humanoid", 10)

        if hrp then
            hrp.CFrame = CFrame.new(0, -99999, 0)
        end
        if hum then
            hum.PlatformStand = true
        end

        task.spawn(function()
            task.wait(0.2)
            pcall(function() char:Destroy() end)
        end)
    end

    if player.Character then
        task.spawn(processCharacter, player.Character)
    end
    player.CharacterAdded:Connect(processCharacter)

    print("[!] Изолирован: " .. player.Name)
end

--===================================================================================--
--                              ОСНОВНАЯ ЛОГИКА                                       --
--===================================================================================--

-- 1. Генерируем код для друга
generateFriendCode()

-- 2. Изолируем уже присутствующих рандомов
for _, player in ipairs(Players:GetPlayers()) do
    isolatePlayer(player)
end

-- 3. Отслеживаем новых входящих
Players.PlayerAdded:Connect(isolatePlayer)

-- 4. Уведомление
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Приватный Сервер";
        Text = "Сервер заблокирован. Код в буфере обмена.";
        Duration = 5
    })
end)

print("[+] Сервер заблокирован для посторонних")
print("[+] Код для друга в буфере обмена")
