local BASE = "https://raw.githubusercontent.com/lixxWW/ViolenceDistrict/refs/heads/main/"

local SCRIPTS = {
    [93978595733734] = BASE .. "violencedistrict.lua",   -- Violence District
    [97598239454123] = BASE .. "growagarden.lua",         -- Grow a Garden 2 (Old)
    [77085202503540] = BASE .. "growagarden.lua",         -- Grow a Garden 2 (New)
    [142823291]      = BASE .. "murdermystery2.lua",     -- Murder Mystery 2
    [66654135]       = BASE .. "murdermystery2.lua",     -- Murder Mystery 2 Trade Plaza
}

local placeId = game.PlaceId
local url     = SCRIPTS[placeId]

if not url then
    local player = game:GetService("Players").LocalPlayer
    local coinBags = player and player:FindFirstChild("PlayerGui")
        and player.PlayerGui:FindFirstChild("MainGUI")
        and player.PlayerGui.MainGUI:FindFirstChild("Game")
        and player.PlayerGui.MainGUI.Game:FindFirstChild("CoinBags")
    
    if coinBags then
        url = BASE .. "murdermystery2.lua"
        print("[Loader] Game detected via CoinBags (Murder Mystery 2)")
    else
        warn("[Loader] No script found for PlaceId: " .. tostring(placeId))
        return
    end
else
    print("[Loader] Game detected: " .. tostring(placeId))
end

print("[Loader] Downloading script from ViolenceDistrict...")

local nocacheUrl = url .. "?t=" .. tostring(math.floor(os.time() or tick()))
local ok, scriptContent = pcall(function()
    return game:HttpGet(nocacheUrl)
end)

if not ok or not scriptContent or #scriptContent == 0 then
    ok, scriptContent = pcall(function()
        return game:HttpGet(url)
    end)
end

if not ok or not scriptContent or #scriptContent == 0 then
    warn("[Loader] Failed to download script from repository.")
    return
end

local fn, err = loadstring(scriptContent)
if not fn then
    warn("[Loader] Compile error in target script: " .. tostring(err))
    return
end

print("[Loader] Script loaded successfully. Executing...")
fn()
