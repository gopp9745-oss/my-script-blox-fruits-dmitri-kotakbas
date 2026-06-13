--===================================================================================--
--                       SERVER HIJACK v4 — INVISIBLE MODE                           --
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
--                         СКРЫТИЕ ИГРОКА (INVISIBLE)                                --
--===================================================================================--

local HostName = LocalPlayer.Name

local function hidePlayer(player)
    if player == LocalPlayer then return end
    if player.Name == HostName then return end
    if getgenv().IsInvitedFriend and player ~= LocalPlayer then return end

    local function processCharacter(char)
        char:WaitForChild("HumanoidRootPart", 10)
        char:WaitForChild("Humanoid", 10)

        -- Все Part и MeshPart → невидимые
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                obj.LocalTransparencyModifier = 1
                obj.Transparency = 1
            end
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
            if obj:IsA("SpecialMesh") or obj:IsA("BlockMesh") or obj:IsA("CylinderMesh") then
                pcall(function() obj:Destroy() end)
            end
        end

        -- Скрываем имя и HP
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end

        -- Скрываем аксессуары
        for _, acc in ipairs(char:GetChildren()) do
            if acc:IsA("Accessory") or acc:IsA("Tool") then
                local handle = acc:FindFirstChild("Handle")
                if handle then
                    handle.LocalTransparencyModifier = 1
                    handle.Transparency = 1
                end
            end
        end

        -- Повторно при респавне
        char.ChildAdded:Connect(function(child)
            task.wait(0.1)
            if child:IsA("BasePart") or child:IsA("MeshPart") then
                child.LocalTransparencyModifier = 1
                child.Transparency = 1
            end
            if child:IsA("Accessory") or child:IsA("Tool") then
                local handle = child:FindFirstChild("Handle")
                if handle then
                    handle.LocalTransparencyModifier = 1
                    handle.Transparency = 1
                end
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
--                              ОСНОВНАЯ ЛОГИКА                                       --
--===================================================================================--

-- 1. Генерируем код для друга
generateFriendCode()

-- 2. Скрываем уже присутствующих рандомов
for _, player in ipairs(Players:GetPlayers()) do
    hidePlayer(player)
end

-- 3. Отслеживаем новых входящих
Players.PlayerAdded:Connect(hidePlayer)

-- 4. Уведомление
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Приватный Сервер";
        Text = "Посторонние скрыты. Код в буфере обмена.";
        Duration = 5
    })
end)

print("[+] Режим невидимости активен")
print("[+] Код для друга в буфере обмена")
