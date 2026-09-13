-- [[ ZYLOHUB OFFICIAL LOADER ]]
local HttpGet = game.HttpGet
local PlaceId = game.PlaceId
local GameId = game.GameId

-- Notifikasi awal di layar
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "ZyloHub",
        Text = "Mengecek game ID: " .. tostring(PlaceId) .. "...",
        Duration = 3
    })
end)

-- 1. Muat Settings (Versi & Discord)
pcall(function()
    loadstring(HttpGet(game, "https://raw.githubusercontent.com/ranklee26-glitch/zylohub/main/Settings.lua?t=" .. tostring(tick())))()
end)

-- 2. Muat GameList
local success, Games = pcall(function()
    return loadstring(HttpGet(game, "https://raw.githubusercontent.com/ranklee26-glitch/zylohub/main/GameList.lua?t=" .. tostring(tick())))()
end)

if not success or type(Games) ~= "table" then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "ZyloHub Error",
            Text = "Gagal memuat GameList!",
            Duration = 5
        })
    end)
    return
end

-- 3. Cari URL berdasarkan PlaceId atau GameId
local URL = Games[PlaceId] or Games[GameId]

if not URL then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "ZyloHub Info",
            Text = "Game ID (" .. tostring(PlaceId) .. ") belum terdaftar!",
            Duration = 5
        })
    end)
    return
end

-- 4. Jalankan Script Game Khusus
loadstring(HttpGet(game, URL .. "?t=" .. tostring(tick())))()
