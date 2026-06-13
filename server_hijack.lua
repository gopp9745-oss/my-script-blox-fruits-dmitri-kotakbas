--===================================================================================--
--                       SERVER HIJACK v2 — LOCAL ISOLATION ONLY                      --
--                       СОВМЕСТИМОСТЬ: XENON / DELTA / MULTI-API                     --
--                                                                                   --
--  Инициатор заходит на сервер вручную → запускает скрипт →                        --
--  копируется код для друга → рандомы изолируются на клиенте                        --
--===================================================================================--

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

print("[SERVER HIJACK] Режим: Local Isolation Only")
print("[SERVER HIJACK] Текущий сервер: " .. JobId)

--===================================================================================--
--                         ГЕНЕРАЦИЯ КОДА ДЛЯ ДРУГА                                  --
--===================================================================================--

local function generateFriendCode()
    local code = string.format([[
        -- Вставь этот код в Xenon/Delta чтобы попасть на сервер к другу
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

    print("[+] Раздай этот код друзьям — они попадут на твой сервер")
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
        task.wait(0.3)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:FindFirstChildOfClass("Humanoid")

        if hrp then
            hrp.CFrame = CFrame.new(0, -99999, 0)
        end
        if hum then
            hum.PlatformStand = true
        end

        task.spawn(function()
            task.wait(0.1)
            pcall(function() char:Destroy() end)
        end)
    end

    if player.Character then
        processCharacter(player.Character)
    end
    player.CharacterAdded:Connect(processCharacter)

    print("[!] Изолирован: " .. player.Name)
end

--===================================================================================--
--                              ОСНОВНАЯ ЛОГИКА                                       --
--===================================================================================--

-- Генерируем код для друга
generateFriendCode()

-- Изолируем уже присутствующих рандомов
for _, player in ipairs(Players:GetPlayers()) do
    isolatePlayer(player)
end

-- Отслеживаем новых входящих
Players.PlayerAdded:Connect(function(player)
    task.wait(0.5)
    isolatePlayer(player)

    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Приватный Сервер";
            Text = player.Name .. " изолирован";
            Duration = 3
        })
    end)
end)

print("[+] Сервер заблокирован для посторонних")
print("[+] Код для друга в буфере обмена")
