--!strict
-- [[ ZYLOHUB OFFICIAL LOADER ]]
-- Professional Modular Game Loader

local HttpGet = game.HttpGet
local PlaceId: number = game.PlaceId

-- 1. Muat Informasi Settings / Versi / Discord
pcall(function()
    loadstring(HttpGet(game, "https://raw.githubusercontent.com/ranklee26-glitch/zylohub/main/Settings.lua"))()
end)

-- 2. Muat Router Daftar Game
local success, Games = pcall(function()
    return loadstring(HttpGet(game, "https://raw.githubusercontent.com/ranklee26-glitch/zylohub/main/GameList.lua"))()
end)

if not success or type(Games) ~= "table" then
    warn("[ZyloHub] Gagal memuat daftar GameList!")
    return
end

-- 3. Deteksi Game & Ambil URL Script
local URL: string? = Games[PlaceId]
if not URL then
    warn("[ZyloHub] Game ini (PlaceId: " .. tostring(PlaceId) .. ") belum didukung oleh ZyloHub!")
    return
end

-- 4. Jalankan Script Game Khusus
loadstring(HttpGet(game, URL))()
