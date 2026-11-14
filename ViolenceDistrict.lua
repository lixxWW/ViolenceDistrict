local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local BASE = "https://raw.githubusercontent.com/lixxWW/ViolenceDistrict/refs/heads/main/"
local VIOLENCE_DISTRICT_PLACE_IDS = {
    [93978595733734] = true,
    [9245727061]     = true,
}

local STORAGE_FOLDER = "gethypnosis.xyz"
local LAUNCHER_FILE = STORAGE_FOLDER .. "/Launcher.json"
local CONFIGS_FILE = STORAGE_FOLDER .. "/Configs.json"

local VD_VERSIONS = {
    {
        id = "v1.0.0",
        title = "v1.0.0",
        badge = "NEW",
        subtitle = "Latest release (updated) — active rework build",
        url = BASE .. "hypnosisrework.lua",
    },
    {
        id = "Legacy",
        title = "Legacy",
        badge = "CLASSIC",
        subtitle = "Old UI & more features — no longer updated",
        url = BASE .. "violencedistrict.lua",
    },
}

local SCRIPTS = {
    [93978595733734] = BASE .. "violencedistrict.lua",   -- Violence District (Legacy)
    [9245727061]     = BASE .. "violencedistrict.lua",   -- Violence District (Legacy)
    [97598239454123] = BASE .. "growagarden.lua",         -- Grow a Garden 2
    [77085202503540] = BASE .. "growagarden.lua",         -- Grow a Garden 2
    [142823291]      = BASE .. "murdermystery2.lua",     -- Murder Mystery 2
    [66654135]       = BASE .. "murdermystery2.lua",     -- Murder Mystery 2
    [10265440494]    = BASE .. "1981.lua",               -- 1981 (Main / Lobby)
    [72137289529544] = BASE .. "1981.lua",               -- 1981 (In-Game Match)
    [6137321701]     = BASE .. "blair.lua",              -- Blair
    [893973440]      = BASE .. "ftf.lua",                -- Flee the Facility
    [13772394625]    = BASE .. "bladeball.lua",          -- Blade Ball
}

local function resolveFs()
    local isf = isfolder or (syn and syn.isfolder)
    local mkf = makefolder or (syn and syn.makefolder)
    local isfl = isfile or (syn and syn.isfile)
    local rfl = readfile or (syn and syn.readfile)
    local wfl = writefile or (syn and syn.writefile)
    return isf, mkf, isfl, rfl, wfl
end

local function ensureStorageFolder()
    local isf, mkf = resolveFs()
    if not mkf then return end
    pcall(function()
        if isf then
            if not isf(STORAGE_FOLDER) then
                mkf(STORAGE_FOLDER)
            end
        else
            mkf(STORAGE_FOLDER)
        end
    end)
end

local function readJsonFile(path)
    local _, _, isfl, rfl = resolveFs()
    if not rfl or not isfl then return nil end
    local okExists, exists = pcall(isfl, path)
    if not okExists or not exists then return nil end
    local okRead, raw = pcall(rfl, path)
    if not okRead or type(raw) ~= "string" or #raw == 0 then return nil end
    local okParse, parsed = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if okParse and type(parsed) == "table" then
        return parsed
    end
    return nil
end

local function writeJsonFile(path, data)
    local _, _, _, _, wfl = resolveFs()
    if not wfl then return false end
    ensureStorageFolder()
    local ok = pcall(function()
        wfl(path, HttpService:JSONEncode(data))
    end)
    return ok
end

local function getVersionById(versionId)
    for i = 1, #VD_VERSIONS do
        if VD_VERSIONS[i].id == versionId then
            return VD_VERSIONS[i]
        end
    end
    return nil
end

local function downloadAndCompile(targetUrl)
    local stamp = tostring(math.floor((os.time and os.time()) or tick()))
    local nocacheUrl = targetUrl .. "?t=" .. stamp
    local ok, scriptContent = pcall(function()
        return game:HttpGet(nocacheUrl)
    end)
    if not ok or type(scriptContent) ~= "string" or #scriptContent == 0 then
        ok, scriptContent = pcall(function()
            return game:HttpGet(targetUrl)
        end)
    end
    if not ok or type(scriptContent) ~= "string" or #scriptContent == 0 then
        return nil, "Failed to download script from repository."
    end
    local fn, compileErr = loadstring(scriptContent)
    if not fn then
        return nil, "Compile error in target script: " .. tostring(compileErr)
    end
    return fn, nil
end

local function buildPalette()
    local w = Color3.fromRGB(12, 12, 12)
    local s = Color3.fromRGB(14, 14, 14)
    local b = Color3.fromRGB(20, 20, 20)
    local bd = Color3.fromRGB(28, 28, 28)
    local ac = Color3.fromRGB(255, 255, 255)
    local tm = Color3.fromRGB(255, 255, 255)
    local td = Color3.fromRGB(120, 120, 130)

    local savedConfigs = readJsonFile(CONFIGS_FILE)
    if savedConfigs and type(savedConfigs.Configs) == "table" then
        local activeName = savedConfigs.Active or "Default"
        local cfg = savedConfigs.Configs[activeName] or savedConfigs.Configs["Default"]
        if type(cfg) == "table" then
            local function pickRgb(key, fallback)
                local arr = cfg[key]
                if type(arr) == "table" and type(arr[1]) == "number" and type(arr[2]) == "number" and type(arr[3]) == "number" then
                    return Color3.new(arr[1], arr[2], arr[3])
                end
                return fallback
            end
            w  = pickRgb("UI_Color_WindowBg", w)
            s  = pickRgb("UI_Color_SidebarBg", s)
            b  = pickRgb("UI_Color_ButtonBg", b)
            bd = pickRgb("UI_Color_Border", bd)
            ac = pickRgb("UI_Color_Accent", ac)
            tm = pickRgb("UI_Color_TextMain", tm)
            td = pickRgb("UI_Color_TextDim", td)
        end
    end

    return {
        WindowBg     = w,
        SidebarBg    = s,
        ModuleBg     = s:Lerp(tm, 0.02),
        ButtonBg     = b,
        HoverBg      = b:Lerp(ac, 0.14),
        Divider      = s:Lerp(bd, 0.65),
        Border       = bd,
        BorderActive = bd:Lerp(ac, 0.25),
        Accent       = ac,
        TextActive   = tm,
        ButtonText   = tm:Lerp(td, 0.25),
        TextDim      = td,
        TextMuted    = td:Lerp(s, 0.08),
        KeybindText  = td:Lerp(s, 0.35),
        InputBg      = b:Lerp(w, 0.15),
        ErrorRed     = Color3.fromRGB(225, 78, 86),
    }
end

local function tweenProp(inst, props, duration, style, dir)
    local tw = TweenService:Create(
        inst,
        TweenInfo.new(duration or 0.14, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function resolveGuiParent()
    local targetParent = nil
    if typeof(gethui) == "function" then
        pcall(function() targetParent = gethui() end)
    end
    if not targetParent then
        pcall(function()
            local _ = CoreGui.Name
            targetParent = CoreGui
        end)
    end
    if not targetParent then
        local lp = Players.LocalPlayer or Players.PlayerAdded:Wait()
        targetParent = lp and (lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 15))
    end
    return targetParent
end

local function showVersionChooser(initialVersionId, initialRemember)
    local Palette = buildPalette()
    local guiParent = resolveGuiParent()
    if not guiParent then
        return nil, "Unable to locate UI container."
    end

    local staleGui = guiParent:FindFirstChild("HypnosisLauncherGui")
    if staleGui then
        pcall(function() staleGui:Destroy() end)
    end

    local selectedEntry = getVersionById(initialVersionId) or VD_VERSIONS[1]
    local rememberChecked = (initialRemember == true)
    local isBusy = false
    local isClosed = false
    local resolvedFn = nil
    local cancelReason = nil
    local connections = {}

    local doneSignal = Instance.new("BindableEvent")

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "HypnosisLauncherGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999999
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = guiParent

    local modalBtn = Instance.new("TextButton")
    modalBtn.Name = "LauncherModalUnlock"
    modalBtn.Size = UDim2.new(0, 1, 0, 1)
    modalBtn.BackgroundTransparency = 1
    modalBtn.BorderSizePixel = 0
    modalBtn.Text = ""
    modalBtn.AutoButtonColor = false
    modalBtn.Active = false
    modalBtn.Modal = true
    modalBtn.ZIndex = 1
    modalBtn.Visible = true
    modalBtn.Parent = ScreenGui

    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local winWidth = (isMobile or vp.X < 460) and math.clamp(vp.X - 24, 292, 344) or 354
    local winHeight = 264

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "LauncherFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, winWidth, 0, winHeight)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Palette.WindowBg
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 50
    MainFrame.Parent = ScreenGui

    local uiScale = Instance.new("UIScale", MainFrame)
    uiScale.Scale = 0.94

    local mainCorner = Instance.new("UICorner", MainFrame)
    mainCorner.CornerRadius = UDim.new(0, 8)

    local mainStroke = Instance.new("UIStroke", MainFrame)
    mainStroke.Color = Palette.Border
    mainStroke.Thickness = 1

    -- Top Header Bar (matches hypnosisrework.lua MainFrame header)
    local HeaderBar = Instance.new("Frame", MainFrame)
    HeaderBar.Name = "HeaderBar"
    HeaderBar.Size = UDim2.new(1, 0, 0, 34)
    HeaderBar.BackgroundTransparency = 1
    HeaderBar.ZIndex = 51

    local HeaderTitle = Instance.new("TextLabel", HeaderBar)
    HeaderTitle.Size = UDim2.new(0, 150, 1, 0)
    HeaderTitle.Position = UDim2.new(0, 14, 0, 0)
    HeaderTitle.BackgroundTransparency = 1
    HeaderTitle.Font = Enum.Font.GothamBold
    HeaderTitle.Text = "Hypnosis Launcher"
    HeaderTitle.TextColor3 = Palette.TextActive
    HeaderTitle.TextSize = 12
    HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    HeaderTitle.ZIndex = 52

    local Watermark = Instance.new("TextLabel", HeaderBar)
    Watermark.AnchorPoint = Vector2.new(1, 0.5)
    Watermark.Size = UDim2.new(0, 100, 0, 18)
    Watermark.Position = UDim2.new(1, -34, 0.5, 0)
    Watermark.BackgroundTransparency = 1
    Watermark.Font = Enum.Font.GothamMedium
    Watermark.Text = "gethypnosis.xyz"
    Watermark.TextColor3 = Palette.TextDim
    Watermark.TextSize = 9
    Watermark.TextXAlignment = Enum.TextXAlignment.Right
    Watermark.ZIndex = 52

    local CloseBtn = Instance.new("TextButton", HeaderBar)
    CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
    CloseBtn.Size = UDim2.new(0, 22, 0, 22)
    CloseBtn.Position = UDim2.new(1, -8, 0.5, 0)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.AutoButtonColor = false
    CloseBtn.Font = Enum.Font.GothamMedium
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Palette.TextMuted
    CloseBtn.TextSize = 14
    CloseBtn.ZIndex = 53

    -- Inner Card Container (matches UI.createCard)
    local Card = Instance.new("Frame", MainFrame)
    Card.Name = "LauncherCard"
    Card.Size = UDim2.new(1, -20, 1, -44)
    Card.Position = UDim2.new(0, 10, 0, 34)
    Card.BackgroundColor3 = Palette.SidebarBg
    Card.BorderSizePixel = 0
    Card.ZIndex = 51

    local cardCorner = Instance.new("UICorner", Card)
    cardCorner.CornerRadius = UDim.new(0, 3)

    local cardStroke = Instance.new("UIStroke", Card)
    cardStroke.Color = Palette.Border
    cardStroke.Thickness = 1

    local CardHeader = Instance.new("TextLabel", Card)
    CardHeader.Size = UDim2.new(0.55, 0, 0, 14)
    CardHeader.Position = UDim2.new(0, 12, 0, 10)
    CardHeader.BackgroundTransparency = 1
    CardHeader.Font = Enum.Font.GothamBold
    CardHeader.Text = "Select Build Version"
    CardHeader.TextColor3 = Palette.TextDim
    CardHeader.TextSize = 11
    CardHeader.TextXAlignment = Enum.TextXAlignment.Left
    CardHeader.ZIndex = 52

    local ShiftHint = Instance.new("TextLabel", Card)
    ShiftHint.AnchorPoint = Vector2.new(1, 0)
    ShiftHint.Size = UDim2.new(0.45, -12, 0, 14)
    ShiftHint.Position = UDim2.new(1, -12, 0, 10)
    ShiftHint.BackgroundTransparency = 1
    ShiftHint.Font = Enum.Font.GothamMedium
    ShiftHint.Text = "Hold Shift to reopen"
    ShiftHint.TextColor3 = Palette.KeybindText
    ShiftHint.TextSize = 9
    ShiftHint.TextXAlignment = Enum.TextXAlignment.Right
    ShiftHint.ZIndex = 52

    local Divider = Instance.new("Frame", Card)
    Divider.Size = UDim2.new(1, -24, 0, 1)
    Divider.Position = UDim2.new(0, 12, 0, 29)
    Divider.BackgroundColor3 = Palette.Divider
    Divider.BorderSizePixel = 0
    Divider.ZIndex = 52

    -- Version Option Rows
    local optionControls = {}
    local lastClickedId = nil
    local lastClickAt = 0

    local function getContrastCheckColor(bgColor)
        local lum = (0.299 * bgColor.R) + (0.587 * bgColor.G) + (0.114 * bgColor.B)
        return lum > 0.55 and Color3.fromRGB(12, 12, 12) or Color3.fromRGB(255, 255, 255)
    end

    local LaunchBtn = Instance.new("TextButton", Card)
    LaunchBtn.Name = "LaunchButton"
    LaunchBtn.Size = UDim2.new(1, -24, 0, 26)
    LaunchBtn.Position = UDim2.new(0, 12, 1, -38)
    LaunchBtn.BackgroundColor3 = Palette.ButtonBg
    LaunchBtn.BorderSizePixel = 0
    LaunchBtn.AutoButtonColor = false
    LaunchBtn.Font = Enum.Font.GothamMedium
    LaunchBtn.Text = "Launch " .. selectedEntry.title
    LaunchBtn.TextColor3 = Palette.TextActive
    LaunchBtn.TextSize = 11
    LaunchBtn.ZIndex = 53

    local lbCorner = Instance.new("UICorner", LaunchBtn)
    lbCorner.CornerRadius = UDim.new(0, 2)

    local lbStroke = Instance.new("UIStroke", LaunchBtn)
    lbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    lbStroke.Color = Palette.BorderActive
    lbStroke.Thickness = 1

    local StatusLbl = Instance.new("TextLabel", Card)
    StatusLbl.Size = UDim2.new(1, -24, 0, 12)
    StatusLbl.Position = UDim2.new(0, 12, 1, -12)
    StatusLbl.BackgroundTransparency = 1
    StatusLbl.Font = Enum.Font.GothamMedium
    StatusLbl.Text = ""
    StatusLbl.TextColor3 = Palette.ErrorRed
    StatusLbl.TextSize = 9
    StatusLbl.TextXAlignment = Enum.TextXAlignment.Center
    StatusLbl.TextTruncate = Enum.TextTruncate.AtEnd
    StatusLbl.ZIndex = 53

    local function updateSelectionVisuals(instant)
        for i = 1, #optionControls do
            local ctrl = optionControls[i]
            local isSel = (ctrl.entry.id == selectedEntry.id)
            local bgTarget = isSel and Palette.HoverBg or (ctrl.hovered and Palette.HoverBg:Lerp(Palette.ButtonBg, 0.45) or Palette.ButtonBg)
            local strokeTarget = isSel and Palette.BorderActive:Lerp(Palette.Accent, 0.55) or (ctrl.hovered and Palette.BorderActive or Palette.Border)
            local barTarget = isSel and Palette.Accent or Palette.Border
            local titleTarget = isSel and Palette.TextActive or Palette.ButtonText
            local badgeTarget = isSel and Palette.Accent or Palette.TextMuted
            local dotBgTarget = isSel and Palette.Accent or Palette.InputBg
            local dotStrokeTarget = isSel and Palette.Accent or Palette.Border

            if instant then
                ctrl.card.BackgroundColor3 = bgTarget
                ctrl.stroke.Color = strokeTarget
                ctrl.bar.BackgroundColor3 = barTarget
                ctrl.titleLbl.TextColor3 = titleTarget
                ctrl.badgeLbl.TextColor3 = badgeTarget
                ctrl.dot.BackgroundColor3 = dotBgTarget
                ctrl.dotStroke.Color = dotStrokeTarget
            else
                tweenProp(ctrl.card, { BackgroundColor3 = bgTarget }, 0.12)
                tweenProp(ctrl.stroke, { Color = strokeTarget }, 0.12)
                tweenProp(ctrl.bar, { BackgroundColor3 = barTarget }, 0.12)
                tweenProp(ctrl.titleLbl, { TextColor3 = titleTarget }, 0.12)
                tweenProp(ctrl.badgeLbl, { TextColor3 = badgeTarget }, 0.12)
                tweenProp(ctrl.dot, { BackgroundColor3 = dotBgTarget }, 0.12)
                tweenProp(ctrl.dotStroke, { Color = dotStrokeTarget }, 0.12)
            end
        end
        if not isBusy then
            LaunchBtn.Text = "Launch " .. selectedEntry.title
        end
    end

    local function submitLaunch()
        if isBusy or isClosed then return end
        isBusy = true
        StatusLbl.Text = ""
        LaunchBtn.Text = "Downloading " .. selectedEntry.title .. "..."
        tweenProp(LaunchBtn, { BackgroundColor3 = Palette.HoverBg }, 0.1)

        writeJsonFile(LAUNCHER_FILE, {
            version = selectedEntry.id,
            remember = rememberChecked,
            updatedAt = (os.time and os.time()) or math.floor(tick()),
        })

        task.spawn(function()
            local fn, errMsg = downloadAndCompile(selectedEntry.url)
            if isClosed then return end
            if fn then
                resolvedFn = fn
                isClosed = true
                modalBtn.Modal = false
                for i = 1, #connections do
                    pcall(function() connections[i]:Disconnect() end)
                end
                table.clear(connections)
                pcall(function()
                    tweenProp(uiScale, { Scale = 0.02 }, 0.11, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
                end)
                task.wait(0.11)
                pcall(function() ScreenGui:Destroy() end)
                doneSignal:Fire()
            else
                isBusy = false
                if ScreenGui.Parent and not isClosed then
                    LaunchBtn.Text = "Launch " .. selectedEntry.title
                    tweenProp(LaunchBtn, { BackgroundColor3 = Palette.ButtonBg }, 0.12)
                    StatusLbl.Text = tostring(errMsg or "Download failed. Retry.")
                end
            end
        end)
    end

    for idx = 1, #VD_VERSIONS do
        local entry = VD_VERSIONS[idx]
        local rowY = 38 + (idx - 1) * 56

        local optBtn = Instance.new("TextButton", Card)
        optBtn.Name = "Option_" .. entry.id
        optBtn.Size = UDim2.new(1, -24, 0, 48)
        optBtn.Position = UDim2.new(0, 12, 0, rowY)
        optBtn.BackgroundColor3 = Palette.ButtonBg
        optBtn.BorderSizePixel = 0
        optBtn.AutoButtonColor = false
        optBtn.Text = ""
        optBtn.ZIndex = 52

        local oCorner = Instance.new("UICorner", optBtn)
        oCorner.CornerRadius = UDim.new(0, 3)

        local oStroke = Instance.new("UIStroke", optBtn)
        oStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        oStroke.Color = Palette.Border
        oStroke.Thickness = 1

        local accentBar = Instance.new("Frame", optBtn)
        accentBar.AnchorPoint = Vector2.new(0, 0.5)
        accentBar.Size = UDim2.new(0, 3, 1, -14)
        accentBar.Position = UDim2.new(0, 8, 0.5, 0)
        accentBar.BackgroundColor3 = Palette.Border
        accentBar.BorderSizePixel = 0
        accentBar.ZIndex = 53
        local abCorner = Instance.new("UICorner", accentBar)
        abCorner.CornerRadius = UDim.new(1, 0)

        local titleLbl = Instance.new("TextLabel", optBtn)
        titleLbl.AnchorPoint = Vector2.new(0, 0.5)
        titleLbl.Size = UDim2.new(0, 120, 0, 16)
        titleLbl.Position = UDim2.new(0, 20, 0, 16)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.Text = entry.title
        titleLbl.TextColor3 = Palette.ButtonText
        titleLbl.TextSize = 11
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 53

        local badgeLbl = Instance.new("TextLabel", optBtn)
        badgeLbl.AnchorPoint = Vector2.new(1, 0.5)
        badgeLbl.Size = UDim2.new(0, 60, 0, 12)
        badgeLbl.Position = UDim2.new(1, -28, 0, 16)
        badgeLbl.BackgroundTransparency = 1
        badgeLbl.Font = Enum.Font.GothamBold
        badgeLbl.Text = entry.badge
        badgeLbl.TextColor3 = Palette.TextMuted
        badgeLbl.TextSize = 9
        badgeLbl.TextXAlignment = Enum.TextXAlignment.Right
        badgeLbl.ZIndex = 53

        local subLbl = Instance.new("TextLabel", optBtn)
        subLbl.Size = UDim2.new(1, -32, 0, 14)
        subLbl.Position = UDim2.new(0, 20, 0, 27)
        subLbl.BackgroundTransparency = 1
        subLbl.Font = Enum.Font.GothamMedium
        subLbl.Text = entry.subtitle
        subLbl.TextColor3 = Palette.TextMuted
        subLbl.TextSize = 9
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.TextTruncate = Enum.TextTruncate.AtEnd
        subLbl.ZIndex = 53

        local radioDot = Instance.new("Frame", optBtn)
        radioDot.AnchorPoint = Vector2.new(1, 0.5)
        radioDot.Size = UDim2.new(0, 10, 0, 10)
        radioDot.Position = UDim2.new(1, -12, 0, 16)
        radioDot.BackgroundColor3 = Palette.InputBg
        radioDot.BorderSizePixel = 0
        radioDot.ZIndex = 53
        local rdCorner = Instance.new("UICorner", radioDot)
        rdCorner.CornerRadius = UDim.new(1, 0)
        local rdStroke = Instance.new("UIStroke", radioDot)
        rdStroke.Color = Palette.Border
        rdStroke.Thickness = 1

        local ctrl = {
            entry = entry,
            card = optBtn,
            stroke = oStroke,
            bar = accentBar,
            titleLbl = titleLbl,
            badgeLbl = badgeLbl,
            dot = radioDot,
            dotStroke = rdStroke,
            hovered = false,
        }
        table.insert(optionControls, ctrl)

        table.insert(connections, optBtn.MouseEnter:Connect(function()
            ctrl.hovered = true
            updateSelectionVisuals(false)
        end))
        table.insert(connections, optBtn.MouseLeave:Connect(function()
            ctrl.hovered = false
            updateSelectionVisuals(false)
        end))
        table.insert(connections, optBtn.MouseButton1Click:Connect(function()
            if isBusy or isClosed then return end
            local now = os.clock()
            local isDouble = (lastClickedId == entry.id) and ((now - lastClickAt) <= 0.35)
            lastClickedId = entry.id
            lastClickAt = now
            selectedEntry = entry
            StatusLbl.Text = ""
            updateSelectionVisuals(false)
            if isDouble then
                submitLaunch()
            end
        end))
    end

    -- 'Remember Option' Checkbox Row
    local RememberRow = Instance.new("TextButton", Card)
    RememberRow.Name = "RememberOptionRow"
    RememberRow.Size = UDim2.new(1, -24, 0, 22)
    RememberRow.Position = UDim2.new(0, 12, 0, 152)
    RememberRow.BackgroundTransparency = 1
    RememberRow.AutoButtonColor = false
    RememberRow.Text = ""
    RememberRow.ZIndex = 52

    local CheckBox = Instance.new("Frame", RememberRow)
    CheckBox.AnchorPoint = Vector2.new(0, 0.5)
    CheckBox.Size = UDim2.new(0, 13, 0, 13)
    CheckBox.Position = UDim2.new(0, 0, 0.5, 0)
    CheckBox.BackgroundColor3 = Palette.InputBg
    CheckBox.BorderSizePixel = 0
    CheckBox.ZIndex = 53
    local cbCorner = Instance.new("UICorner", CheckBox)
    cbCorner.CornerRadius = UDim.new(0, 2)
    local cbStroke = Instance.new("UIStroke", CheckBox)
    cbStroke.Color = Palette.Border
    cbStroke.Thickness = 1

    local CheckMark = Instance.new("TextLabel", CheckBox)
    CheckMark.Size = UDim2.new(1, 0, 1, 0)
    CheckMark.BackgroundTransparency = 1
    CheckMark.Font = Enum.Font.GothamBold
    CheckMark.Text = "✓"
    CheckMark.TextColor3 = getContrastCheckColor(Palette.Accent)
    CheckMark.TextSize = 10
    CheckMark.TextTransparency = 1
    CheckMark.ZIndex = 54

    local RememberLbl = Instance.new("TextLabel", RememberRow)
    RememberLbl.Size = UDim2.new(0.6, 0, 1, 0)
    RememberLbl.Position = UDim2.new(0, 20, 0, 0)
    RememberLbl.BackgroundTransparency = 1
    RememberLbl.Font = Enum.Font.GothamMedium
    RememberLbl.Text = "Remember Option"
    RememberLbl.TextColor3 = Palette.ButtonText
    RememberLbl.TextSize = 10
    RememberLbl.TextXAlignment = Enum.TextXAlignment.Left
    RememberLbl.ZIndex = 53

    local RememberHint = Instance.new("TextLabel", RememberRow)
    RememberHint.AnchorPoint = Vector2.new(1, 0.5)
    RememberHint.Size = UDim2.new(0.4, -4, 1, 0)
    RememberHint.Position = UDim2.new(1, 0, 0.5, 0)
    RememberHint.BackgroundTransparency = 1
    RememberHint.Font = Enum.Font.GothamMedium
    RememberHint.Text = "Skip prompt next run"
    RememberHint.TextColor3 = Palette.KeybindText
    RememberHint.TextSize = 9
    RememberHint.TextXAlignment = Enum.TextXAlignment.Right
    RememberHint.ZIndex = 53

    local function updateRememberVisual(instant)
        local boxBg = rememberChecked and Palette.Accent or Palette.InputBg
        local boxStroke = rememberChecked and Palette.Accent or Palette.BorderActive
        local markTrans = rememberChecked and 0 or 1
        local textCol = rememberChecked and Palette.TextActive or Palette.ButtonText
        if instant then
            CheckBox.BackgroundColor3 = boxBg
            cbStroke.Color = boxStroke
            CheckMark.TextTransparency = markTrans
            RememberLbl.TextColor3 = textCol
        else
            tweenProp(CheckBox, { BackgroundColor3 = boxBg }, 0.12)
            tweenProp(cbStroke, { Color = boxStroke }, 0.12)
            tweenProp(CheckMark, { TextTransparency = markTrans }, 0.1)
            tweenProp(RememberLbl, { TextColor3 = textCol }, 0.12)
        end
    end

    table.insert(connections, RememberRow.MouseButton1Click:Connect(function()
        if isBusy or isClosed then return end
        rememberChecked = not rememberChecked
        updateRememberVisual(false)
    end))

    -- Launch Button Hover & Click
    table.insert(connections, LaunchBtn.MouseEnter:Connect(function()
        if not isBusy then
            tweenProp(LaunchBtn, { BackgroundColor3 = Palette.HoverBg }, 0.1)
            tweenProp(lbStroke, { Color = Palette.BorderActive:Lerp(Palette.Accent, 0.35) }, 0.1)
        end
    end))
    table.insert(connections, LaunchBtn.MouseLeave:Connect(function()
        if not isBusy then
            tweenProp(LaunchBtn, { BackgroundColor3 = Palette.ButtonBg }, 0.1)
            tweenProp(lbStroke, { Color = Palette.BorderActive }, 0.1)
        end
    end))
    table.insert(connections, LaunchBtn.MouseButton1Click:Connect(submitLaunch))

    local function closeLauncherCancelled()
        if isClosed or isBusy then return end
        isClosed = true
        modalBtn.Modal = false
        cancelReason = "Launch cancelled by user."
        for i = 1, #connections do
            pcall(function() connections[i]:Disconnect() end)
        end
        table.clear(connections)
        task.spawn(function()
            pcall(function()
                tweenProp(uiScale, { Scale = 0.02 }, 0.11, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
            end)
            task.wait(0.11)
            pcall(function() ScreenGui:Destroy() end)
            doneSignal:Fire()
        end)
    end

    table.insert(connections, CloseBtn.MouseEnter:Connect(function()
        tweenProp(CloseBtn, { TextColor3 = Palette.TextActive }, 0.1)
    end))
    table.insert(connections, CloseBtn.MouseLeave:Connect(function()
        tweenProp(CloseBtn, { TextColor3 = Palette.TextMuted }, 0.1)
    end))
    table.insert(connections, CloseBtn.MouseButton1Click:Connect(closeLauncherCancelled))

    -- Header Drag Support (Mouse & Touch)
    local isDragging = false
    local dragInput = nil
    local dragStartPos = nil
    local frameStartPos = nil

    table.insert(connections, HeaderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragInput = input
            dragStartPos = input.Position
            frameStartPos = MainFrame.Position
        end
    end))
    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if not isDragging then return end
        if input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStartPos
            MainFrame.Position = UDim2.new(
                frameStartPos.X.Scale,
                frameStartPos.X.Offset + delta.X,
                frameStartPos.Y.Scale,
                frameStartPos.Y.Offset + delta.Y
            )
        end
    end))
    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
            dragInput = nil
        end
    end))

    -- Keyboard Shortcuts (Enter launches, Escape closes)
    table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or isClosed then return end
        if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
            submitLaunch()
        elseif input.KeyCode == Enum.KeyCode.Escape then
            closeLauncherCancelled()
        end
    end))

    updateSelectionVisuals(true)
    updateRememberVisual(true)
    tweenProp(uiScale, { Scale = 1.0 }, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    doneSignal.Event:Wait()
    pcall(function() doneSignal:Destroy() end)
    return resolvedFn, cancelReason
end

-- ============================================================================
-- TARGET RESOLUTION & ENTRY POINT
-- ============================================================================
local placeId = game.PlaceId

if VIOLENCE_DISTRICT_PLACE_IDS[placeId] then
    local holdShift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
    local savedPref = readJsonFile(LAUNCHER_FILE)
    local savedEntry = savedPref and getVersionById(savedPref.version)

    if not holdShift and savedPref and savedPref.remember == true and savedEntry then
        print("[Hypnosis] Remembered version: " .. savedEntry.title .. ". Downloading...")
        local fn, errMsg = downloadAndCompile(savedEntry.url)
        if fn then
            print("[Hypnosis] Script loaded successfully. Executing...")
            fn()
            return
        end
        warn("[Hypnosis] Remembered launch failed (" .. tostring(errMsg) .. "). Opening launcher...")
    end

    local defaultVersionId = (savedEntry and savedEntry.id) or VD_VERSIONS[1].id
    local defaultRemember = (savedPref and savedPref.remember == true) or false
    local chosenFn, errReason = showVersionChooser(defaultVersionId, defaultRemember)
    if chosenFn then
        print("[Hypnosis] Script loaded successfully. Executing...")
        chosenFn()
    elseif errReason then
        print("[Hypnosis] " .. tostring(errReason))
    end
    return
end

local url = SCRIPTS[placeId]
if not url then
    if workspace:FindFirstChild("FavoriteRoomHighlightMock") then
        url = BASE .. "blair.lua"
        print("[Hypnosis] Game Detected: Blair")
    elseif workspace:FindFirstChild("Packanack Lodge") or workspace:FindFirstChild("InGameHousing") then
        url = BASE .. "1981.lua"
        print("[Hypnosis] Game Detected: 1981")
    elseif workspace:FindFirstChild("Balls") and (workspace:FindFirstChild("Alive") or workspace:FindFirstChild("Dead")) then
        url = BASE .. "bladeball.lua"
        print("[Hypnosis] Game Detected: Blade Ball")
    else
        local player = Players.LocalPlayer
        local coinBags = player and player:FindFirstChild("PlayerGui")
            and player.PlayerGui:FindFirstChild("MainGUI")
            and player.PlayerGui.MainGUI:FindFirstChild("Game")
            and player.PlayerGui.MainGUI.Game:FindFirstChild("CoinBags")

        if coinBags then
            url = BASE .. "murdermystery2.lua"
            print("[Hypnosis] Game Detected: Murder Mystery 2")
        else
            warn("[Hypnosis] No script found for PlaceId: " .. tostring(placeId))
            return
        end
    end
else
    print("[Hypnosis] Game Detected: " .. tostring(placeId))
end

print("[Hypnosis] Downloading script from ViolenceDistrict...")
local fn, errMsg = downloadAndCompile(url)
if not fn then
    warn("[Hypnosis] " .. tostring(errMsg))
    return
end

print("[Hypnosis] Script loaded successfully. Executing...")
fn()
