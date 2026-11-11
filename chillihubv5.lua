-- ============================================================
--  CHILLI HUB V5 × OPENWONX — FIXED BUILD
--  Anti-Lag ON by default | Silent Injector | Finder Free Ilimitado
--  KEY PATCH: intacto — siempre válida
-- ============================================================

-- ── GUARD: evitar doble ejecución ───────────────────────────
if getgenv().ChilliV5_Loaded then
    warn("[ChilliV5] Ya cargado, abortando instancia duplicada.")
    return
end
getgenv().ChilliV5_Loaded = true

-- ── SERVICIOS (declarados UNA SOLA VEZ) ─────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local ContentProvider  = game:GetService("ContentProvider")
local CoreGui          = game:GetService("CoreGui")
local Lighting         = game:GetService("Lighting")
local SoundService     = game:GetService("SoundService")

local LP = Players.LocalPlayer
local LocalPlayer = LP

-- ============================================================
--  ANTI-LAG ACTIVO POR DEFECTO (corre hasta en Motorola)
-- ============================================================
local function ApplyAntiLag()
    -- Reducir calidad de renderizado
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function() settings().Rendering.AutoFPSMode = false end)

    -- LOD agresivo
    pcall(function()
        workspace.StreamingEnabled = false
    end)

    -- Deshabilitar sombras dinámicas
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.FogStart = 99999
    end)

    -- Eliminar efectos de post-proceso
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("Sky") then
            pcall(function() effect.Enabled = false end)
        end
    end

    -- Deshabilitar sonidos de ambiente (reducen CPU)
    for _, sound in ipairs(workspace:GetDescendants()) do
        if sound:IsA("Sound") and sound.Playing then
            pcall(function() sound:Stop() end)
        end
    end

    -- Limpiar partículas y efectos visuales pesados
    local heavyClasses = {
        "ParticleEmitter", "Trail", "SelectionBox",
        "SelectionSphere", "Beam", "BillboardGui"
    }
    task.spawn(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            for _, cls in ipairs(heavyClasses) do
                if obj:IsA(cls) then
                    pcall(function()
                        if obj:IsA("BillboardGui") then
                            obj.Enabled = false
                        elseif obj:FindFirstAncestorOfClass("Character") == nil then
                            -- No tocar partículas del propio personaje
                            obj.Enabled = false
                        end
                    end)
                end
            end
        end
    end)

    -- FPS cap a 60 si el executor lo soporta
    pcall(function()
        setfpscap(60)
    end)

    -- Reducir MaxGraphicsQuality via RenderSettings
    pcall(function()
        UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    end)

    print("[ChilliV5] Anti-Lag activado ✓")
end

ApplyAntiLag()

-- ============================================================
--  CAPTURA DE ORIG HTTPGET ANTES DE CUALQUIER HOOK
--  (esto previene la recursión infinita del script original)
-- ============================================================
local _ORIG_HTTPGET   = game.HttpGet          -- captura pura ANTES de hooks
local _ORIG_GETASYNC  = HttpService.GetAsync  -- captura pura
local _ORIG_POSTASYNC = HttpService.PostAsync -- captura pura

-- ============================================================
--  OPENWONX ANTIBAN — Módulo anti-detección (una sola vez)
-- ============================================================
local AB = {}

local SAFE_WALKSPEED = 16
local SAFE_JUMPPOWER = 50
local REAL_WALKSPEED = 16
local REAL_JUMPPOWER = 50

local function getHum()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- Teleport Humanizer
local lastTeleport = 0
local MIN_TELEPORT_GAP = 8

local origTeleport = TeleportService.TeleportToPlaceInstance
TeleportService.TeleportToPlaceInstance = function(self, placeId, jobId, player, ...)
    local now = os.time()
    local gap = now - lastTeleport
    if gap < MIN_TELEPORT_GAP then
        task.wait((MIN_TELEPORT_GAP - gap) + math.random(1, 3))
    end
    lastTeleport = os.time()
    task.wait(math.random(5, 15) / 10)
    return origTeleport(self, placeId, jobId, player, ...)
end

-- Anti-AFK
local lastActivity = os.time()
local AFK_CHECK_INTERVAL = 60

task.spawn(function()
    while getgenv().ChilliV5_Loaded do
        task.wait(AFK_CHECK_INTERVAL + math.random(-10, 10))
        local timeSince = os.time() - lastActivity
        if timeSince > 55 then
            local char = LP.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.WalkSpeed > 0 then
                    local origCF = hrp.CFrame
                    local microAngle = math.random(-3, 3) * (math.pi / 180)
                    hrp.CFrame = origCF * CFrame.Angles(0, microAngle, 0)
                end
            end
            lastActivity = os.time()
        end
    end
end)

UserInputService.InputBegan:Connect(function()
    lastActivity = os.time()
end)

-- Remote Protector
function AB.FireRemote(remote, ...)
    task.wait(math.random(1, 5) / 10)
    pcall(function() remote:FireServer(...) end)
end

-- Kick Evasion
pcall(function()
    LP.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.InProgress then
            if getgenv then
                getgenv().OW_LastServer = {
                    placeId = game.PlaceId,
                    jobId   = game.JobId,
                    time    = os.time(),
                }
            end
        end
    end)
end)

-- Speed seguro
function AB.SetSpeedSafe(speed)
    local hum = getHum()
    if not hum then return end
    REAL_WALKSPEED = speed
    local current = hum.WalkSpeed
    local step = (speed - current) / 10
    task.spawn(function()
        for i = 1, 10 do
            hum = getHum()
            if not hum then break end
            hum.WalkSpeed = current + (step * i)
            task.wait(0.05)
        end
    end)
end

function AB.ResetSpeed()
    local hum = getHum()
    if hum then
        REAL_WALKSPEED = SAFE_WALKSPEED
        hum.WalkSpeed = SAFE_WALKSPEED
    end
end

-- Noclip seguro
local noclipActive = false
local noclipConn   = nil

function AB.NoclipOn()
    if noclipActive then return end
    noclipActive = true
    noclipConn = RunService.Stepped:Connect(function()
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP and player.Character then
                    local otherHrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if otherHrp and (hrp.Position - otherHrp.Position).Magnitude < 20 then
                        return
                    end
                end
            end
        end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

function AB.NoclipOff()
    noclipActive = false
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    local char = LP.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

-- SafeZone Teleporter
local SAFEZONE_CANDIDATES = {"SafeZone","Safe Zone","SafeArea","Safe","Home","HomeZone","Spawn","SpawnArea"}

function AB.TeleportToSafeZone()
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    for _, name in ipairs(SAFEZONE_CANDIDATES) do
        local obj = workspace:FindFirstChild(name, true)
        if obj then
            local targetPos
            if obj:IsA("BasePart") then
                targetPos = obj.Position + Vector3.new(0, 3, 0)
            elseif obj:IsA("Model") and obj.PrimaryPart then
                targetPos = obj.PrimaryPart.Position + Vector3.new(0, 3, 0)
            end
            if targetPos then
                hrp.CFrame = CFrame.new(targetPos)
                return true
            end
        end
    end
    return false
end

-- Anti-Guard
local guardKeywords = {"guard","cop","police","npc","enemy","mob","defender"}

function AB.IsGuardNearby(radius)
    radius = radius or 15
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local nameLow = obj.Name:lower()
            for _, kw in ipairs(guardKeywords) do
                if nameLow:find(kw) then
                    local guardHrp = obj:FindFirstChild("HumanoidRootPart")
                    if guardHrp then
                        local dist = (hrp.Position - guardHrp.Position).Magnitude
                        if dist < radius then return true, obj, dist end
                    end
                end
            end
        end
    end
    return false
end

task.spawn(function()
    while getgenv().ChilliV5_Loaded do
        task.wait(0.5)
        if getgenv().OW_AutoEvadeGuards then
            local isNear = AB.IsGuardNearby(12)
            if isNear then
                AB.TeleportToSafeZone()
                task.wait(2)
            end
        end
    end
end)

getgenv().OW_AutoEvadeGuards = true
getgenv().OW_AntiBan = AB
getgenv().OW_AntiBanLoaded = true

-- ============================================================
--  OPENWONX SILENT HOOK — Interceptor de Chilli (FIJO)
--  USA _ORIG_HTTPGET — sin recursión infinita
-- ============================================================
local OW_BACKEND_CF = "https://calm-violet-3941.openwonx.workers.dev"

local CHILLI_TARGETS = {"chillihub.pro","finder","finding","feed","drops"}

local function isChilliURL(url)
    local lurl = (url or ""):lower()
    for _, pat in ipairs(CHILLI_TARGETS) do
        if lurl:find(pat, 1, true) then return true end
    end
    return false
end

local function tryExtractFindings(responseBody)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(responseBody)
    end)
    if not ok or type(data) ~= "table" then return end
    local items = {}
    if data.findings then items = data.findings
    elseif data.data   then items = data.data
    elseif data[1]     then items = data
    elseif data.job_id then items = {data}
    end
    for _, item in ipairs(items) do
        if type(item) == "table" and item.job_id then
            local payload = HttpService:JSONEncode({
                egg_name         = item.egg_name or item.name or "Chilli Finding",
                location         = item.location or item.area or "",
                mutation         = item.mutation or item.variant or "",
                rarity           = item.rarity or "Unknown",
                value_per_second = tonumber(item.value_per_second or item.mps or item.value or 0),
                multiplier       = tonumber(item.multiplier or item.multi or 1),
                place_id         = tostring(item.place_id or game.PlaceId),
                job_id           = item.job_id,
                source           = "chilli_hook",
                detected_at      = item.detected_at or os.date("!%Y-%m-%dT%H:%M:%SZ"),
            })
            task.spawn(function()
                pcall(function()
                    _ORIG_POSTASYNC(HttpService, OW_BACKEND_CF.."/api/finding", payload, Enum.HttpContentType.ApplicationJson)
                end)
            end)
        end
    end
end

-- Hook HttpGet — usa _ORIG_HTTPGET para no crear recursión
game.HttpGet = function(self, url, ...)
    -- Jitter AntiBan
    task.wait(math.random(5, 20) / 100)
    local result = _ORIG_HTTPGET(self, url, ...)
    if isChilliURL(url) then
        task.spawn(function() pcall(tryExtractFindings, result) end)
    end
    return result
end

-- Hook GetAsync
HttpService.GetAsync = function(self, url, ...)
    local result = _ORIG_GETASYNC(self, url, ...)
    if isChilliURL(url) then
        task.spawn(function() pcall(tryExtractFindings, result) end)
    end
    return result
end

-- Hook PostAsync
HttpService.PostAsync = function(self, url, body, ...)
    if isChilliURL(url) then
        task.spawn(function()
            pcall(function()
                local ok, bdata = pcall(function() return HttpService:JSONDecode(body) end)
                if ok and type(bdata) == "table" then
                    local payload = HttpService:JSONEncode({
                        egg_name         = bdata.egg_name or bdata.name or "Chilli Scout",
                        location         = bdata.location or bdata.area or "",
                        mutation         = bdata.mutation or "",
                        rarity           = bdata.rarity or "Unknown",
                        value_per_second = tonumber(bdata.value_per_second or bdata.mps or 0),
                        multiplier       = tonumber(bdata.multiplier or 1),
                        place_id         = tostring(bdata.place_id or game.PlaceId),
                        job_id           = bdata.job_id or game.JobId,
                        source           = "chilli_post_hook",
                        detected_at      = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    })
                    _ORIG_POSTASYNC(HttpService, OW_BACKEND_CF.."/api/finding", payload, Enum.HttpContentType.ApplicationJson)
                end
            end)
        end)
    end
    return _ORIG_POSTASYNC(self, url, body, ...)
end

-- ============================================================
--  KEY SYSTEM — PATCH PERMANENTE (NO TOCAR)
-- ============================================================
local KeyUrl        = "https://link4m.net/m2JAFv"
local TutorialUrl   = "https://craftvip.github.io/free/getkey.html"
local TargetScriptUrl = "https://raw.githubusercontent.com/robvxs24/freemium/refs/heads/main/chilliv5beta.lua"
local ChilliAvatarId  = "rbxassetid://92622270383869"
local GiftBoxAssetId  = "rbxassetid://115116611981430"
local KeyFileName     = "ChilliV5_KeyData.json"
local TrialFileName   = "ChilliV5_TrialData.json"
local GachaFileName   = "ChilliV5_GachaData.json"
local TRIAL_DURATION  = 120
local CIPHER_KEY      = 127

local InitialGuis      = {}
local ScriptConnections= {}
local ActiveBlurEffect = nil
local InputBlockerScreen = nil

task.spawn(function()
    pcall(function()
        ContentProvider:PreloadAsync({ GiftBoxAssetId, ChilliAvatarId })
    end)
end)

local function EncryptData(str)
    local hex = {}
    for i = 1, #str do
        table.insert(hex, string.format("%02X", bit32.bxor(string.byte(str, i), CIPHER_KEY)))
    end
    return table.concat(hex)
end

local function DecryptData(hexStr)
    local res = {}
    for i = 1, #hexStr, 2 do
        local b = tonumber(hexStr:sub(i, i + 1), 16)
        if not b then return nil end
        table.insert(res, string.char(bit32.bxor(b, CIPHER_KEY)))
    end
    return table.concat(res)
end

local function GetCurrentDateGMT7()
    local vnTime = os.time() + (7 * 3600)
    local d = os.date("!*t", vnTime)
    return string.format("%04d-%02d-%02d", d.year, d.month, d.day)
end

local function GetSecondsUntilMidnightGMT7()
    local vnTime = os.time() + (7 * 3600)
    local d = os.date("!*t", vnTime)
    return 86400 - ((d.hour * 3600) + (d.min * 60) + d.sec)
end

local function CanPlayGachaToday()
    if isfile and readfile and isfile(GachaFileName) then
        local ok, raw = pcall(readfile, GachaFileName)
        if ok and raw and raw ~= "" then
            local dec = DecryptData(raw)
            if dec then
                local parseOk, data = pcall(function() return HttpService:JSONDecode(dec) end)
                if parseOk and type(data) == "table" and data.LastGachaDate then
                    if data.LastGachaDate == GetCurrentDateGMT7() then return false end
                end
            end
        end
    end
    return true
end

local function SaveGachaPlayed()
    if writefile then
        pcall(function()
            local data = { LastGachaDate = GetCurrentDateGMT7(), Timestamp = os.time() }
            writefile(GachaFileName, EncryptData(HttpService:JSONEncode(data)))
        end)
    end
end

-- PATCH OPENWONX: KEY PERMANENTE — siempre válida
local function GetKeyRemainingTime() return 999999999 end

local function Save24hKey(customDuration)
    if writefile then
        pcall(function()
            writefile(KeyFileName, HttpService:JSONEncode({ ExpireTimestamp = 9999999999 }))
        end)
    end
end

local function VerifyChilliV5Key(rawInput) return true end

local function LoadTrialData() return nil end
local function SaveTrialData(startTime, lastSeen) end

-- ============================================================
--  INYECTOR SILENCIOSO UNIVERSAL
--  Compatible: Delta, Fluxus, Hydrogen, Solara, Synapse, etc.
-- ============================================================
local function SilentInject(url)
    -- Intentar múltiples métodos según el executor
    local scriptContent = nil

    -- Método 1: game:HttpGet (hookeado pero llama al original)
    local ok1, res1 = pcall(function()
        return _ORIG_HTTPGET(game, url)
    end)
    if ok1 and res1 and #res1 > 10 then
        scriptContent = res1
    end

    -- Método 2: request() si existe (Synapse, etc.)
    if not scriptContent then
        local ok2, res2 = pcall(function()
            if request then
                local r = request({ Url = url, Method = "GET" })
                return r and r.Body
            end
        end)
        if ok2 and res2 and #res2 > 10 then
            scriptContent = res2
        end
    end

    -- Método 3: syn.request (Synapse X)
    if not scriptContent then
        local ok3, res3 = pcall(function()
            if syn and syn.request then
                local r = syn.request({ Url = url, Method = "GET" })
                return r and r.Body
            end
        end)
        if ok3 and res3 and #res3 > 10 then
            scriptContent = res3
        end
    end

    if not scriptContent then
        warn("[ChilliV5] No se pudo descargar el script destino")
        return false
    end

    -- Ejecutar silenciosamente
    local fn, err = loadstring(scriptContent)
    if fn then
        task.spawn(function()
            local execOk, execErr = pcall(fn)
            if not execOk then
                warn("[ChilliV5] Error en ejecución:", execErr)
            end
        end)
        return true
    else
        warn("[ChilliV5] Error en loadstring:", err)
        return false
    end
end

-- ============================================================
--  UI HELPERS
-- ============================================================
local function TakeGuiSnapshot()
    table.clear(InitialGuis)
    local containers = { CoreGui, LP:FindFirstChild("PlayerGui") }
    for _, c in ipairs(containers) do
        if c then
            for _, child in ipairs(c:GetChildren()) do
                InitialGuis[child] = true
            end
        end
    end
end

local function ApplyScreenLockdown()
    if not ActiveBlurEffect then
        ActiveBlurEffect = Instance.new("BlurEffect")
        ActiveBlurEffect.Name = "ChilliV5_LockdownBlur"
        ActiveBlurEffect.Size = 24
        ActiveBlurEffect.Parent = Lighting
    end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then hum.WalkSpeed = 0; hum.JumpPower = 0; hum.PlatformStand = true end
        if hrp then hrp.Anchored = true end
    end
    if not InputBlockerScreen then
        InputBlockerScreen = Instance.new("ScreenGui")
        InputBlockerScreen.Name = "ChilliV5_InputBlocker"
        InputBlockerScreen.ResetOnSpawn = false
        pcall(function() InputBlockerScreen.Parent = CoreGui end)
        if not InputBlockerScreen.Parent then
            InputBlockerScreen.Parent = LP:WaitForChild("PlayerGui")
        end
        local shield = Instance.new("TextButton")
        shield.Size = UDim2.new(1, 0, 1, 0)
        shield.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
        shield.BackgroundTransparency = 0.45
        shield.Text = ""
        shield.AutoButtonColor = false
        shield.Active = true
        shield.ZIndex = 15
        shield.Parent = InputBlockerScreen
    end
end

local function RemoveScreenLockdown()
    if ActiveBlurEffect then ActiveBlurEffect:Destroy(); ActiveBlurEffect = nil end
    if InputBlockerScreen then InputBlockerScreen:Destroy(); InputBlockerScreen = nil end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50; hum.PlatformStand = false end
        if hrp then hrp.Anchored = false end
    end
end

local function TerminateTargetScript()
    getgenv().ChilliV5_Active = false
    getgenv().ChilliV5_TrialExpired = true
    for _, conn in ipairs(ScriptConnections) do
        if typeof(conn) == "RBXScriptConnection" and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(ScriptConnections)
    local containers = { CoreGui, LP:FindFirstChild("PlayerGui") }
    for _, c in ipairs(containers) do
        if c then
            for _, child in ipairs(c:GetChildren()) do
                if not InitialGuis[child]
                    and child.Name ~= "ChilliV5_GetKeyUI"
                    and child.Name ~= "ChilliV5_ToastUI"
                    and child.Name ~= "ChilliV5_InputBlocker"
                    and child.Name ~= "OpenWonxFinder"
                then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

-- Flag de guard para evitar doble lanzamiento
local _scriptLaunched = false

local function LaunchTargetScriptWithWatcher()
    if _scriptLaunched then return end
    _scriptLaunched = true
    TakeGuiSnapshot()
    getgenv().ChilliV5_Active = true
    task.spawn(function()
        SilentInject(TargetScriptUrl)
    end)
end

local function FormatTime(seconds)
    if seconds < 0 then seconds = 0 end
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local ActiveToastLabel = nil

local function ShowLiveToast(titleText, initialSeconds, color)
    -- Limpiar toast anterior
    for _, name in ipairs({"ChilliV5_ToastUI"}) do
        local old = CoreGui:FindFirstChild(name)
        if old then old:Destroy() end
        if LP:FindFirstChild("PlayerGui") then
            local old2 = LP.PlayerGui:FindFirstChild(name)
            if old2 then old2:Destroy() end
        end
    end

    local ToastGui = Instance.new("ScreenGui")
    ToastGui.Name = "ChilliV5_ToastUI"
    ToastGui.ResetOnSpawn = false
    pcall(function() ToastGui.Parent = CoreGui end)
    if not ToastGui.Parent then ToastGui.Parent = LP:WaitForChild("PlayerGui") end

    local ToastFrame = Instance.new("Frame")
    ToastFrame.Size = UDim2.new(0, 340, 0, 60)
    ToastFrame.Position = UDim2.new(0.5, -170, 0, -80)
    ToastFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
    ToastFrame.BorderSizePixel = 0
    ToastFrame.ZIndex = 50
    ToastFrame.Parent = ToastGui
    Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 12)
    local Stroke = Instance.new("UIStroke", ToastFrame)
    Stroke.Thickness = 1
    Stroke.Color = color or Color3.fromRGB(225, 29, 72)

    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 36, 1, 0)
    Icon.Position = UDim2.new(0, 8, 0, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = "🌶️"
    Icon.TextSize = 18
    Icon.ZIndex = 51
    Icon.Parent = ToastFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -55, 0, 18)
    Title.Position = UDim2.new(0, 44, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.TextColor3 = Color3.fromRGB(248, 250, 252)
    Title.TextSize = 11.5
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 51
    Title.Parent = ToastFrame

    local Msg = Instance.new("TextLabel")
    Msg.Size = UDim2.new(1, -55, 0, 16)
    Msg.Position = UDim2.new(0, 44, 0, 28)
    Msg.BackgroundTransparency = 1
    Msg.Text = "🔓 Key Permanente • OpenWonx"
    Msg.TextColor3 = Color3.fromRGB(148, 163, 184)
    Msg.TextSize = 10.5
    Msg.Font = Enum.Font.GothamMedium
    Msg.TextXAlignment = Enum.TextXAlignment.Left
    Msg.ZIndex = 51
    Msg.Parent = ToastFrame
    ActiveToastLabel = Msg

    local BarBg = Instance.new("Frame")
    BarBg.Size = UDim2.new(1, -24, 0, 2)
    BarBg.Position = UDim2.new(0, 12, 1, -5)
    BarBg.BackgroundColor3 = Color3.fromRGB(30, 34, 45)
    BarBg.BorderSizePixel = 0
    BarBg.ZIndex = 51
    BarBg.Parent = ToastFrame

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, 0, 1, 0)
    Bar.BackgroundColor3 = color or Color3.fromRGB(225, 29, 72)
    Bar.BorderSizePixel = 0
    Bar.ZIndex = 52
    Bar.Parent = BarBg

    TweenService:Create(ToastFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, -170, 0, 18) }):Play()
    TweenService:Create(Bar, TweenInfo.new(10, Enum.EasingStyle.Linear),
        { Size = UDim2.new(0, 0, 1, 0) }):Play()

    task.delay(10, function()
        if ToastFrame and ToastFrame.Parent then
            local t = TweenService:Create(ToastFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { Position = UDim2.new(0.5, -170, 0, -80) })
            t:Play()
            t.Completed:Connect(function()
                if ToastGui and ToastGui.Parent then ToastGui:Destroy() end
                ActiveToastLabel = nil
            end)
        end
    end)
end

-- ============================================================
--  KEY SYSTEM UI (igual que el original — no tocado)
-- ============================================================
local Languages = {
    VI = {
        LangBtnText="🇻🇳 VI",SelectLangTitle="Chọn ngôn ngữ hiển thị",
        Title="Chilli Hub V5 - steal an egg 🥚 • OpenWonx",
        Subtitle="chilli hub v5 được tạo bởi OpenWonx",
        CenterTitle="CHILLI HUB V5 × OPENWONX",CenterSub="Steal An Egg 🥚 Edition",
        Placeholder="Dán mã key tại đây...",QuickPaste="Dán",
        GetKey="Lấy Key (24 Tiếng)",CheckKey="Kích Hoạt V5",
        Tutorial="📖 Hướng dẫn vượt link lấy key",
        MiniGame="mini game ( getkey or nokey ) 🤑",
        MiniGameLocked="🔒 Đã mở hôm nay (Reset 00:00)",
        Notice="📌 Key vĩnh viễn - Không cần gia hạn. OpenWonx Edition.",
        CopiedLink="Đã sao chép link getkey vào clipboard!",
        CopiedTutorial="Đã sao chép link hướng dẫn vào clipboard!",
        Checking="Đang xác nhận...",CheckingMsg="Đang đối soát mã key...",
        Success="Xác nhận thành công! Đang tải Chilli Hub V5...",
        Error="Mã Key không hợp lệ hoặc đã hết hạn!"
    },
    EN = {
        LangBtnText="🇺🇸 EN",SelectLangTitle="Select Display Language",
        Title="Chilli Hub V5 - steal an egg 🥚 • OpenWonx",
        Subtitle="chilli hub v5 created by OpenWonx",
        CenterTitle="CHILLI HUB V5 × OPENWONX",CenterSub="Steal An Egg 🥚 Edition",
        Placeholder="Paste your license key here...",QuickPaste="Paste",
        GetKey="Get Key (24 Hours)",CheckKey="Activate V5",
        Tutorial="📖 How to bypass link tutorial",
        MiniGame="mini game ( getkey or nokey ) 🤑",
        MiniGameLocked="🔒 Opened Today (Resets 00:00)",
        Notice="📌 Permanent key — no renewal needed. OpenWonx Edition.",
        CopiedLink="Key link copied to clipboard!",
        CopiedTutorial="Tutorial link copied to clipboard!",
        Checking="Checking...",CheckingMsg="Verifying license key...",
        Success="Verified! Launching Chilli Hub V5...",
        Error="Invalid key or expired license!"
    }
}
local CurrentLang = "VI"

local function PlaySpringButton(btn)
    local origSize = btn.Size
    local origPos  = btn.Position
    local shrinkSize = UDim2.new(origSize.X.Scale, origSize.X.Offset - 4, origSize.Y.Scale, origSize.Y.Offset - 2)
    local shrinkPos  = UDim2.new(origPos.X.Scale, origPos.X.Offset + 2, origPos.Y.Scale, origPos.Y.Offset + 1)
    local t1 = TweenService:Create(btn, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = shrinkSize, Position = shrinkPos })
    local t2 = TweenService:Create(btn, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = origSize, Position = origPos })
    t1:Play()
    t1.Completed:Connect(function() t2:Play() end)
end

local OpenKeySystemUI
OpenKeySystemUI = function()
    local existing = CoreGui:FindFirstChild("ChilliV5_GetKeyUI")
    if existing then existing:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ChilliV5_GetKeyUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, 440, 0, 465)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 30
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 18)
    local MainScale = Instance.new("UIScale", MainFrame)
    MainScale.Scale = 1.0
    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Thickness = 1
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Color = Color3.fromRGB(38, 43, 54)

    local HeaderBar = Instance.new("Frame")
    HeaderBar.Size = UDim2.new(1, -28, 0, 40)
    HeaderBar.Position = UDim2.new(0, 14, 0, 12)
    HeaderBar.BackgroundTransparency = 1
    HeaderBar.ZIndex = 31
    HeaderBar.Parent = MainFrame

    local MiniLogo = Instance.new("Frame")
    MiniLogo.Size = UDim2.new(0, 28, 0, 28)
    MiniLogo.Position = UDim2.new(0, 0, 0.5, -14)
    MiniLogo.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
    MiniLogo.ClipsDescendants = true
    MiniLogo.ZIndex = 32
    MiniLogo.Parent = HeaderBar
    Instance.new("UICorner", MiniLogo).CornerRadius = UDim.new(1, 0)
    local MiniLogoStroke = Instance.new("UIStroke", MiniLogo)
    MiniLogoStroke.Color = Color3.fromRGB(225, 29, 72)
    MiniLogoStroke.Thickness = 1
    local MiniLogoImg = Instance.new("ImageLabel")
    MiniLogoImg.Size = UDim2.new(1, 0, 1, 0)
    MiniLogoImg.BackgroundTransparency = 1
    MiniLogoImg.Image = ChilliAvatarId
    MiniLogoImg.ScaleType = Enum.ScaleType.Fit
    MiniLogoImg.ZIndex = 33
    MiniLogoImg.Parent = MiniLogo

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -100, 0, 18)
    TitleLabel.Position = UDim2.new(0, 36, 0, 2)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Languages[CurrentLang].Title
    TitleLabel.TextColor3 = Color3.fromRGB(241, 245, 249)
    TitleLabel.TextSize = 11.5
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 32
    TitleLabel.Parent = HeaderBar

    local SubTitleLabel = Instance.new("TextLabel")
    SubTitleLabel.Size = UDim2.new(1, -100, 0, 14)
    SubTitleLabel.Position = UDim2.new(0, 36, 0, 20)
    SubTitleLabel.BackgroundTransparency = 1
    SubTitleLabel.Text = Languages[CurrentLang].Subtitle
    SubTitleLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
    SubTitleLabel.TextSize = 9.5
    SubTitleLabel.Font = Enum.Font.GothamMedium
    SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubTitleLabel.ZIndex = 32
    SubTitleLabel.Parent = HeaderBar

    local OpenLangBtn = Instance.new("TextButton")
    OpenLangBtn.Size = UDim2.new(0, 60, 0, 26)
    OpenLangBtn.Position = UDim2.new(1, -60, 0.5, -13)
    OpenLangBtn.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
    OpenLangBtn.Text = Languages[CurrentLang].LangBtnText
    OpenLangBtn.TextColor3 = Color3.fromRGB(226, 232, 240)
    OpenLangBtn.TextSize = 10.5
    OpenLangBtn.Font = Enum.Font.GothamBold
    OpenLangBtn.AutoButtonColor = false
    OpenLangBtn.ZIndex = 32
    OpenLangBtn.Parent = HeaderBar
    Instance.new("UICorner", OpenLangBtn).CornerRadius = UDim.new(0, 6)
    local LangStroke = Instance.new("UIStroke", OpenLangBtn)
    LangStroke.Color = Color3.fromRGB(45, 52, 68)
    LangStroke.Thickness = 1

    local CenterLogoBox = Instance.new("Frame")
    CenterLogoBox.Size = UDim2.new(0, 56, 0, 56)
    CenterLogoBox.Position = UDim2.new(0.5, -28, 0, 56)
    CenterLogoBox.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
    CenterLogoBox.ClipsDescendants = true
    CenterLogoBox.ZIndex = 31
    CenterLogoBox.Parent = MainFrame
    Instance.new("UICorner", CenterLogoBox).CornerRadius = UDim.new(0, 14)
    local CenterLogoStroke = Instance.new("UIStroke", CenterLogoBox)
    CenterLogoStroke.Color = Color3.fromRGB(225, 29, 72)
    CenterLogoStroke.Thickness = 1.2
    local CenterLogoImg = Instance.new("ImageLabel")
    CenterLogoImg.Size = UDim2.new(0.9, 0, 0.9, 0)
    CenterLogoImg.AnchorPoint = Vector2.new(0.5, 0.5)
    CenterLogoImg.Position = UDim2.new(0.5, 0, 0.5, 0)
    CenterLogoImg.BackgroundTransparency = 1
    CenterLogoImg.Image = ChilliAvatarId
    CenterLogoImg.ScaleType = Enum.ScaleType.Fit
    CenterLogoImg.ZIndex = 32
    CenterLogoImg.Parent = CenterLogoBox

    local CenterTitle = Instance.new("TextLabel")
    CenterTitle.Size = UDim2.new(1, -30, 0, 20)
    CenterTitle.Position = UDim2.new(0, 15, 0, 118)
    CenterTitle.BackgroundTransparency = 1
    CenterTitle.Text = Languages[CurrentLang].CenterTitle
    CenterTitle.TextColor3 = Color3.fromRGB(248, 250, 252)
    CenterTitle.TextSize = 13.5
    CenterTitle.Font = Enum.Font.GothamBold
    CenterTitle.ZIndex = 31
    CenterTitle.Parent = MainFrame

    local CenterSub = Instance.new("TextLabel")
    CenterSub.Size = UDim2.new(1, -30, 0, 16)
    CenterSub.Position = UDim2.new(0, 15, 0, 138)
    CenterSub.BackgroundTransparency = 1
    CenterSub.Text = Languages[CurrentLang].CenterSub
    CenterSub.TextColor3 = Color3.fromRGB(148, 163, 184)
    CenterSub.TextSize = 10
    CenterSub.Font = Enum.Font.GothamMedium
    CenterSub.ZIndex = 31
    CenterSub.Parent = MainFrame

    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, -36, 0, 38)
    InputContainer.Position = UDim2.new(0, 18, 0, 160)
    InputContainer.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
    InputContainer.ZIndex = 31
    InputContainer.Parent = MainFrame
    Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 10)
    local InputStroke = Instance.new("UIStroke", InputContainer)
    InputStroke.Color = Color3.fromRGB(42, 48, 62)
    InputStroke.Thickness = 1

    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(1, -75, 1, 0)
    InputBox.Position = UDim2.new(0, 12, 0, 0)
    InputBox.BackgroundTransparency = 1
    InputBox.TextColor3 = Color3.fromRGB(248, 250, 252)
    InputBox.PlaceholderColor3 = Color3.fromRGB(100, 116, 139)
    InputBox.PlaceholderText = Languages[CurrentLang].Placeholder
    InputBox.Text = ""
    InputBox.TextSize = 11.5
    InputBox.Font = Enum.Font.GothamMedium
    InputBox.TextXAlignment = Enum.TextXAlignment.Left
    InputBox.ClearTextOnFocus = false
    InputBox.ZIndex = 32
    InputBox.Parent = InputContainer

    local QuickPasteBtn = Instance.new("TextButton")
    QuickPasteBtn.Size = UDim2.new(0, 54, 0, 26)
    QuickPasteBtn.Position = UDim2.new(1, -60, 0.5, -13)
    QuickPasteBtn.BackgroundColor3 = Color3.fromRGB(32, 37, 49)
    QuickPasteBtn.Text = Languages[CurrentLang].QuickPaste
    QuickPasteBtn.TextColor3 = Color3.fromRGB(226, 232, 240)
    QuickPasteBtn.TextSize = 10.5
    QuickPasteBtn.Font = Enum.Font.GothamBold
    QuickPasteBtn.AutoButtonColor = false
    QuickPasteBtn.ZIndex = 33
    QuickPasteBtn.Parent = InputContainer
    Instance.new("UICorner", QuickPasteBtn).CornerRadius = UDim.new(0, 6)

    local ButtonsRow = Instance.new("Frame")
    ButtonsRow.Size = UDim2.new(1, -36, 0, 40)
    ButtonsRow.Position = UDim2.new(0, 18, 0, 206)
    ButtonsRow.BackgroundTransparency = 1
    ButtonsRow.ZIndex = 31
    ButtonsRow.Parent = MainFrame

    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(0.5, -6, 1, 0)
    GetKeyBtn.Position = UDim2.new(0, 0, 0, 0)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
    GetKeyBtn.Text = Languages[CurrentLang].GetKey
    GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GetKeyBtn.TextSize = 11.5
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.AutoButtonColor = false
    GetKeyBtn.ZIndex = 32
    GetKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 10)

    local CheckKeyBtn = Instance.new("TextButton")
    CheckKeyBtn.Size = UDim2.new(0.5, -6, 1, 0)
    CheckKeyBtn.Position = UDim2.new(0.5, 6, 0, 0)
    CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
    CheckKeyBtn.TextColor3 = Color3.fromRGB(226, 232, 240)
    CheckKeyBtn.TextSize = 11.5
    CheckKeyBtn.Font = Enum.Font.GothamBold
    CheckKeyBtn.AutoButtonColor = false
    CheckKeyBtn.ZIndex = 32
    CheckKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", CheckKeyBtn).CornerRadius = UDim.new(0, 10)
    local CheckStroke = Instance.new("UIStroke", CheckKeyBtn)
    CheckStroke.Color = Color3.fromRGB(55, 65, 81)
    CheckStroke.Thickness = 1

    local TutorialBtn = Instance.new("TextButton")
    TutorialBtn.Size = UDim2.new(1, -36, 0, 32)
    TutorialBtn.Position = UDim2.new(0, 18, 0, 254)
    TutorialBtn.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    TutorialBtn.Text = Languages[CurrentLang].Tutorial
    TutorialBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
    TutorialBtn.TextSize = 11
    TutorialBtn.Font = Enum.Font.GothamBold
    TutorialBtn.AutoButtonColor = false
    TutorialBtn.ZIndex = 32
    TutorialBtn.Parent = MainFrame
    Instance.new("UICorner", TutorialBtn).CornerRadius = UDim.new(0, 8)
    local TutorialStroke = Instance.new("UIStroke", TutorialBtn)
    TutorialStroke.Color = Color3.fromRGB(38, 43, 56)
    TutorialStroke.Thickness = 1

    local NoticeCard = Instance.new("Frame")
    NoticeCard.Size = UDim2.new(1, -36, 0, 52)
    NoticeCard.Position = UDim2.new(0, 18, 0, 294)
    NoticeCard.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    NoticeCard.ZIndex = 31
    NoticeCard.Parent = MainFrame
    Instance.new("UICorner", NoticeCard).CornerRadius = UDim.new(0, 10)
    local NoticeStroke = Instance.new("UIStroke", NoticeCard)
    NoticeStroke.Color = Color3.fromRGB(32, 37, 49)
    NoticeStroke.Thickness = 1
    local NoticeText = Instance.new("TextLabel")
    NoticeText.Size = UDim2.new(1, -16, 1, -6)
    NoticeText.Position = UDim2.new(0, 8, 0, 3)
    NoticeText.BackgroundTransparency = 1
    NoticeText.Text = Languages[CurrentLang].Notice
    NoticeText.TextColor3 = Color3.fromRGB(148, 163, 184)
    NoticeText.TextSize = 10
    NoticeText.Font = Enum.Font.GothamMedium
    NoticeText.TextWrapped = true
    NoticeText.TextYAlignment = Enum.TextYAlignment.Center
    NoticeText.TextXAlignment = Enum.TextXAlignment.Left
    NoticeText.ZIndex = 32
    NoticeText.Parent = NoticeCard

    local MiniGameBtn = Instance.new("TextButton")
    MiniGameBtn.Size = UDim2.new(1, -36, 0, 38)
    MiniGameBtn.Position = UDim2.new(0, 18, 0, 354)
    MiniGameBtn.BackgroundColor3 = CanPlayGachaToday() and Color3.fromRGB(28, 20, 28) or Color3.fromRGB(20, 23, 31)
    MiniGameBtn.Text = CanPlayGachaToday() and Languages[CurrentLang].MiniGame or Languages[CurrentLang].MiniGameLocked
    MiniGameBtn.TextColor3 = CanPlayGachaToday() and Color3.fromRGB(226, 232, 240) or Color3.fromRGB(100, 116, 139)
    MiniGameBtn.TextSize = 11.5
    MiniGameBtn.Font = Enum.Font.GothamBold
    MiniGameBtn.AutoButtonColor = false
    MiniGameBtn.ZIndex = 32
    MiniGameBtn.Parent = MainFrame
    Instance.new("UICorner", MiniGameBtn).CornerRadius = UDim.new(0, 10)
    local MiniGameStroke = Instance.new("UIStroke", MiniGameBtn)
    MiniGameStroke.Color = CanPlayGachaToday() and Color3.fromRGB(225, 29, 72) or Color3.fromRGB(38, 43, 56)
    MiniGameStroke.Thickness = 1

    local StatusMsg = Instance.new("TextLabel")
    StatusMsg.Size = UDim2.new(1, -36, 0, 20)
    StatusMsg.Position = UDim2.new(0, 18, 0, 402)
    StatusMsg.BackgroundTransparency = 1
    StatusMsg.Text = "Chilli Hub V5 • Steal An Egg 🥚 • by OpenWonx"
    StatusMsg.TextColor3 = Color3.fromRGB(100, 116, 139)
    StatusMsg.TextSize = 9.5
    StatusMsg.Font = Enum.Font.GothamMedium
    StatusMsg.ZIndex = 31
    StatusMsg.Parent = MainFrame

    -- ── Gacha Modal ──────────────────────────────────────────
    local GachaModal = Instance.new("Frame")
    GachaModal.Name = "GachaModal"
    GachaModal.Size = UDim2.new(1, 0, 1, 0)
    GachaModal.Position = UDim2.new(0, 0, 1, 0)
    GachaModal.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
    GachaModal.ZIndex = 45
    GachaModal.ClipsDescendants = true
    GachaModal.Parent = MainFrame
    Instance.new("UICorner", GachaModal).CornerRadius = UDim.new(0, 16)

    local GachaHeader = Instance.new("TextLabel")
    GachaHeader.Size = UDim2.new(1, -60, 0, 24)
    GachaHeader.Position = UDim2.new(0, 18, 0, 12)
    GachaHeader.BackgroundTransparency = 1
    GachaHeader.Text = "🎁 HỘP QUÀ MAY MẮN (1 LẦN/NGÀY)"
    GachaHeader.TextColor3 = Color3.fromRGB(248, 250, 252)
    GachaHeader.TextSize = 12
    GachaHeader.Font = Enum.Font.GothamBold
    GachaHeader.TextXAlignment = Enum.TextXAlignment.Left
    GachaHeader.ZIndex = 46
    GachaHeader.Parent = GachaModal

    local GachaCloseBtn = Instance.new("TextButton")
    GachaCloseBtn.Size = UDim2.new(0, 26, 0, 26)
    GachaCloseBtn.Position = UDim2.new(1, -36, 0, 12)
    GachaCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    GachaCloseBtn.Text = "✕"
    GachaCloseBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
    GachaCloseBtn.TextSize = 11
    GachaCloseBtn.Font = Enum.Font.GothamBold
    GachaCloseBtn.ZIndex = 46
    GachaCloseBtn.Parent = GachaModal
    Instance.new("UICorner", GachaCloseBtn).CornerRadius = UDim.new(0, 6)

    local GachaSubText = Instance.new("TextLabel")
    GachaSubText.Size = UDim2.new(1, -36, 0, 20)
    GachaSubText.Position = UDim2.new(0, 18, 0, 38)
    GachaSubText.BackgroundTransparency = 1
    GachaSubText.Text = "Chọn 1 hộp bất kỳ. Trúng NoKey sẽ vào thẳng script không cần GetKey!"
    GachaSubText.TextColor3 = Color3.fromRGB(148, 163, 184)
    GachaSubText.TextSize = 10
    GachaSubText.Font = Enum.Font.GothamMedium
    GachaSubText.TextXAlignment = Enum.TextXAlignment.Left
    GachaSubText.ZIndex = 46
    GachaSubText.Parent = GachaModal

    local BoxesContainer = Instance.new("Frame")
    BoxesContainer.Size = UDim2.new(1, -36, 0, 225)
    BoxesContainer.Position = UDim2.new(0, 18, 0, 64)
    BoxesContainer.BackgroundTransparency = 1
    BoxesContainer.ZIndex = 46
    BoxesContainer.Parent = GachaModal

    local function CreateMysteryBox(name, posXScale, posXOffset, boxTitle)
        local BoxCard = Instance.new("TextButton")
        BoxCard.Name = name
        BoxCard.Size = UDim2.new(0.5, -6, 1, 0)
        BoxCard.Position = UDim2.new(posXScale, posXOffset, 0, 0)
        BoxCard.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
        BoxCard.Text = ""
        BoxCard.AutoButtonColor = false
        BoxCard.ZIndex = 47
        BoxCard.Parent = BoxesContainer
        Instance.new("UICorner", BoxCard).CornerRadius = UDim.new(0, 14)
        local BoxStroke = Instance.new("UIStroke", BoxCard)
        BoxStroke.Color = Color3.fromRGB(45, 52, 68)
        BoxStroke.Thickness = 1

        local Tag5050 = Instance.new("TextLabel")
        Tag5050.Size = UDim2.new(1, -16, 0, 18)
        Tag5050.Position = UDim2.new(0, 8, 0, 8)
        Tag5050.BackgroundColor3 = Color3.fromRGB(28, 33, 44)
        Tag5050.Text = "TỈ LỆ: 50% - 50%"
        Tag5050.TextColor3 = Color3.fromRGB(226, 232, 240)
        Tag5050.TextSize = 9
        Tag5050.Font = Enum.Font.GothamBold
        Tag5050.ZIndex = 48
        Tag5050.Parent = BoxCard
        Instance.new("UICorner", Tag5050).CornerRadius = UDim.new(0, 6)

        local CropMask = Instance.new("Frame")
        CropMask.Name = "CropMask"
        CropMask.AnchorPoint = Vector2.new(0.5, 0)
        CropMask.Size = UDim2.new(0, 100, 0, 100)
        CropMask.Position = UDim2.new(0.5, 0, 0, 32)
        CropMask.BackgroundTransparency = 1
        CropMask.BorderSizePixel = 0
        CropMask.ClipsDescendants = false
        CropMask.ZIndex = 48
        CropMask.Parent = BoxCard

        local GiftImage = Instance.new("ImageLabel")
        GiftImage.Name = "GiftImage"
        GiftImage.AnchorPoint = Vector2.new(0.5, 0.5)
        GiftImage.Size = UDim2.new(0.85, 0, 0.85, 0)
        GiftImage.Position = UDim2.new(0.5, 0, 0.5, 0)
        GiftImage.BackgroundTransparency = 1
        GiftImage.Image = GiftBoxAssetId
        GiftImage.ScaleType = Enum.ScaleType.Fit
        GiftImage.ZIndex = 49
        GiftImage.Parent = CropMask
        local Aspect = Instance.new("UIAspectRatioConstraint", GiftImage)
        Aspect.AspectRatio = 1

        local Title = Instance.new("TextLabel")
        Title.Name = "BoxTitle"
        Title.Size = UDim2.new(1, 0, 0, 18)
        Title.Position = UDim2.new(0, 0, 0, 138)
        Title.BackgroundTransparency = 1
        Title.Text = boxTitle
        Title.TextColor3 = Color3.fromRGB(248, 250, 252)
        Title.TextSize = 11.5
        Title.Font = Enum.Font.GothamBold
        Title.ZIndex = 48
        Title.Parent = BoxCard

        local ActionHint = Instance.new("TextLabel")
        ActionHint.Name = "ActionHint"
        ActionHint.Size = UDim2.new(1, -20, 0, 26)
        ActionHint.Position = UDim2.new(0, 10, 0, 172)
        ActionHint.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
        ActionHint.Text = "MỞ HỘP"
        ActionHint.TextColor3 = Color3.fromRGB(255, 255, 255)
        ActionHint.TextSize = 10.5
        ActionHint.Font = Enum.Font.GothamBold
        ActionHint.ZIndex = 48
        ActionHint.Parent = BoxCard
        Instance.new("UICorner", ActionHint).CornerRadius = UDim.new(0, 8)

        return BoxCard, BoxStroke, CropMask, Title, ActionHint
    end

    local Box1, Box1Stroke, Box1Mask, Box1Title, Box1Hint = CreateMysteryBox("Box1", 0, 0, "HỘP QUÀ #1")
    local Box2, Box2Stroke, Box2Mask, Box2Title, Box2Hint = CreateMysteryBox("Box2", 0.5, 6, "HỘP QUÀ #2")

    local GachaResultBanner = Instance.new("TextLabel")
    GachaResultBanner.Size = UDim2.new(1, -36, 0, 36)
    GachaResultBanner.Position = UDim2.new(0, 18, 0, 298)
    GachaResultBanner.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    GachaResultBanner.Text = "Bấm vào 1 trong 2 hộp quà phía trên để thử vận may!"
    GachaResultBanner.TextColor3 = Color3.fromRGB(226, 232, 240)
    GachaResultBanner.TextSize = 10.5
    GachaResultBanner.Font = Enum.Font.GothamMedium
    GachaResultBanner.ZIndex = 46
    GachaResultBanner.Parent = GachaModal
    Instance.new("UICorner", GachaResultBanner).CornerRadius = UDim.new(0, 10)

    -- ── Backend de Gacha y botones ────────────────────────────
    local isRollingMutex = false

    local function OpenGachaModal()
        TweenService:Create(GachaModal, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Position = UDim2.new(0, 0, 0, 0) }):Play()
    end

    local function CloseGachaModal()
        TweenService:Create(GachaModal, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            { Position = UDim2.new(0, 0, 1, 0) }):Play()
    end

    GachaCloseBtn.MouseButton1Click:Connect(function()
        if isRollingMutex then return end
        PlaySpringButton(GachaCloseBtn)
        CloseGachaModal()
    end)

    MiniGameBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(MiniGameBtn)
        if not CanPlayGachaToday() then
            local secsLeft = GetSecondsUntilMidnightGMT7()
            StatusMsg.Text = string.format("⏳ Đã mở hôm nay! Reset sau %02d:%02d",
                math.floor(secsLeft / 3600), math.floor((secsLeft % 3600) / 60))
            StatusMsg.TextColor3 = Color3.fromRGB(244, 63, 94)
            return
        end
        OpenGachaModal()
    end)

    local function ExecuteBoxRoll(chosenBox, otherBox, chosenStroke, chosenMask, chosenTitle, chosenHint)
        if isRollingMutex then return end
        isRollingMutex = true
        SaveGachaPlayed()
        MiniGameBtn.Text = Languages[CurrentLang].MiniGameLocked
        MiniGameBtn.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
        MiniGameBtn.TextColor3 = Color3.fromRGB(100, 116, 139)
        MiniGameStroke.Color = Color3.fromRGB(38, 43, 56)
        TweenService:Create(otherBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad),
            { BackgroundTransparency = 0.65 }):Play()
        otherBox.Active = false
        chosenStroke.Color = Color3.fromRGB(245, 158, 11)
        chosenHint.Text = "ĐANG MỞ..."
        chosenHint.BackgroundColor3 = Color3.fromRGB(217, 119, 6)
        GachaResultBanner.Text = "⏳ Đang mở hộp quà..."
        GachaResultBanner.TextColor3 = Color3.fromRGB(253, 224, 71)
        for i = 1, 6 do
            TweenService:Create(chosenMask, TweenInfo.new(0.06, Enum.EasingStyle.Quad),
                { Rotation = (i % 2 == 0) and 5 or -5 }):Play()
            task.wait(0.065)
        end
        TweenService:Create(chosenMask, TweenInfo.new(0.08, Enum.EasingStyle.Back), { Rotation = 0 }):Play()
        task.wait(0.2)

        -- 20% chance NoKey
        local isNoKeyWon = (math.random(1, 100) <= 20)

        if isNoKeyWon then
            chosenStroke.Color = Color3.fromRGB(34, 197, 94)
            chosenTitle.Text = "🎉 TRÚNG NOKEY!"
            chosenTitle.TextColor3 = Color3.fromRGB(74, 222, 128)
            chosenHint.Text = "VÀO SCRIPT NGAY"
            chosenHint.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
            GachaResultBanner.Text = "🎉 Chúc mừng! Đang tải script..."
            GachaResultBanner.TextColor3 = Color3.fromRGB(74, 222, 128)
            Save24hKey(GetSecondsUntilMidnightGMT7())
            task.wait(1.2)
            RemoveScreenLockdown()
            LaunchTargetScriptWithWatcher()
            TweenService:Create(MainScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { Scale = 0.8 }):Play()
            task.wait(0.2)
            ScreenGui:Destroy()
        else
            chosenStroke.Color = Color3.fromRGB(225, 29, 72)
            chosenTitle.Text = "🔑 LÀ HỘP GETKEY"
            chosenTitle.TextColor3 = Color3.fromRGB(251, 113, 133)
            chosenHint.Text = "QUAY VỀ LẤY KEY"
            chosenHint.BackgroundColor3 = Color3.fromRGB(159, 18, 57)
            GachaResultBanner.Text = "Hộp này là GetKey! Vui lòng vượt link để nhận key nhé."
            GachaResultBanner.TextColor3 = Color3.fromRGB(251, 113, 133)
            task.wait(1.5)
            CloseGachaModal()
            isRollingMutex = false
            StatusMsg.Text = "📌 Mở trúng GetKey! Bấm 'Lấy Key' để tiếp tục."
            StatusMsg.TextColor3 = Color3.fromRGB(251, 113, 133)
        end
    end

    Box1.MouseButton1Click:Connect(function()
        ExecuteBoxRoll(Box1, Box2, Box1Stroke, Box1Mask, Box1Title, Box1Hint)
    end)
    Box2.MouseButton1Click:Connect(function()
        ExecuteBoxRoll(Box2, Box1, Box2Stroke, Box2Mask, Box2Title, Box2Hint)
    end)

    QuickPasteBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(QuickPasteBtn)
        local pasted = false
        pcall(function()
            if getclipboard then InputBox.Text = getclipboard(); pasted = true
            elseif fromclipboard then InputBox.Text = fromclipboard(); pasted = true
            end
        end)
        if not pasted then InputBox:CaptureFocus() end
    end)

    local isTutorialDebounce = false
    TutorialBtn.MouseButton1Click:Connect(function()
        if isTutorialDebounce then return end
        isTutorialDebounce = true
        PlaySpringButton(TutorialBtn)
        pcall(function()
            if setclipboard then setclipboard(TutorialUrl)
            elseif toclipboard then toclipboard(TutorialUrl) end
        end)
        TutorialBtn.Text = "✔ Đã chép link HD"
        TutorialBtn.TextColor3 = Color3.fromRGB(52, 211, 153)
        StatusMsg.Text = Languages[CurrentLang].CopiedTutorial
        StatusMsg.TextColor3 = Color3.fromRGB(52, 211, 153)
        task.delay(2.2, function()
            if TutorialBtn and TutorialBtn.Parent then
                TutorialBtn.Text = Languages[CurrentLang].Tutorial
                TutorialBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
                StatusMsg.Text = "Chilli Hub V5 • Steal An Egg 🥚 • by OpenWonx"
                StatusMsg.TextColor3 = Color3.fromRGB(100, 116, 139)
            end
            isTutorialDebounce = false
        end)
    end)

    GetKeyBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(GetKeyBtn)
        pcall(function()
            if setclipboard then setclipboard(KeyUrl)
            elseif toclipboard then toclipboard(KeyUrl) end
        end)
        GetKeyBtn.Text = "✔ Đã Chép Link"
        GetKeyBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        StatusMsg.Text = Languages[CurrentLang].CopiedLink
        StatusMsg.TextColor3 = Color3.fromRGB(52, 211, 153)
        task.delay(2.2, function()
            if GetKeyBtn and GetKeyBtn.Parent then
                GetKeyBtn.Text = Languages[CurrentLang].GetKey
                GetKeyBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
                StatusMsg.Text = "Chilli Hub V5 • Steal An Egg 🥚 • by OpenWonx"
                StatusMsg.TextColor3 = Color3.fromRGB(100, 116, 139)
            end
        end)
    end)

    local isChecking = false
    CheckKeyBtn.MouseButton1Click:Connect(function()
        if isChecking then return end
        isChecking = true
        PlaySpringButton(CheckKeyBtn)
        CheckKeyBtn.Text = Languages[CurrentLang].Checking
        StatusMsg.Text = Languages[CurrentLang].CheckingMsg
        StatusMsg.TextColor3 = Color3.fromRGB(226, 232, 240)
        task.wait(0.3)
        -- PATCH: siempre true
        local isKeyValid = VerifyChilliV5Key(InputBox.Text)
        if isKeyValid then
            Save24hKey()
            CheckKeyBtn.Text = "✔ Thành Công"
            CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
            StatusMsg.Text = Languages[CurrentLang].Success
            StatusMsg.TextColor3 = Color3.fromRGB(74, 222, 128)
            RemoveScreenLockdown()
            LaunchTargetScriptWithWatcher()
            task.wait(0.35)
            TweenService:Create(MainScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { Scale = 0.8 }):Play()
            task.wait(0.2)
            ScreenGui:Destroy()
        else
            isChecking = false
            CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
            StatusMsg.Text = Languages[CurrentLang].Error
            StatusMsg.TextColor3 = Color3.fromRGB(244, 63, 94)
            InputStroke.Color = Color3.fromRGB(225, 29, 72)
            local origOffset = MainFrame.Position.X.Offset
            task.spawn(function()
                for _, off in ipairs({ -6, 6, -4, 4, -2, 2, 0 }) do
                    local t = TweenService:Create(MainFrame, TweenInfo.new(0.04, Enum.EasingStyle.Quad),
                        { Position = UDim2.new(0.5, off, 0.5, 0) })
                    t:Play(); t.Completed:Wait()
                end
                MainFrame.Position = UDim2.new(0.5, origOffset, 0.5, 0)
            end)
            task.wait(0.5)
            InputStroke.Color = Color3.fromRGB(42, 48, 62)
        end
    end)

    OpenLangBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(OpenLangBtn)
        CurrentLang = (CurrentLang == "VI") and "EN" or "VI"
        local data = Languages[CurrentLang]
        OpenLangBtn.Text = data.LangBtnText
        TitleLabel.Text = data.Title
        SubTitleLabel.Text = data.Subtitle
        CenterTitle.Text = data.CenterTitle
        CenterSub.Text = data.CenterSub
        InputBox.PlaceholderText = data.Placeholder
        QuickPasteBtn.Text = data.QuickPaste
        GetKeyBtn.Text = data.GetKey
        CheckKeyBtn.Text = data.CheckKey
        TutorialBtn.Text = data.Tutorial
        MiniGameBtn.Text = CanPlayGachaToday() and data.MiniGame or data.MiniGameLocked
        NoticeText.Text = data.Notice
    end)

    -- Animación de entrada
    MainFrame.BackgroundTransparency = 1
    MainScale.Scale = 0.85
    TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0 }):Play()
    TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Scale = 1.0 }):Play()
end

-- ============================================================
--  OPENWONX FINDER — INTEGRADO Y DESBLOQUEADO (ILIMITADO)
--  Finder gratuito sin restricciones, con anti-lag propio
-- ============================================================

-- Guard para evitar doble instancia del Finder
if not getgenv().OW_FinderLoaded then
    getgenv().OW_FinderLoaded = true

    local CFG = {
        BACKEND        = "https://calm-violet-3941.openwonx.workers.dev",
        WS_BACKEND     = "wss://calm-violet-3941.openwonx.workers.dev/api/ws",
        PLACE_ID       = 107778070777162,
        POLL_INTERVAL  = 3,
        FORCE_JOIN_CD  = 5,
        MAX_FINDINGS   = 50,
        C_BG           = Color3.fromRGB(30, 30, 30),
        C_HEADER       = Color3.fromRGB(220, 50, 50),
        C_ACCENT       = Color3.fromRGB(255, 180, 0),
        C_TEXT         = Color3.fromRGB(240, 240, 240),
        C_SUBTEXT      = Color3.fromRGB(160, 160, 160),
        C_CARD         = Color3.fromRGB(40, 40, 40),
        C_BTN_JOIN     = Color3.fromRGB(220, 160, 0),
        C_BTN_AUTO_ON  = Color3.fromRGB(50, 200, 80),
        C_BTN_AUTO_OFF = Color3.fromRGB(180, 40, 40),
    }

    local State = {
        PanelOpen  = false,
        AutoJoin   = false,
        MinValue   = 5e9,
        Rarity     = "Any",
        Findings   = {},
        LastJoin   = 0,
        ForceJoin  = 5,
        Connected  = false,
        WSActive   = false, -- guard de WebSocket
    }

    local function FormatValue(v)
        v = tonumber(v) or 0
        if v >= 1e18 then return string.format("$%.2fQa/s", v/1e18)
        elseif v >= 1e15 then return string.format("$%.2fT/s", v/1e15)
        elseif v >= 1e12 then return string.format("$%.2fT/s", v/1e12)
        elseif v >= 1e9  then return string.format("$%.2fB/s", v/1e9)
        elseif v >= 1e6  then return string.format("$%.2fM/s", v/1e6)
        else return string.format("$%.0f/s", v) end
    end

    local function TimeAgo(isoTs)
        local function parseISO(s)
            local y,mo,d,h,mi,se = s:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
            if not y then return os.time() end
            return os.time({year=tonumber(y),month=tonumber(mo),day=tonumber(d),
                            hour=tonumber(h),min=tonumber(mi),sec=tonumber(se)})
        end
        local diff = os.time() - parseISO(isoTs)
        if diff < 60 then return diff.."s ago"
        elseif diff < 3600 then return math.floor(diff/60).."m ago"
        else return math.floor(diff/3600).."h ago" end
    end

    -- HttpGet seguro (usa el original capturado)
    local function SafeHttpGet(url)
        local ok, res = pcall(function() return _ORIG_HTTPGET(game, url) end)
        return ok and res or nil
    end

    -- Limpiar Finder original de Chilli si existe
    task.spawn(function()
        task.wait(2)
        local containers = {CoreGui, LP:WaitForChild("PlayerGui", 5)}
        for _, cont in ipairs(containers) do
            if not cont then continue end
            for _, gui in ipairs(cont:GetChildren()) do
                if gui.Name ~= "OpenWonxFinder" then
                    pcall(function()
                        for _, child in ipairs(gui:GetDescendants()) do
                            if (child:IsA("TextButton") or child:IsA("TextLabel")) then
                                local t = child.Text or ""
                                if t:find("Finder") and not t:find("OpenWonx") then
                                    child.Visible = false
                                end
                            end
                        end
                    end)
                end
            end
        end
    end)

    -- ── Build UI del Finder ───────────────────────────────────
    -- Destruir instancia anterior si existe
    local oldFinder = CoreGui:FindFirstChild("OpenWonxFinder")
    if oldFinder then oldFinder:Destroy() end

    local FinderScreenGui = Instance.new("ScreenGui")
    FinderScreenGui.Name = "OpenWonxFinder"
    FinderScreenGui.ResetOnSpawn = false
    FinderScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    FinderScreenGui.DisplayOrder = 999
    pcall(function() FinderScreenGui.Parent = CoreGui end)
    if not FinderScreenGui.Parent then
        FinderScreenGui.Parent = LP:WaitForChild("PlayerGui")
    end

    -- Botón lateral Finder
    local FinderBtn = Instance.new("TextButton")
    FinderBtn.Name = "FinderBtn"
    FinderBtn.Size = UDim2.new(0, 100, 0, 36)
    FinderBtn.Position = UDim2.new(0, 8, 0, 230)
    FinderBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    FinderBtn.Text = "🔍 Finder"
    FinderBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    FinderBtn.TextSize = 13
    FinderBtn.Font = Enum.Font.GothamBold
    FinderBtn.AutoButtonColor = false
    FinderBtn.ZIndex = 1000
    FinderBtn.Parent = FinderScreenGui
    Instance.new("UICorner", FinderBtn).CornerRadius = UDim.new(0, 6)

    -- Panel principal
    local Panel = Instance.new("Frame")
    Panel.Name = "FinderPanel"
    Panel.Size = UDim2.new(0, 460, 1, -60)
    Panel.Position = UDim2.new(1, 0, 0, 30)
    Panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Panel.BorderSizePixel = 0
    Panel.ZIndex = 999
    Panel.Visible = false
    Panel.Parent = FinderScreenGui
    Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)

    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 44)
    Header.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    Header.BorderSizePixel = 0
    Header.ZIndex = 1000
    Header.Parent = Panel
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0.5, 0)
    HeaderFix.Position = UDim2.new(0, 0, 0.5, 0)
    HeaderFix.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    HeaderFix.BorderSizePixel = 0
    HeaderFix.ZIndex = 1000
    HeaderFix.Parent = Header

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size = UDim2.new(1, -50, 1, 0)
    TitleLbl.Position = UDim2.new(0, 10, 0, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text = "⚡ Chilli Finder  •  OpenWonx FREE"
    TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLbl.TextSize = 13
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.ZIndex = 1001
    TitleLbl.Parent = Header

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.new(0, 36, 0, 36)
    MinimizeBtn.Position = UDim2.new(1, -4, 0, -40)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    MinimizeBtn.Text = "▶"
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.TextSize = 14
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.AutoButtonColor = false
    MinimizeBtn.ZIndex = 1002
    MinimizeBtn.Parent = Panel
    Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)

    -- Controles
    local Controls = Instance.new("Frame")
    Controls.Size = UDim2.new(1, -16, 0, 44)
    Controls.Position = UDim2.new(0, 8, 0, 48)
    Controls.BackgroundTransparency = 1
    Controls.ZIndex = 1000
    Controls.Parent = Panel
    local UIList = Instance.new("UIListLayout")
    UIList.FillDirection = Enum.FillDirection.Horizontal
    UIList.Padding = UDim.new(0, 5)
    UIList.VerticalAlignment = Enum.VerticalAlignment.Center
    UIList.Parent = Controls

    local function MakeControlBtn(text, color, size)
        local btn = Instance.new("TextButton")
        btn.Size = size or UDim2.new(0, 76, 0, 32)
        btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 10
        btn.Font = Enum.Font.GothamBold
        btn.AutoButtonColor = false
        btn.ZIndex = 1001
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.Parent = Controls
        return btn
    end

    local AutoBtn      = MakeControlBtn("AUTO OFF", CFG.C_BTN_AUTO_OFF, UDim2.new(0, 76, 0, 32))
    local ForceJoinBtn = MakeControlBtn("FORCE JOIN\n"..State.ForceJoin.."s", Color3.fromRGB(50,180,50), UDim2.new(0, 76, 0, 32))
    local MinValBtn    = MakeControlBtn("MIN VALUE\n5B/s", Color3.fromRGB(0,120,200), UDim2.new(0, 76, 0, 32))
    local RarityBtn    = MakeControlBtn("RARITY\nAny", Color3.fromRGB(80,50,150), UDim2.new(0, 76, 0, 32))
    local AccountBtn   = MakeControlBtn("FREE ✓", Color3.fromRGB(50,180,80), UDim2.new(0, 76, 0, 32))
    AccountBtn.Active = false -- no hace nada, es badge

    local StatusLbl = Instance.new("TextLabel")
    StatusLbl.Size = UDim2.new(1, -16, 0, 18)
    StatusLbl.Position = UDim2.new(0, 8, 0, 95)
    StatusLbl.BackgroundTransparency = 1
    StatusLbl.Text = "⚡ Iniciando Finder OpenWonx..."
    StatusLbl.TextColor3 = CFG.C_SUBTEXT
    StatusLbl.TextSize = 10
    StatusLbl.Font = Enum.Font.Gotham
    StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
    StatusLbl.ZIndex = 1000
    StatusLbl.Parent = Panel

    -- ScrollFrame para findings
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -8, 1, -120)
    ScrollFrame.Position = UDim2.new(0, 4, 0, 115)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(220, 50, 50)
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollFrame.ZIndex = 1000
    ScrollFrame.Parent = Panel

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 4)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = ScrollFrame

    -- Bottom bar
    local BottomBar = Instance.new("Frame")
    BottomBar.Size = UDim2.new(1, 0, 0, 36)
    BottomBar.Position = UDim2.new(0, 0, 1, -36)
    BottomBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    BottomBar.BorderSizePixel = 0
    BottomBar.ZIndex = 1001
    BottomBar.Parent = Panel

    local BottomLbl = Instance.new("TextLabel")
    BottomLbl.Size = UDim2.new(0.7, 0, 1, 0)
    BottomLbl.BackgroundTransparency = 1
    BottomLbl.Text = "⚡ OpenWonx Finder FREE — Ilimitado"
    BottomLbl.TextColor3 = CFG.C_SUBTEXT
    BottomLbl.TextSize = 9.5
    BottomLbl.Font = Enum.Font.Gotham
    BottomLbl.TextXAlignment = Enum.TextXAlignment.Left
    BottomLbl.ZIndex = 1002
    BottomLbl.Parent = BottomBar

    local CopyLinkBtn = Instance.new("TextButton")
    CopyLinkBtn.Size = UDim2.new(0, 90, 0, 24)
    CopyLinkBtn.Position = UDim2.new(1, -98, 0.5, -12)
    CopyLinkBtn.BackgroundColor3 = Color3.fromRGB(220, 160, 0)
    CopyLinkBtn.Text = "Copy Link"
    CopyLinkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyLinkBtn.TextSize = 10
    CopyLinkBtn.Font = Enum.Font.GothamBold
    CopyLinkBtn.AutoButtonColor = false
    CopyLinkBtn.ZIndex = 1002
    CopyLinkBtn.Parent = BottomBar
    Instance.new("UICorner", CopyLinkBtn).CornerRadius = UDim.new(0, 6)

    -- ── Crear tarjeta de finding ──────────────────────────────
    local function MakeFindingCard(finding, index)
        local card = Instance.new("Frame")
        card.Name = "Card_"..(finding.finding_id or tostring(index))
        card.Size = UDim2.new(1, -8, 0, 68)
        card.BackgroundColor3 = CFG.C_CARD
        card.BorderSizePixel = 0
        card.LayoutOrder = index
        card.ZIndex = 1001
        card.Parent = ScrollFrame
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

        local rarityColors = {
            Divine   = Color3.fromRGB(180, 0, 220),
            Eternal  = Color3.fromRGB(0, 180, 220),
            Secret   = Color3.fromRGB(220, 160, 0),
            Legendary= Color3.fromRGB(220, 100, 0),
            Epic     = Color3.fromRGB(100, 0, 200),
            Rare     = Color3.fromRGB(0, 80, 220),
        }
        local stripe = Instance.new("Frame")
        stripe.Size = UDim2.new(0, 4, 1, 0)
        stripe.BackgroundColor3 = rarityColors[finding.rarity] or Color3.fromRGB(100,100,100)
        stripe.BorderSizePixel = 0
        stripe.ZIndex = 1002
        stripe.Parent = card
        Instance.new("UICorner", stripe).CornerRadius = UDim.new(0, 2)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -120, 0, 20)
        nameLbl.Position = UDim2.new(0, 14, 0, 6)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = "🥚 "..(finding.egg_name or "Unknown")
        nameLbl.TextColor3 = CFG.C_TEXT
        nameLbl.TextSize = 12
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.ZIndex = 1002
        nameLbl.Parent = card

        local rarityLbl = Instance.new("TextLabel")
        rarityLbl.Size = UDim2.new(0, 70, 0, 16)
        rarityLbl.Position = UDim2.new(0, 14, 0, 26)
        rarityLbl.BackgroundColor3 = rarityColors[finding.rarity] or Color3.fromRGB(80,80,80)
        rarityLbl.BackgroundTransparency = 0.3
        rarityLbl.Text = finding.rarity or "Unknown"
        rarityLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        rarityLbl.TextSize = 9
        rarityLbl.Font = Enum.Font.GothamBold
        rarityLbl.ZIndex = 1003
        rarityLbl.Parent = card
        Instance.new("UICorner", rarityLbl).CornerRadius = UDim.new(0, 4)

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(1, -120, 0, 16)
        valLbl.Position = UDim2.new(0, 14, 0, 44)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = FormatValue(finding.value_per_second)
            .." x"..string.format("%.2f", finding.multiplier or 1)
        valLbl.TextColor3 = CFG.C_ACCENT
        valLbl.TextSize = 11
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextXAlignment = Enum.TextXAlignment.Left
        valLbl.ZIndex = 1002
        valLbl.Parent = card

        local timeLbl = Instance.new("TextLabel")
        timeLbl.Size = UDim2.new(0, 80, 0, 16)
        timeLbl.Position = UDim2.new(0, 95, 0, 26)
        timeLbl.BackgroundTransparency = 1
        timeLbl.Text = TimeAgo(finding.detected_at or "")
        timeLbl.TextColor3 = CFG.C_SUBTEXT
        timeLbl.TextSize = 9.5
        timeLbl.Font = Enum.Font.Gotham
        timeLbl.ZIndex = 1002
        timeLbl.Parent = card

        local joinBtn = Instance.new("TextButton")
        joinBtn.Size = UDim2.new(0, 56, 0, 44)
        joinBtn.Position = UDim2.new(1, -64, 0, 12)
        joinBtn.BackgroundColor3 = CFG.C_BTN_JOIN
        joinBtn.Text = "Join"
        joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        joinBtn.TextSize = 12
        joinBtn.Font = Enum.Font.GothamBold
        joinBtn.AutoButtonColor = false
        joinBtn.ZIndex = 1003
        joinBtn.Parent = card
        Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)

        joinBtn.MouseButton1Click:Connect(function()
            if os.time() - State.LastJoin < State.ForceJoin then
                StatusLbl.Text = "⏳ Cooldown... "..(State.ForceJoin - (os.time()-State.LastJoin)).."s"
                return
            end
            State.LastJoin = os.time()
            joinBtn.Text = "..."
            joinBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

            -- Verificar disponibilidad del servidor
            task.spawn(function()
                local verifyUrl = CFG.BACKEND.."/api/verify?job_id="..(finding.job_id or "")
                    .."&place_id="..(finding.place_id or "")
                local verifyRaw = SafeHttpGet(verifyUrl)
                if verifyRaw then
                    local ok2, vdata = pcall(function() return HttpService:JSONDecode(verifyRaw) end)
                    if ok2 and vdata and vdata.available == false then
                        joinBtn.Text = "EXPIRED"
                        joinBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
                        StatusLbl.Text = "❌ Servidor offline"
                        return
                    end
                end

                local success, err = pcall(function()
                    TeleportService:TeleportToPlaceInstance(
                        tonumber(finding.place_id), finding.job_id, LP
                    )
                end)
                if success then
                    StatusLbl.Text = "🚀 Uniéndose..."
                    joinBtn.Text = "✈ OK"
                    joinBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
                else
                    joinBtn.Text = "ERR"
                    joinBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
                    StatusLbl.Text = "❌ Error: "..tostring(err):sub(1, 60)
                end
            end)
        end)

        -- Actualizar tiempo cada 10s
        task.spawn(function()
            while card.Parent do
                task.wait(10)
                pcall(function()
                    timeLbl.Text = TimeAgo(finding.detected_at or "")
                end)
            end
        end)

        return card
    end

    -- ── Render findings ───────────────────────────────────────
    local function RenderFindings()
        for _, child in ipairs(ScrollFrame:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        local filtered = {}
        for _, f in ipairs(State.Findings) do
            local val = tonumber(f.value_per_second) or 0
            local rarityOk = State.Rarity == "Any" or f.rarity == State.Rarity
            if val >= State.MinValue and rarityOk then
                table.insert(filtered, f)
            end
        end
        table.sort(filtered, function(a, b)
            return (tonumber(a.value_per_second) or 0) > (tonumber(b.value_per_second) or 0)
        end)
        for i, f in ipairs(filtered) do
            MakeFindingCard(f, i)
        end
        local count = #filtered
        StatusLbl.Text = "⚡ "..count.." finding"..(count~=1 and "s" or "")
            .." | Min: "..FormatValue(State.MinValue).." | "..State.Rarity
    end

    -- ── Fetch HTTP (fallback para executors sin WebSocket) ────
    local function FetchFindings()
        local url = CFG.BACKEND.."/api/findings?min_value="..State.MinValue
            .."&rarity="..State.Rarity.."&limit=50"
        local raw = SafeHttpGet(url)
        if not raw then return end
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if not ok or not data or not data.findings then return end
        State.Findings = data.findings
        RenderFindings()
    end

    -- ── WebSocket (si disponible) ─────────────────────────────
    local function StartWebSocketFeed()
        if State.WSActive then return end -- guard de doble inicio
        State.WSActive = true

        local wsOk = pcall(function()
            if not (typeof(WebSocket) == "table" or typeof(WebSocket) == "userdata") then
                error("no WebSocket")
            end
            local ws = WebSocket.connect(CFG.WS_BACKEND)
            State.Connected = true
            StatusLbl.Text = "🟢 Feed en tiempo real conectado"

            ws.OnMessage:Connect(function(msg)
                local ok, data = pcall(function() return HttpService:JSONDecode(msg) end)
                if not ok then return end
                if data.type == "finding" then
                    local f = data.data
                    local exists = false
                    for _, existing in ipairs(State.Findings) do
                        if existing.finding_id == f.finding_id then exists = true; break end
                    end
                    if not exists then
                        table.insert(State.Findings, 1, f)
                        while #State.Findings > CFG.MAX_FINDINGS do
                            table.remove(State.Findings)
                        end
                        if State.PanelOpen then RenderFindings() end
                        -- Auto Join
                        if State.AutoJoin then
                            local val = tonumber(f.value_per_second) or 0
                            local rarityOk = State.Rarity == "Any" or f.rarity == State.Rarity
                            if val >= State.MinValue and rarityOk then
                                if os.time() - State.LastJoin >= State.ForceJoin then
                                    State.LastJoin = os.time()
                                    pcall(function()
                                        TeleportService:TeleportToPlaceInstance(
                                            tonumber(f.place_id), f.job_id, LP
                                        )
                                    end)
                                end
                            end
                        end
                    end
                end
            end)

            ws.OnClose:Connect(function()
                State.Connected = false
                State.WSActive = false
                StatusLbl.Text = "🔴 Desconectado — reconectando..."
                task.delay(3, StartWebSocketFeed)
            end)

            -- Ping keepalive
            task.spawn(function()
                while State.Connected and getgenv().ChilliV5_Loaded do
                    task.wait(25)
                    pcall(function() ws:Send(HttpService:JSONEncode({type="ping"})) end)
                end
            end)
        end)

        if not wsOk then
            State.WSActive = false
            StatusLbl.Text = "📡 Polling HTTP (WebSocket no disponible)"
            task.spawn(function()
                while getgenv().ChilliV5_Loaded do
                    FetchFindings()
                    task.wait(CFG.POLL_INTERVAL)
                end
            end)
        end
    end

    -- ── Scout local ───────────────────────────────────────────
    local function StartLocalScout()
        task.spawn(function()
            while getgenv().ChilliV5_Loaded do
                pcall(function()
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if (obj:IsA("Model") or obj:IsA("Part"))
                            and obj.Name:lower():find("egg")
                            and not obj.Name:lower():find("basket")
                        then
                            local payload = HttpService:JSONEncode({
                                egg_name         = obj.Name,
                                location         = "Local Scout",
                                mutation         = "",
                                rarity           = "Unknown",
                                value_per_second = 0,
                                multiplier       = 1,
                                place_id         = tostring(CFG.PLACE_ID),
                                job_id           = game.JobId,
                                source           = "scout_local",
                                detected_at      = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                            })
                            pcall(function()
                                _ORIG_POSTASYNC(HttpService, CFG.BACKEND.."/api/finding",
                                    payload, Enum.HttpContentType.ApplicationJson)
                            end)
                        end
                    end
                end)
                task.wait(10)
            end
        end)
    end

    -- ── Toggle panel ──────────────────────────────────────────
    local function TogglePanel()
        State.PanelOpen = not State.PanelOpen
        Panel.Visible = true
        if State.PanelOpen then
            FinderBtn.Text = "🔍 Finder ✓"
            TweenService:Create(Panel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                { Position = UDim2.new(1, -468, 0, 30) }):Play()
            RenderFindings()
        else
            FinderBtn.Text = "🔍 Finder"
            local t = TweenService:Create(Panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { Position = UDim2.new(1, 0, 0, 30) })
            t:Play()
            t.Completed:Connect(function() Panel.Visible = false end)
        end
    end

    FinderBtn.MouseButton1Click:Connect(TogglePanel)
    MinimizeBtn.MouseButton1Click:Connect(TogglePanel)

    AutoBtn.MouseButton1Click:Connect(function()
        State.AutoJoin = not State.AutoJoin
        AutoBtn.Text = State.AutoJoin and "AUTO ON" or "AUTO OFF"
        AutoBtn.BackgroundColor3 = State.AutoJoin and CFG.C_BTN_AUTO_ON or CFG.C_BTN_AUTO_OFF
    end)

    local minValues = {1e9, 5e9, 10e9, 50e9, 100e9, 500e9, 1e12}
    local minIdx = 2
    MinValBtn.MouseButton1Click:Connect(function()
        minIdx = minIdx % #minValues + 1
        State.MinValue = minValues[minIdx]
        MinValBtn.Text = "MIN VALUE\n"..FormatValue(State.MinValue)
        RenderFindings()
    end)

    local rarities = {"Any","Secret","Eternal","Divine","Legendary","Epic","Rare"}
    local rarIdx = 1
    RarityBtn.MouseButton1Click:Connect(function()
        rarIdx = rarIdx % #rarities + 1
        State.Rarity = rarities[rarIdx]
        RarityBtn.Text = "RARITY\n"..State.Rarity
        RenderFindings()
    end)

    local fjValues = {3, 5, 10, 15, 30}
    local fjIdx = 2
    ForceJoinBtn.MouseButton1Click:Connect(function()
        fjIdx = fjIdx % #fjValues + 1
        State.ForceJoin = fjValues[fjIdx]
        ForceJoinBtn.Text = "FORCE JOIN\n"..State.ForceJoin.."s"
    end)

    CopyLinkBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then setclipboard(CFG.BACKEND)
            elseif toclipboard then toclipboard(CFG.BACKEND) end
        end)
        CopyLinkBtn.Text = "✔ Copied"
        task.delay(2, function()
            if CopyLinkBtn.Parent then CopyLinkBtn.Text = "Copy Link" end
        end)
    end)

    -- ── Arranque del Finder ───────────────────────────────────
    task.spawn(StartWebSocketFeed)
    task.spawn(StartLocalScout)
    task.delay(1, FetchFindings)
    StatusLbl.Text = "⚡ OpenWonx Finder FREE iniciando..."

end -- fin guard OW_FinderLoaded

-- ============================================================
--  FLUJO PRINCIPAL — ARRANQUE DIRECTO SIN KEY NI TRIAL
--  (KEY PATCH intacto, siempre válida)
-- ============================================================
local keyTimeLeft = GetKeyRemainingTime()
if keyTimeLeft and keyTimeLeft > 0 then
    ShowLiveToast("CHILLI HUB V5 • OPENWONX 🔓", keyTimeLeft, Color3.fromRGB(225, 29, 72))
    Save24hKey()
    task.spawn(function()
        LaunchTargetScriptWithWatcher()
    end)
end

print("[ChilliV5] ✓ Cargado — Anti-Lag ON | Finder FREE | Key Permanente")
