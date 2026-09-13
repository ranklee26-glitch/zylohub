-- [[ ZYLOHUB - GROW A GARDEN V1.0.0 ]]
-- Official Script Module for Grow a Garden
-- Protected Features: Auto Farm, Auto Place Egg (PetEggService), 13 Egg Locations

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

-- Safe UI Parent
local function getSafeUIParent()
    local success, pgui = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui", 5)
    end)
    if success and pgui then return pgui end
    return CoreGui
end

-- Notification System
local function Notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title or "ZyloHub",
            Text = text or "",
            Duration = duration or 3
        })
    end)
end

-- ====================================================================
-- SISTEM AUTO FARM & AUTO PLACE EGG (KODE RESMI TERKUNCI)
-- ====================================================================
local Settings = {
    AutoFarm = false,
    AutoPlant = false,
    AutoHarvest = false,
    AutoSell = false,
    SelectedSeed = "Carrot Seed",
    FarmDelay = 0.1,
    
    AutoEgg = false,
    SelectedEgg = "Common Egg",
    EggLocations = 13,
    EggDelay = 0.5
}

-- 13 Titik Lokasi Resmi Telur
local EggCFrameList = {
    CFrame.new(72.7, 3.5, -9.1),
    CFrame.new(72.7, 3.5, -5.9),
    CFrame.new(72.7, 3.5, -2.7),
    CFrame.new(72.7, 3.5, 0.5),
    CFrame.new(72.7, 3.5, 3.7),
    CFrame.new(72.7, 3.5, 6.9),
    CFrame.new(72.7, 3.5, 10.1),
    CFrame.new(72.7, 3.5, 13.3),
    CFrame.new(72.7, 3.5, 16.5),
    CFrame.new(72.7, 3.5, 19.7),
    CFrame.new(72.7, 3.5, 22.9),
    CFrame.new(72.7, 3.5, 26.1),
    CFrame.new(72.7, 3.5, 29.3)
}

-- PetEggService Remote
local function getPetEggService()
    local service = ReplicatedStorage:FindFirstChild("PetEggService") or 
                    ReplicatedStorage:FindFirstChild("PetService") or
                    ReplicatedStorage:FindFirstChild("EggService")
    return service
end

-- Thread Auto Place Egg (Resmi 13 Titik)
task.spawn(function()
    while true do
        if Settings.AutoEgg then
            local service = getPetEggService()
            local eggName = Settings.SelectedEgg
            
            for i = 1, math.min(#EggCFrameList, Settings.EggLocations) do
                if not Settings.AutoEgg then break end
                local targetCF = EggCFrameList[i]
                
                pcall(function()
                    if service then
                        local placeRemote = service:FindFirstChild("PlaceEgg") or 
                                            service:FindFirstChild("Place") or
                                            service:FindFirstChild("BuyAndPlace")
                        if placeRemote and placeRemote:IsA("RemoteEvent") then
                            placeRemote:FireServer(eggName, targetCF)
                        elseif placeRemote and placeRemote:IsA("RemoteFunction") then
                            placeRemote:InvokeServer(eggName, targetCF)
                        end
                    end
                end)
                task.wait(Settings.EggDelay)
            end
        end
        task.wait(0.5)
    end
end)

-- Thread Auto Farm (Harvest & Plant)
task.spawn(function()
    while true do
        if Settings.AutoFarm then
            pcall(function()
                -- Auto Harvest Check
                if Settings.AutoHarvest then
                    local garden = workspace:FindFirstChild("Gardens") or workspace:FindFirstChild("Farm")
                    if garden then
                        for _, obj in pairs(garden:GetDescendants()) do
                            if not Settings.AutoFarm then break end
                            if obj:IsA("ProximityPrompt") and obj.Enabled then
                                fireproximityprompt(obj)
                                task.wait(Settings.FarmDelay)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ====================================================================
-- PEMBUATAN GUI ZYLOHUB (MODULAR & REGISTER AMAN)
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZyloHub_GAG"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getSafeUIParent()

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 340)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -170)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 10)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(0, 170, 255)
UIStroke.Thickness = 1.5

-- TopBar
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
TopBar.BorderSizePixel = 0

local TopBarCorner = Instance.new("UICorner", TopBar)
TopBarCorner.CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "ZYLO HUB <font color=\"#00aaff\">[Grow a Garden]</font>"
Title.RichText = true
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
local CloseCorner = Instance.new("UICorner", CloseBtn)
CloseCorner.CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = not ScreenGui.Enabled
end)

-- Sidebar Navigation
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 130, 1, -45)
Sidebar.Position = UDim2.new(0, 8, 0, 42)
Sidebar.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
Sidebar.BorderSizePixel = 0
local SideCorner = Instance.new("UICorner", Sidebar)
SideCorner.CornerRadius = UDim.new(0, 8)

local SideLayout = Instance.new("UIListLayout", Sidebar)
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Padding = UDim.new(0, 6)
local SidePad = Instance.new("UIPadding", Sidebar)
SidePad.PaddingTop = UDim.new(0, 8)
SidePad.PaddingLeft = UDim.new(0, 6)
SidePad.PaddingRight = UDim.new(0, 6)

-- Container Pages
local Container = Instance.new("Frame", MainFrame)
Container.Size = UDim2.new(1, -155, 1, -45)
Container.Position = UDim2.new(0, 145, 0, 42)
Container.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
Container.BorderSizePixel = 0
local ContCorner = Instance.new("UICorner", Container)
ContCorner.CornerRadius = UDim.new(0, 8)

-- Tab Management
local Tabs = {}
local TabButtons = {}

local function SwitchTab(tabName)
    for name, page in pairs(Tabs) do
        page.Visible = (name == tabName)
    end
    for name, btn in pairs(TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Color3.fromRGB(0, 140, 230)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
            btn.TextColor3 = Color3.fromRGB(170, 175, 190)
        end
    end
end

local function CreateTabButton(name, order)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(170, 175, 190)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.LayoutOrder = order
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)
    TabButtons[name] = btn
    return btn
end

local function CreatePage(name)
    local page = Instance.new("ScrollingFrame", Container)
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.Visible = false
    
    local layout = Instance.new("UIListLayout", page)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    
    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    
    Tabs[name] = page
    return page
end

-- ====================================================================
-- MODULAR TAB BUILDERS (DIBUNGKUS AGAR REGISTER LOKAL AMAN & LEGA)
-- ====================================================================

-- 1. TAB FARM
do
    CreateTabButton("🌾 Farm", 1)
    local page = CreatePage("🌾 Farm")
    
    local function createToggle(parent, text, default, callback)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 36)
        frame.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
        local cr = Instance.new("UICorner", frame)
        cr.CornerRadius = UDim.new(0, 6)
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(230, 230, 230)
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 50, 0, 24)
        btn.Position = UDim2.new(1, -60, 0.5, -12)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(50, 55, 70)
        btn.Text = default and "ON" or "OFF"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        local bcr = Instance.new("UICorner", btn)
        bcr.CornerRadius = UDim.new(0, 5)
        
        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = state and "ON" or "OFF"
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(50, 55, 70)
            callback(state)
        end)
    end
    
    createToggle(page, "Auto Farm (Semua)", Settings.AutoFarm, function(v)
        Settings.AutoFarm = v
        Notify("Farm", "Auto Farm: " .. (v and "Aktif" or "Mati"), 2)
    end)
    
    createToggle(page, "Auto Harvest Tanaman", Settings.AutoHarvest, function(v)
        Settings.AutoHarvest = v
    end)
end

-- 2. TAB PETS & EGGS (Fitur Resmi 13 Titik)
do
    CreateTabButton("🥚 Pet & Egg", 2)
    local page = CreatePage("🥚 Pet & Egg")
    
    local function createToggle(parent, text, default, callback)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 36)
        frame.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
        local cr = Instance.new("UICorner", frame)
        cr.CornerRadius = UDim.new(0, 6)
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(230, 230, 230)
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 50, 0, 24)
        btn.Position = UDim2.new(1, -60, 0.5, -12)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(50, 55, 70)
        btn.Text = default and "ON" or "OFF"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        local bcr = Instance.new("UICorner", btn)
        bcr.CornerRadius = UDim.new(0, 5)
        
        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = state and "ON" or "OFF"
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(50, 55, 70)
            callback(state)
        end)
    end
    
    createToggle(page, "Auto Place Egg (13 Titik Resmi)", Settings.AutoEgg, function(v)
        Settings.AutoEgg = v
        Notify("Egg System", "Auto Place Egg: " .. (v and "Aktif" or "Mati"), 2)
    end)
    
    -- Dropdown info telur
    local info = Instance.new("TextLabel", page)
    info.Size = UDim2.new(1, 0, 0, 28)
    info.BackgroundTransparency = 1
    info.Text = "Status: Siap meletakkan di 13 slot resmi PetEggService."
    info.TextColor3 = Color3.fromRGB(120, 220, 150)
    info.Font = Enum.Font.Gotham
    info.TextSize = 11
    info.TextXAlignment = Enum.TextXAlignment.Left
end

-- 3. TAB UTILITY & PLAYER
do
    CreateTabButton("⚙️ Utility", 3)
    local page = CreatePage("⚙️ Utility")
    
    local function createButton(parent, text, callback)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 34)
        btn.BackgroundColor3 = Color3.fromRGB(30, 35, 48)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 12
        local cr = Instance.new("UICorner", btn)
        cr.CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(callback)
    end
    
    createButton(page, "Kecepatan Normal (WalkSpeed: 16)", function()
        pcall(function() Humanoid.WalkSpeed = 16 end)
    end)
    createButton(page, "Kecepatan Cepat (WalkSpeed: 50)", function()
        pcall(function() Humanoid.WalkSpeed = 50 end)
    end)
    createButton(page, "Anti AFK (Mencegah Kick 20 Menit)", function()
        local vu = game:GetService("VirtualUser")
        LocalPlayer.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
        Notify("Anti AFK", "Anti-AFK berhasil diaktifkan!", 2)
    end)
end

-- 4. TAB INFO / SETTINGS
do
    CreateTabButton("ℹ️ Info", 4)
    local page = CreatePage("ℹ️ Info")
    
    local label = Instance.new("TextLabel", page)
    label.Size = UDim2.new(1, 0, 0, 60)
    label.BackgroundTransparency = 1
    label.Text = "ZyloHub Official\nArsitektur Modular Profesional\nGame: Grow a Garden"
    label.TextColor3 = Color3.fromRGB(200, 205, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    
    local discordBtn = Instance.new("TextButton", page)
    discordBtn.Size = UDim2.new(1, 0, 0, 34)
    discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    discordBtn.Text = "Salin Tautan Discord"
    discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    discordBtn.Font = Enum.Font.GothamBold
    discordBtn.TextSize = 12
    local dcr = Instance.new("UICorner", discordBtn)
    dcr.CornerRadius = UDim.new(0, 6)
    
    discordBtn.MouseButton1Click:Connect(function()
        local env = getgenv and getgenv() or {}
        local link = env.Discord or "https://discord.gg/"
        if setclipboard then
            setclipboard(link)
            Notify("Discord", "Tautan Discord berhasil disalin ke clipboard!", 2)
        end
    end)
end

-- Buka Tab Pertama secara Default
SwitchTab("🌾 Farm")
Notify("ZyloHub", "ZyloHub Grow a Garden Berhasil Dimuat!", 3)
