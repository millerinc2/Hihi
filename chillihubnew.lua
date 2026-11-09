-- =========================================================================
--   🌶️ CHILLI HUB V2 X RONNEI - STEAL AN EGG 🥚 (PHẦN 1/4)
--   Chilli Hub V2 · có ngôn ngữ tiếng việt · New
-- =========================================================================

local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local KeyUrl = "https://link4m.net/80x8y"
local TutorialUrl = "https://craftvip.github.io/free/getkey.html"
local TargetScriptUrl = "https://raw.githubusercontent.com/robvxs24/freemium/refs/heads/main/chillihubv2.lua"

local KeyFileName = "ChilliV2_KeyData.json"
local TrialFileName = "ChilliV2_TrialData.json"
local TRIAL_DURATION = 120 -- Thời hạn dùng thử đúng 2 phút (120 giây)

local InitialGuis = {}
local ScriptConnections = {}
local ActiveBlurEffect = nil
local InputBlockerScreen = nil
local OpenKeySystemUI = nil

-- MODULE MÃ HÓA BẢO MẬT DỮ LIỆU CỤC BỘ
local CIPHER_KEY = 127

local function EncryptData(str: string): string
    local hex = {}
    for i = 1, #str do
        table.insert(hex, string.format("%02X", bit32.bxor(string.byte(str, i), CIPHER_KEY)))
    end
    return table.concat(hex)
end

local function DecryptData(hexStr: string): string?
    local res = {}
    for i = 1, #hexStr, 2 do
        local b = tonumber(hexStr:sub(i, i + 1), 16)
        if not b then return nil end
        table.insert(res, string.char(bit32.bxor(b, CIPHER_KEY)))
    end
    return table.concat(res)
end

local function LoadTrialData()
    if isfile and readfile and isfile(TrialFileName) then
        local ok, raw = pcall(readfile, TrialFileName)
        if ok and raw and raw ~= "" then
            local dec = DecryptData(raw)
            if dec then
                local parseOk, data = pcall(function() return HttpService:JSONDecode(dec) end)
                if parseOk and type(data) == "table" and data.StartTime and data.LastSeen then
                    if os.time() < data.LastSeen then
                        return { StartTime = 0, LastSeen = os.time(), Tampered = true }
                    end
                    return data
                end
            end
        end
    end
    return nil
end

local function SaveTrialData(startTime: number, lastSeen: number?)
    if writefile then
        pcall(function()
            local data = { StartTime = startTime, LastSeen = lastSeen or os.time(), Duration = TRIAL_DURATION }
            writefile(TrialFileName, EncryptData(HttpService:JSONEncode(data)))
        end)
    end
end

local function GetKeyRemainingTime(): number?
    if isfile and readfile and isfile(KeyFileName) then
        local ok, content = pcall(readfile, KeyFileName)
        if ok and content and content ~= "" then
            local decOk, data = pcall(function() return HttpService:JSONDecode(content) end)
            if decOk and type(data) == "table" and data.ExpireTimestamp then
                local left = data.ExpireTimestamp - os.time()
                if left > 0 then return left end
            end
        end
    end
    return nil
end

local function Save24hKey()
    if writefile then
        pcall(function()
            writefile(KeyFileName, HttpService:JSONEncode({ ExpireTimestamp = os.time() + 86400 }))
        end)
    end
end

-- THUẬT TOÁN ĐỐI SOÁT KEY 24H (GMT+7)
local function VerifyChilliV2Key(rawInput: string): boolean
    if not rawInput or rawInput == "" then return false end
    local clean = string.lower(string.gsub(rawInput, "[%s%c]", ""))
    clean = clean:gsub("^chillihubv2%-", ""):gsub("^chilliv2%-", "")

    local vnTime = os.time() + (7 * 3600)
    local testTimes = { vnTime, vnTime - 86400, vnTime + 3600 }

    for _, t in ipairs(testTimes) do
        local d = os.date("!*t", t)
        local v1 = (d.day * 3617 + d.month * 2851 + d.year * 149) % 65535
        local v2 = (d.day * 6211 + d.month * 4397 + d.year * 269) % 65535
        local v3 = (d.day * 7919 + d.month * 6571 + d.year * 409) % 65535
        local target = string.format("%04x-%04x-%04x", v1, v2, v3)

        if clean == target then
            return true
        end
    end
    return false
end
-- =========================================================================
--   🌶️ CHILLI HUB V2 X RONNEI - STEAL AN EGG 🥚 (PHẦN 2/4)
--   SNAPSHOT UI · KHÓA MÀN HÌNH BẢO MẬT · VELVET LIVE HUD
-- =========================================================================

local function TakeGuiSnapshot()
    table.clear(InitialGuis)
    local containers = { CoreGui, LocalPlayer:FindFirstChild("PlayerGui") }
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
        ActiveBlurEffect.Name = "ChilliV2_LockdownBlur"
        ActiveBlurEffect.Size = 28
        ActiveBlurEffect.Parent = Lighting
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.PlatformStand = true
        end
        if hrp then
            hrp.Anchored = true
        end
    end

    if not InputBlockerScreen then
        InputBlockerScreen = Instance.new("ScreenGui")
        InputBlockerScreen.Name = "ChilliV2_InputBlocker"
        InputBlockerScreen.ResetOnSpawn = false
        pcall(function() InputBlockerScreen.Parent = CoreGui end)
        if not InputBlockerScreen.Parent then InputBlockerScreen.Parent = LocalPlayer:WaitForChild("PlayerGui") end

        local shield = Instance.new("TextButton")
        shield.Size = UDim2.new(1, 0, 1, 0)
        shield.Position = UDim2.new(0, 0, 0, 0)
        shield.BackgroundColor3 = Color3.fromRGB(10, 4, 7)
        shield.BackgroundTransparency = 0.45
        shield.Text = ""
        shield.AutoButtonColor = false
        shield.Active = true
        shield.ZIndex = 15
        shield.Parent = InputBlockerScreen
    end
end

local function RemoveScreenLockdown()
    if ActiveBlurEffect then
        ActiveBlurEffect:Destroy()
        ActiveBlurEffect = nil
    end
    if InputBlockerScreen then
        InputBlockerScreen:Destroy()
        InputBlockerScreen = nil
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.PlatformStand = false
        end
        if hrp then
            hrp.Anchored = false
        end
    end
end

local function TerminateTargetScript()
    getgenv().ChilliV2_Active = false
    getgenv().ChilliV2_TrialExpired = true

    for _, conn in ipairs(ScriptConnections) do
        if typeof(conn) == "RBXScriptConnection" and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(ScriptConnections)

    local containers = { CoreGui, LocalPlayer:FindFirstChild("PlayerGui") }
    for _, c in ipairs(containers) do
        if c then
            for _, child in ipairs(c:GetChildren()) do
                if not InitialGuis[child] and child.Name ~= "ChilliV2_GetKeyUI" and child.Name ~= "ChilliV2_ToastUI" and child.Name ~= "ChilliV2_InputBlocker" then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

local function LaunchTargetScriptWithWatcher()
    TakeGuiSnapshot()
    getgenv().ChilliV2_Active = true

    task.spawn(function()
        pcall(function()
            loadstring(game:HttpGet(TargetScriptUrl))()
        end)
    end)
end

local function FormatTime(seconds: number): string
    if seconds < 0 then seconds = 0 end
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%02d phút %02d giây", m, s)
end

local ActiveToastLabel = nil

local function ShowLiveToast(titleText: string, initialSeconds: number, color: Color3)
    if CoreGui:FindFirstChild("ChilliV2_ToastUI") then CoreGui.ChilliV2_ToastUI:Destroy() end
    if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("ChilliV2_ToastUI") then
        LocalPlayer.PlayerGui.ChilliV2_ToastUI:Destroy()
    end

    local ToastGui = Instance.new("ScreenGui")
    ToastGui.Name = "ChilliV2_ToastUI"
    ToastGui.ResetOnSpawn = false
    pcall(function() ToastGui.Parent = CoreGui end)
    if not ToastGui.Parent then ToastGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local ToastFrame = Instance.new("Frame")
    ToastFrame.Size = UDim2.new(0, 385, 0, 72)
    ToastFrame.Position = UDim2.new(0.5, -192, 0, -100)
    ToastFrame.BackgroundColor3 = Color3.fromRGB(16, 6, 10)
    ToastFrame.BorderSizePixel = 0
    ToastFrame.ZIndex = 50
    ToastFrame.Parent = ToastGui

    Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 16)
    local Stroke = Instance.new("UIStroke", ToastFrame)
    Stroke.Thickness = 1.4
    Stroke.Color = color or Color3.fromRGB(225, 75, 105)

    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 42, 1, 0)
    Icon.Position = UDim2.new(0, 10, 0, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = "🌶️"
    Icon.TextSize = 22
    Icon.ZIndex = 51
    Icon.Parent = ToastFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -65, 0, 20)
    Title.Position = UDim2.new(0, 52, 0, 12)
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.TextColor3 = color or Color3.fromRGB(250, 205, 218)
    Title.TextSize = 11.5
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 51
    Title.Parent = ToastFrame

    local Msg = Instance.new("TextLabel")
    Msg.Size = UDim2.new(1, -65, 0, 20)
    Msg.Position = UDim2.new(0, 52, 0, 32)
    Msg.BackgroundTransparency = 1
    Msg.Text = "Thời gian dùng thử: " .. FormatTime(initialSeconds)
    Msg.TextColor3 = Color3.fromRGB(240, 230, 235)
    Msg.TextSize = 11
    Msg.Font = Enum.Font.GothamMedium
    Msg.TextXAlignment = Enum.TextXAlignment.Left
    Msg.ZIndex = 51
    Msg.Parent = ToastFrame

    ActiveToastLabel = Msg

    local BarBg = Instance.new("Frame")
    BarBg.Size = UDim2.new(1, -24, 0, 3)
    BarBg.Position = UDim2.new(0, 12, 1, -6)
    BarBg.BackgroundColor3 = Color3.fromRGB(35, 10, 16)
    BarBg.BorderSizePixel = 0
    BarBg.ZIndex = 51
    BarBg.Parent = ToastFrame

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, 0, 1, 0)
    Bar.BackgroundColor3 = color or Color3.fromRGB(225, 75, 105)
    Bar.BorderSizePixel = 0
    Bar.ZIndex = 52
    Bar.Parent = BarBg

    TweenService:Create(ToastFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -192, 0, 24) }):Play()
    TweenService:Create(Bar, TweenInfo.new(10, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) }):Play()

    task.delay(10, function()
        if ToastFrame and ToastFrame.Parent then
            local t = TweenService:Create(ToastFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -192, 0, -100), BackgroundTransparency = 1 })
            t:Play()
            t.Completed:Connect(function()
                if ToastGui and ToastGui.Parent then ToastGui:Destroy() end
                ActiveToastLabel = nil
            end)
        end
    end)
end
-- =========================================================================
--   🌶️ CHILLI HUB V2 X RONNEI - STEAL AN EGG 🥚 (PHẦN 3/4)
--   NÚT HƯỚNG DẪN GETKEY RÕ RÀNG · KHUNG THẺ 425PX · DÁN NHANH QUICK-PASTE
-- =========================================================================

local Languages = {
    VI = {
        LangBtnText = "🇻🇳 VN ▾",
        SelectLangTitle = "🌶️ NGÔN NGỮ HỆ THỐNG / LANGUAGE",
        Title = "Chilli Hub V2 X Ronnei",
        Subtitle = "chilli hub v2 được việt hoá bởi ronnei7.htk",
        CenterTitle = "CHILLI HUB V2 × RONNEI",
        CenterSub = "Steal An Egg 🥚",
        Placeholder = "nhập key của bạn tại đây...",
        QuickPaste = "📋 Dán",
        GetKey = "⚡ LẤY KEY (24 TIẾNG)",
        CheckKey = "🔓 Xác Nhận",
        Tutorial = "📖 HƯỚNG DẪN CÁCH VƯỢT LINK LẤY KEY",
        Notice = "📌 Lưu ý: Link getkey 24 tiếng thao tác nhanh gọn (chỉ 1 phút vượt link). Mỗi key có hạn sử dụng đúng 24 giờ kể từ khi kích hoạt.",
        CopiedLink = "📋 ĐÃ SAO CHÉP LINK GETKEY 24 TIẾNG VÀO CLIPBOARD!",
        CopiedTutorial = "📖 ĐÃ SAO CHÉP LINK HƯỚNG DẪN VÀO CLIPBOARD!",
        Checking = "ĐANG XÁC THỰC...",
        CheckingMsg = "⏳ Đang đối soát chứng chỉ mã hóa trên máy chủ Chilli...",
        Success = "✔ Xác thực thành công! Đang khởi động Chilli Hub V2...",
        Error = "✖ Mã Key không chính xác hoặc phiên 24 giờ đã hết hạn!"
    },
    EN = {
        LangBtnText = "🇺🇸 EN ▾",
        SelectLangTitle = "🌶️ SELECT SYSTEM LANGUAGE",
        Title = "Chilli Hub V2 X Ronnei",
        Subtitle = "chilli hub v2 được tạo bởi ronnei7.htk",
        CenterTitle = "CHILLI HUB V2 × RONNEI",
        CenterSub = "Steal An Egg 🥚",
        Placeholder = "Paste Your key is here...",
        QuickPaste = "📋 Paste",
        GetKey = "⚡ GET KEY (24 HOURS)",
        CheckKey = "🔓 Confirm",
        Tutorial = "📖 HOW TO BYPASS LINK & GET KEY TUTORIAL",
        Notice = "📌 Notice: 24-hour key link is fast and easy (takes only 1 min). Each key remains fully valid for exactly 24 hours.",
        CopiedLink = "📋 24-HOUR KEY LINK COPIED TO CLIPBOARD!",
        CopiedTutorial = "📖 TUTORIAL LINK COPIED TO CLIPBOARD!",
        Checking = "AUTHENTICATING...",
        CheckingMsg = "⏳ Verifying Velvet Ruby credentials with Chilli server...",
        Success = "✔ Authorization granted! Launching Chilli Hub V2...",
        Error = "✖ Invalid key or expired 24-hour license!"
    }
}
local CurrentLang = "VI"

local function PlaySpringButton(btn: TextButton)
    local origSize = btn.Size
    local origPos = btn.Position
    local shrinkSize = UDim2.new(origSize.X.Scale, origSize.X.Offset - 4, origSize.Y.Scale, origSize.Y.Offset - 3)
    local shrinkPos = UDim2.new(origPos.X.Scale, origPos.X.Offset + 2, origPos.Y.Scale, origPos.Y.Offset + 1.5)

    local t1 = TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = shrinkSize, Position = shrinkPos })
    local t2 = TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = origSize, Position = origPos })
    t1:Play()
    t1.Completed:Connect(function() t2:Play() end)
end

OpenKeySystemUI = function()
    if CoreGui:FindFirstChild("ChilliV2_GetKeyUI") then CoreGui.ChilliV2_GetKeyUI:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ChilliV2_GetKeyUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- Mở rộng kích thước chiều cao lên 425px để tạo khoảng cách thông thoáng
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, 440, 0, 425)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 6, 9)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 30
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 22)

    local MainScale = Instance.new("UIScale", MainFrame)
    MainScale.Scale = 0.5

    -- Viền nhịp thở Velvet Rose tự động hóa bằng C++ Tween
    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Thickness = 1.4
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Color = Color3.fromRGB(225, 65, 95)

    local breatheTween = TweenService:Create(MainStroke, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Color = Color3.fromRGB(160, 40, 65)
    })
    breatheTween:Play()

    -- HEADER TOP BAR
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Size = UDim2.new(1, -24, 0, 42)
    HeaderBar.Position = UDim2.new(0, 12, 0, 10)
    HeaderBar.BackgroundTransparency = 1
    HeaderBar.ZIndex = 31
    HeaderBar.Parent = MainFrame

    local MiniLogo = Instance.new("Frame")
    MiniLogo.Size = UDim2.new(0, 28, 0, 28)
    MiniLogo.Position = UDim2.new(0, 0, 0.5, -14)
    MiniLogo.BackgroundColor3 = Color3.fromRGB(28, 9, 14)
    MiniLogo.ZIndex = 32
    MiniLogo.Parent = HeaderBar
    Instance.new("UICorner", MiniLogo).CornerRadius = UDim.new(1, 0)
    local MiniLogoStroke = Instance.new("UIStroke", MiniLogo)
    MiniLogoStroke.Color = Color3.fromRGB(220, 68, 98)
    MiniLogoStroke.Thickness = 1.2

    local MiniLogoTxt = Instance.new("TextLabel")
    MiniLogoTxt.Size = UDim2.new(1, 0, 1, 0)
    MiniLogoTxt.BackgroundTransparency = 1
    MiniLogoTxt.Text = "🌶️"
    MiniLogoTxt.TextSize = 13
    MiniLogoTxt.ZIndex = 33
    MiniLogoTxt.Parent = MiniLogo

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -115, 0, 18)
    TitleLabel.Position = UDim2.new(0, 36, 0, 2)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Languages[CurrentLang].Title
    TitleLabel.TextColor3 = Color3.fromRGB(250, 235, 238)
    TitleLabel.TextSize = 12
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 32
    TitleLabel.Parent = HeaderBar

    local SubTitleLabel = Instance.new("TextLabel")
    SubTitleLabel.Size = UDim2.new(1, -115, 0, 16)
    SubTitleLabel.Position = UDim2.new(0, 36, 0, 20)
    SubTitleLabel.BackgroundTransparency = 1
    SubTitleLabel.Text = Languages[CurrentLang].Subtitle
    SubTitleLabel.TextColor3 = Color3.fromRGB(235, 148, 170)
    SubTitleLabel.TextSize = 10
    SubTitleLabel.Font = Enum.Font.GothamMedium
    SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubTitleLabel.ZIndex = 32
    SubTitleLabel.Parent = HeaderBar

    local OpenLangBtn = Instance.new("TextButton")
    OpenLangBtn.Size = UDim2.new(0, 76, 0, 26)
    OpenLangBtn.Position = UDim2.new(1, -76, 0.5, -13)
    OpenLangBtn.BackgroundColor3 = Color3.fromRGB(26, 8, 13)
    OpenLangBtn.Text = Languages[CurrentLang].LangBtnText
    OpenLangBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
    OpenLangBtn.TextSize = 10.5
    OpenLangBtn.Font = Enum.Font.GothamBold
    OpenLangBtn.AutoButtonColor = false
    OpenLangBtn.ZIndex = 32
    OpenLangBtn.Parent = HeaderBar
    Instance.new("UICorner", OpenLangBtn).CornerRadius = UDim.new(0, 8)
    local LangStroke = Instance.new("UIStroke", OpenLangBtn)
    LangStroke.Color = Color3.fromRGB(180, 50, 75)
    LangStroke.Thickness = 1

    -- LOGO TRUNG TÂM PHÙ ĐIÊU THẠCH ANH
    local CenterLogoBox = Instance.new("Frame")
    CenterLogoBox.Size = UDim2.new(0, 54, 0, 54)
    CenterLogoBox.Position = UDim2.new(0.5, -27, 0, 48)
    CenterLogoBox.BackgroundColor3 = Color3.fromRGB(24, 7, 12)
    CenterLogoBox.ZIndex = 31
    CenterLogoBox.Parent = MainFrame
    Instance.new("UICorner", CenterLogoBox).CornerRadius = UDim.new(0, 16)
    local CenterLogoStroke = Instance.new("UIStroke", CenterLogoBox)
    CenterLogoStroke.Color = Color3.fromRGB(220, 68, 98)
    CenterLogoStroke.Thickness = 1.2

    local CenterLogoTxt = Instance.new("TextLabel")
    CenterLogoTxt.Size = UDim2.new(1, 0, 1, 0)
    CenterLogoTxt.BackgroundTransparency = 1
    CenterLogoTxt.Text = "🥚"
    CenterLogoTxt.TextSize = 26
    CenterLogoTxt.ZIndex = 32
    CenterLogoTxt.Parent = CenterLogoBox

    local CenterTitle = Instance.new("TextLabel")
    CenterTitle.Size = UDim2.new(1, -30, 0, 20)
    CenterTitle.Position = UDim2.new(0, 15, 0, 108)
    CenterTitle.BackgroundTransparency = 1
    CenterTitle.Text = Languages[CurrentLang].CenterTitle
    CenterTitle.TextColor3 = Color3.fromRGB(252, 242, 245)
    CenterTitle.TextSize = 13.5
    CenterTitle.Font = Enum.Font.GothamBold
    CenterTitle.ZIndex = 31
    CenterTitle.Parent = MainFrame

    local CenterSub = Instance.new("TextLabel")
    CenterSub.Size = UDim2.new(1, -30, 0, 16)
    CenterSub.Position = UDim2.new(0, 15, 0, 128)
    CenterSub.BackgroundTransparency = 1
    CenterSub.Text = Languages[CurrentLang].CenterSub
    CenterSub.TextColor3 = Color3.fromRGB(235, 148, 170)
    CenterSub.TextSize = 10
    CenterSub.Font = Enum.Font.GothamMedium
    CenterSub.ZIndex = 31
    CenterSub.Parent = MainFrame

    -- KHUNG NHẬP LIỆU THÔNG MINH
    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, -36, 0, 38)
    InputContainer.Position = UDim2.new(0, 18, 0, 150)
    InputContainer.BackgroundColor3 = Color3.fromRGB(22, 7, 12)
    InputContainer.ZIndex = 31
    InputContainer.Parent = MainFrame
    Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 10)
    local InputStroke = Instance.new("UIStroke", InputContainer)
    InputStroke.Color = Color3.fromRGB(60, 18, 28)

    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(1, -75, 1, 0)
    InputBox.Position = UDim2.new(0, 10, 0, 0)
    InputBox.BackgroundTransparency = 1
    InputBox.TextColor3 = Color3.fromRGB(248, 235, 238)
    InputBox.PlaceholderColor3 = Color3.fromRGB(135, 75, 90)
    InputBox.PlaceholderText = Languages[CurrentLang].Placeholder
    InputBox.Text = ""
    InputBox.TextSize = 11.5
    InputBox.Font = Enum.Font.GothamMedium
    InputBox.TextXAlignment = Enum.TextXAlignment.Left
    InputBox.ClearTextOnFocus = false
    InputBox.ZIndex = 32
    InputBox.Parent = InputContainer

    -- NÚT DÁN NHANH QUICK-PASTE
    local QuickPasteBtn = Instance.new("TextButton")
    QuickPasteBtn.Size = UDim2.new(0, 56, 0, 26)
    QuickPasteBtn.Position = UDim2.new(1, -62, 0.5, -13)
    QuickPasteBtn.BackgroundColor3 = Color3.fromRGB(34, 10, 17)
    QuickPasteBtn.Text = Languages[CurrentLang].QuickPaste
    QuickPasteBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
    QuickPasteBtn.TextSize = 10.5
    QuickPasteBtn.Font = Enum.Font.GothamBold
    QuickPasteBtn.AutoButtonColor = false
    QuickPasteBtn.ZIndex = 33
    QuickPasteBtn.Parent = InputContainer
    Instance.new("UICorner", QuickPasteBtn).CornerRadius = UDim.new(0, 7)
    local QuickPasteStroke = Instance.new("UIStroke", QuickPasteBtn)
    QuickPasteStroke.Color = Color3.fromRGB(160, 45, 65)
    QuickPasteStroke.Thickness = 1

    -- HÀNG NÚT CHÍNH: LẤY KEY (24 TIẾNG) & KÍCH HOẠT V2
    local ButtonsRow = Instance.new("Frame")
    ButtonsRow.Size = UDim2.new(1, -36, 0, 40)
    ButtonsRow.Position = UDim2.new(0, 18, 0, 194)
    ButtonsRow.BackgroundTransparency = 1
    ButtonsRow.ZIndex = 31
    ButtonsRow.Parent = MainFrame

    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(0.5, -6, 1, 0)
    GetKeyBtn.Position = UDim2.new(0, 0, 0, 0)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(215, 60, 90)
    GetKeyBtn.Text = Languages[CurrentLang].GetKey
    GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GetKeyBtn.TextSize = 11.5
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.AutoButtonColor = false
    GetKeyBtn.ZIndex = 32
    GetKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 10)
    local GetKeyStroke = Instance.new("UIStroke", GetKeyBtn)
    GetKeyStroke.Color = Color3.fromRGB(240, 95, 125)

    local CheckKeyBtn = Instance.new("TextButton")
    CheckKeyBtn.Size = UDim2.new(0.5, -6, 1, 0)
    CheckKeyBtn.Position = UDim2.new(0.5, 6, 0, 0)
    CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(26, 8, 14)
    CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
    CheckKeyBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
    CheckKeyBtn.TextSize = 11.5
    CheckKeyBtn.Font = Enum.Font.GothamBold
    CheckKeyBtn.AutoButtonColor = false
    CheckKeyBtn.ZIndex = 32
    CheckKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", CheckKeyBtn).CornerRadius = UDim.new(0, 10)
    local CheckStroke = Instance.new("UIStroke", CheckKeyBtn)
    CheckStroke.Color = Color3.fromRGB(180, 50, 75)
    CheckStroke.Thickness = 1.2

    -- NÚT HƯỚNG DẪN GETKEY CHUYÊN NGHIỆP (MÀU KÍNH VELVET MỜ ĐẸP MẮT)
    local TutorialBtn = Instance.new("TextButton")
    TutorialBtn.Size = UDim2.new(1, -36, 0, 36)
    TutorialBtn.Position = UDim2.new(0, 18, 0, 240)
    TutorialBtn.BackgroundColor3 = Color3.fromRGB(24, 8, 14)
    TutorialBtn.Text = Languages[CurrentLang].Tutorial
    TutorialBtn.TextColor3 = Color3.fromRGB(255, 180, 200)
    TutorialBtn.TextSize = 11
    TutorialBtn.Font = Enum.Font.GothamBold
    TutorialBtn.AutoButtonColor = false
    TutorialBtn.ZIndex = 32
    TutorialBtn.Parent = MainFrame
    Instance.new("UICorner", TutorialBtn).CornerRadius = UDim.new(0, 10)
    local TutorialStroke = Instance.new("UIStroke", TutorialBtn)
    TutorialStroke.Color = Color3.fromRGB(145, 45, 65)
    TutorialStroke.Thickness = 1.2

    -- BẢNG THÔNG BÁO LƯU Ý
    local NoticeCard = Instance.new("Frame")
    NoticeCard.Size = UDim2.new(1, -36, 0, 68)
    NoticeCard.Position = UDim2.new(0, 18, 0, 284)
    NoticeCard.BackgroundColor3 = Color3.fromRGB(20, 6, 11)
    NoticeCard.ZIndex = 31
    NoticeCard.Parent = MainFrame
    Instance.new("UICorner", NoticeCard).CornerRadius = UDim.new(0, 10)
    local NoticeStroke = Instance.new("UIStroke", NoticeCard)
    NoticeStroke.Color = Color3.fromRGB(50, 14, 22)

    local NoticeText = Instance.new("TextLabel")
    NoticeText.Size = UDim2.new(1, -16, 1, -10)
    NoticeText.Position = UDim2.new(0, 8, 0, 5)
    NoticeText.BackgroundTransparency = 1
    NoticeText.Text = Languages[CurrentLang].Notice
    NoticeText.TextColor3 = Color3.fromRGB(245, 215, 222)
    NoticeText.TextSize = 10.5
    NoticeText.Font = Enum.Font.GothamMedium
    NoticeText.TextWrapped = true
    NoticeText.TextYAlignment = Enum.TextYAlignment.Center
    NoticeText.TextXAlignment = Enum.TextXAlignment.Left
    NoticeText.ZIndex = 32
    NoticeText.Parent = NoticeCard

    local StatusMsg = Instance.new("TextLabel")
    StatusMsg.Size = UDim2.new(1, -36, 0, 22)
    StatusMsg.Position = UDim2.new(0, 18, 0, 362)
    StatusMsg.BackgroundTransparency = 1
    StatusMsg.Text = "Chilli Hub V2 X Ronnei · Security Protocol Active"
    StatusMsg.TextColor3 = Color3.fromRGB(145, 80, 95)
    StatusMsg.TextSize = 9.5
    StatusMsg.Font = Enum.Font.GothamMedium
    StatusMsg.ZIndex = 31
    StatusMsg.Parent = MainFrame
    -- =========================================================================
--   🌶️ CHILLI HUB V2 X RONNEI - STEAL AN EGG 🥚 (PHẦN 4/4)
--   SỰ KIỆN NÚT HƯỚNG DẪN · ANIMATION SAO CHÉP · ĐẾM NGƯỢC DÙNG THỬ 2 PHÚT
-- =========================================================================

    local function PlayShakeEffect()
        local origOffset = MainFrame.Position.X.Offset
        local offsets = { -8, 8, -6, 6, -3, 3, 0 }
        task.spawn(function()
            for _, off in ipairs(offsets) do
                local t = TweenService:Create(MainFrame, TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0.5, off, 0.5, 0)
                })
                t:Play()
                t.Completed:Wait()
            end
            MainFrame.Position = UDim2.new(0.5, origOffset, 0.5, 0)
        end)
    end

    QuickPasteBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(QuickPasteBtn)
        local pasted = false
        pcall(function()
            if getclipboard then
                InputBox.Text = getclipboard()
                pasted = true
            elseif fromclipboard then
                InputBox.Text = fromclipboard()
                pasted = true
            end
        end)
        if not pasted then
            InputBox:CaptureFocus()
        end
    end)

    -- MODAL CHỌN NGÔN NGỮ
    local LangModal = Instance.new("Frame")
    LangModal.Name = "LangModal"
    LangModal.Size = UDim2.new(1, 0, 1, 0)
    LangModal.Position = UDim2.new(0, 0, 1, 0)
    LangModal.BackgroundColor3 = Color3.fromRGB(12, 4, 7)
    LangModal.BackgroundTransparency = 0.02
    LangModal.ZIndex = 40
    LangModal.Parent = MainFrame
    Instance.new("UICorner", LangModal).CornerRadius = UDim.new(0, 22)

    local ModalTitle = Instance.new("TextLabel")
    ModalTitle.Size = UDim2.new(1, -60, 0, 30)
    ModalTitle.Position = UDim2.new(0, 20, 0, 18)
    ModalTitle.BackgroundTransparency = 1
    ModalTitle.Text = Languages[CurrentLang].SelectLangTitle
    ModalTitle.TextColor3 = Color3.fromRGB(220, 68, 98)
    ModalTitle.TextSize = 12
    ModalTitle.Font = Enum.Font.GothamBold
    ModalTitle.TextXAlignment = Enum.TextXAlignment.Left
    ModalTitle.ZIndex = 41
    ModalTitle.Parent = LangModal

    local CloseModalBtn = Instance.new("TextButton")
    CloseModalBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseModalBtn.Position = UDim2.new(1, -40, 0, 18)
    CloseModalBtn.BackgroundColor3 = Color3.fromRGB(28, 8, 14)
    CloseModalBtn.Text = "✕"
    CloseModalBtn.TextColor3 = Color3.fromRGB(220, 68, 98)
    CloseModalBtn.TextSize = 12
    CloseModalBtn.Font = Enum.Font.GothamBold
    CloseModalBtn.ZIndex = 41
    CloseModalBtn.Parent = LangModal
    Instance.new("UICorner", CloseModalBtn).CornerRadius = UDim.new(0, 6)

    local LangList = Instance.new("Frame")
    LangList.Size = UDim2.new(1, -40, 0, 150)
    LangList.Position = UDim2.new(0, 20, 0, 65)
    LangList.BackgroundTransparency = 1
    LangList.ZIndex = 41
    LangList.Parent = LangModal

    local OptViBtn = Instance.new("TextButton")
    OptViBtn.Size = UDim2.new(1, 0, 0, 56)
    OptViBtn.BackgroundColor3 = Color3.fromRGB(28, 8, 14)
    OptViBtn.Text = "🇻🇳  Tiếng Việt (Vietnamese)  ✓"
    OptViBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
    OptViBtn.TextSize = 13
    OptViBtn.Font = Enum.Font.GothamBold
    OptViBtn.ZIndex = 42
    OptViBtn.AutoButtonColor = false
    OptViBtn.Parent = LangList
    Instance.new("UICorner", OptViBtn).CornerRadius = UDim.new(0, 12)
    local OptViStroke = Instance.new("UIStroke", OptViBtn)
    OptViStroke.Color = Color3.fromRGB(220, 68, 98)
    OptViStroke.Thickness = 1.3

    local OptEnBtn = Instance.new("TextButton")
    OptEnBtn.Size = UDim2.new(1, 0, 0, 56)
    OptEnBtn.Position = UDim2.new(0, 0, 0, 68)
    OptEnBtn.BackgroundColor3 = Color3.fromRGB(18, 5, 9)
    OptEnBtn.Text = "🇺🇸  English (Global)"
    OptEnBtn.TextColor3 = Color3.fromRGB(156, 163, 175)
    OptEnBtn.TextSize = 13
    OptEnBtn.Font = Enum.Font.GothamMedium
    OptEnBtn.ZIndex = 42
    OptEnBtn.AutoButtonColor = false
    OptEnBtn.Parent = LangList
    Instance.new("UICorner", OptEnBtn).CornerRadius = UDim.new(0, 12)
    local OptEnStroke = Instance.new("UIStroke", OptEnBtn)
    OptEnStroke.Color = Color3.fromRGB(50, 14, 22)

    local function SetLanguage(code: string)
        CurrentLang = code
        local data = Languages[code]
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
        NoticeText.Text = data.Notice
        ModalTitle.Text = data.SelectLangTitle

        if code == "VI" then
            OptViBtn.Text = "🇻🇳  Tiếng Việt (Vietnamese)  ✓"
            OptViBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
            OptViBtn.Font = Enum.Font.GothamBold
            OptViStroke.Color = Color3.fromRGB(220, 68, 98)
            OptViBtn.BackgroundColor3 = Color3.fromRGB(28, 8, 14)

            OptEnBtn.Text = "🇺🇸  English (Global)"
            OptEnBtn.TextColor3 = Color3.fromRGB(156, 163, 175)
            OptEnBtn.Font = Enum.Font.GothamMedium
            OptEnStroke.Color = Color3.fromRGB(50, 14, 22)
            OptEnBtn.BackgroundColor3 = Color3.fromRGB(18, 5, 9)
        else
            OptEnBtn.Text = "🇺🇸  English (Global)  ✓"
            OptEnBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
            OptEnBtn.Font = Enum.Font.GothamBold
            OptEnStroke.Color = Color3.fromRGB(220, 68, 98)
            OptEnBtn.BackgroundColor3 = Color3.fromRGB(28, 8, 14)

            OptViBtn.Text = "🇻🇳  Tiếng Việt (Vietnamese)"
            OptViBtn.TextColor3 = Color3.fromRGB(156, 163, 175)
            OptViBtn.Font = Enum.Font.GothamMedium
            OptViStroke.Color = Color3.fromRGB(50, 14, 22)
            OptViBtn.BackgroundColor3 = Color3.fromRGB(18, 5, 9)
        end
    end

    local function OpenLangModal()
        TweenService:Create(LangModal, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
    end
    local function CloseLangModal()
        TweenService:Create(LangModal, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Position = UDim2.new(0, 0, 1, 0) }):Play()
    end

    OpenLangBtn.MouseButton1Click:Connect(function() PlaySpringButton(OpenLangBtn); OpenLangModal() end)
    CloseModalBtn.MouseButton1Click:Connect(function() PlaySpringButton(CloseModalBtn); CloseLangModal() end)
    OptViBtn.MouseButton1Click:Connect(function() PlaySpringButton(OptViBtn); SetLanguage("VI"); task.wait(0.15); CloseLangModal() end)
    OptEnBtn.MouseButton1Click:Connect(function() PlaySpringButton(OptEnBtn); SetLanguage("EN"); task.wait(0.15); CloseLangModal() end)

    MainFrame.BackgroundTransparency = 1
    MainScale.Scale = 0.4
    TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(MainScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    -- SỰ KIỆN BẤM LẤY KEY (24 TIẾNG)
    GetKeyBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(GetKeyBtn)
        if setclipboard then setclipboard(KeyUrl) elseif toclipboard then toclipboard(KeyUrl) end

        GetKeyBtn.Text = "COPIED LINK (24H)!"
        GetKeyBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        GetKeyStroke.Color = Color3.fromRGB(52, 211, 153)
        StatusMsg.Text = Languages[CurrentLang].CopiedLink
        StatusMsg.TextColor3 = Color3.fromRGB(52, 211, 153)

        task.delay(2.5, function()
            if GetKeyBtn and GetKeyBtn.Parent then
                GetKeyBtn.Text = Languages[CurrentLang].GetKey
                GetKeyBtn.BackgroundColor3 = Color3.fromRGB(215, 60, 90)
                GetKeyStroke.Color = Color3.fromRGB(240, 95, 125)
                StatusMsg.Text = "Chilli Hub V2 X Ronnei · Security Protocol Active"
                StatusMsg.TextColor3 = Color3.fromRGB(145, 80, 95)
            end
        end)
    end)

    -- SỰ KIỆN BẤM NÚT HƯỚNG DẪN CÁCH VƯỢT LINK GETKEY
    local isTutorialDebounce = false
    TutorialBtn.MouseButton1Click:Connect(function()
        if isTutorialDebounce then return end
        isTutorialDebounce = true
        PlaySpringButton(TutorialBtn)

        if setclipboard then setclipboard(TutorialUrl) elseif toclipboard then toclipboard(TutorialUrl) end

        TutorialBtn.Text = "📖 ĐÃ SAO CHÉP LINK HƯỚNG DẪN!"
        TutorialBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        TutorialStroke.Color = Color3.fromRGB(52, 211, 153)
        StatusMsg.Text = Languages[CurrentLang].CopiedTutorial
        StatusMsg.TextColor3 = Color3.fromRGB(52, 211, 153)

        task.delay(2.5, function()
            if TutorialBtn and TutorialBtn.Parent then
                TutorialBtn.Text = Languages[CurrentLang].Tutorial
                TutorialBtn.BackgroundColor3 = Color3.fromRGB(24, 8, 14)
                TutorialStroke.Color = Color3.fromRGB(145, 45, 65)
                StatusMsg.Text = "Chilli Hub V2 X Ronnei · Security Protocol Active"
                StatusMsg.TextColor3 = Color3.fromRGB(145, 80, 95)
            end
            isTutorialDebounce = false
        end)
    end)

    -- SỰ KIỆN BẤM KÍCH HOẠT V2
    local isChecking = false
    CheckKeyBtn.MouseButton1Click:Connect(function()
        if isChecking then return end
        isChecking = true
        PlaySpringButton(CheckKeyBtn)

        CheckKeyBtn.Text = Languages[CurrentLang].Checking
        StatusMsg.Text = Languages[CurrentLang].CheckingMsg
        StatusMsg.TextColor3 = Color3.fromRGB(245, 195, 210)

        task.wait(0.35)
        local isKeyValid = VerifyChilliV2Key(InputBox.Text)

        if isKeyValid then
            Save24hKey()
            CheckKeyBtn.Text = "SUCCESS"
            CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(22, 101, 52)
            CheckStroke.Color = Color3.fromRGB(74, 222, 128)
            StatusMsg.Text = Languages[CurrentLang].Success
            StatusMsg.TextColor3 = Color3.fromRGB(74, 222, 128)

            RemoveScreenLockdown()
            LaunchTargetScriptWithWatcher()

            task.wait(0.4)
            TweenService:Create(MainScale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.5 }):Play()
            task.wait(0.25)
            ScreenGui:Destroy()
        else
            isChecking = false
            CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
            StatusMsg.Text = Languages[CurrentLang].Error
            StatusMsg.TextColor3 = Color3.fromRGB(239, 68, 68)

            InputStroke.Color = Color3.fromRGB(220, 68, 98)
            PlayShakeEffect()
            task.wait(0.6)
            InputStroke.Color = Color3.fromRGB(60, 18, 28)
        end
    end)
end

-- =========================================================================
--   LUỒNG CHÍNH: DÙNG THỬ 2 PHÚT & BẢO MẬT KHÓA MÀN HÌNH TỰ ĐỘNG
-- =========================================================================

local keyTimeLeft = GetKeyRemainingTime()
if keyTimeLeft and keyTimeLeft > 0 then
    ShowLiveToast("CHILLI HUB V2 X RONNEI (24H)", keyTimeLeft, Color3.fromRGB(220, 68, 98))
    LaunchTargetScriptWithWatcher()
    return
end

local trialData = LoadTrialData()

if not trialData then
    trialData = { StartTime = os.time(), LastSeen = os.time() }
    SaveTrialData(trialData.StartTime, trialData.LastSeen)
end

if trialData.Tampered then
    ApplyScreenLockdown()
    ShowLiveToast("⚠ SECURITY: TAMPER DETECTED", 0, Color3.fromRGB(239, 68, 68))
    OpenKeySystemUI()
    return
end

local targetEndTime = trialData.StartTime + TRIAL_DURATION
local remaining = targetEndTime - os.time()

if remaining <= 0 then
    ApplyScreenLockdown()
    ShowLiveToast("⚠️ HẾT THỜI GIAN DÙNG THỬ (2 PHÚT)", 0, Color3.fromRGB(220, 68, 98))
    OpenKeySystemUI()
    return
else
    ShowLiveToast("CHILLI HUB V2 X RONNEI (2 PHÚT)", remaining, Color3.fromRGB(220, 68, 98))
    LaunchTargetScriptWithWatcher()

    task.spawn(function()
        local saveInterval = 0

        while true do
            task.wait(1)
            local currentRemaining = targetEndTime - os.time()

            if ActiveToastLabel and ActiveToastLabel.Parent then
                ActiveToastLabel.Text = "Thời gian dùng thử: " .. FormatTime(currentRemaining)
            end

            saveInterval = saveInterval + 1
            if saveInterval >= 10 then -- Ghi đĩa 10 giây/lần chống giật lag
                saveInterval = 0
                SaveTrialData(trialData.StartTime, os.time())
            end

            if GetKeyRemainingTime() then return end

            if currentRemaining <= 0 then
                SaveTrialData(trialData.StartTime, os.time())
                TerminateTargetScript()
                ApplyScreenLockdown()
                ShowLiveToast("⚠️ HẾT THỜI GIAN DÙNG THỬ (2 PHÚT)", 0, Color3.fromRGB(220, 68, 98))
                task.wait(0.3)
                OpenKeySystemUI()
                break
            end
        end
    end)
end
