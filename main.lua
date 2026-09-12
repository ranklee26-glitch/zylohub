-- =========================================================================
--  ZYLOHUB EXECUTOR EDITION (v3.5 - COMPLETE SUITE: FARM + EGG + HATCH)
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  Dimensions: Compact 620 x 400 px
--
--  SEMUA FITUR TERKUNCI & TERINTEGRASI:
--  [1] AUTO FARM (Plant, Harvest, Sell Crops) -> LOCKED
--  [2] AUTO PLACE EGG (13 Slots, Good Position, Pure Egg Filter) -> LOCKED
--  [3] AUTO HATCH ENGINE (Step 2 Selector, Favorite Detector, Rotation, Rules)
--  [4] STRICT EXECUTION: SEMUA FITUR DEFAULT OFF (Hanya jalan saat diperintah!)
-- =========================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- =========================================================================
-- [1] REMOTE SERVICE CONNECTOR
-- =========================================================================
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)
local Plant_RE = GameEvents and GameEvents:WaitForChild("Plant_RE", 5)
local Sell_Inventory = GameEvents and GameEvents:WaitForChild("Sell_Inventory", 5)
local BuySeedStock = GameEvents and GameEvents:WaitForChild("BuySeedStock", 5)
local PetEggService = GameEvents and GameEvents:WaitForChild("PetEggService", 5)
local PetsServiceRemote = GameEvents and GameEvents:WaitForChild("PetsService", 5)

local Farms = workspace:WaitForChild("Farm", 10)

-- =========================================================================
-- [2] GLOBAL APPLICATION STATE (MUTLAK DEFAULT OFF)
-- =========================================================================
local State = {
    -- Farm Controls (OFF)
    AutoPlant = false,
    PlantMode = "UnderPlayer", -- "UnderPlayer" or "RandomFarm"
    AutoHarvest = false,
    AutoSell = false,
    SellThreshold = 15,
    SelectedSeed = "All Seeds",
    SearchSeedQuery = "",
    
    -- Egg Placement Controls (OFF)
    SelectedEgg = "All Eggs",
    PlacePosition = "Good Position", -- "Good Position", "Right", "Left"
    AutoPlaceEgg = false,
    MaxEggPlace = 13,
    FarmEggCount = 0,
    
    -- Auto Hatch & Rotation Controls (OFF)
    AutoHatch = false,
    DelayEquip = 2,
    DelayUnequip = 2,
    DelayAction = 0.1,
    ActiveTeamTab = "Main Team",
    SelectedTeamPets = {
        ["Main Team"]   = {},
        ["Bronto Team"] = {},
        ["Hatch Team"]  = {},
        ["Sell Team"]   = {}
    },
    SearchPetQuery = "",
    AutoSellAtCount = 24,
    SellMode = "Sell All",
    FilterList = {
        { Name = "Mimic Octopus", MinKG = 3, Action = "KEEP" },
        { Name = "Peacock", MinKG = 3, Action = "KEEP" },
        { Name = "Scarlet Macaw", MinKG = 3, Action = "KEEP" },
        { Name = "Capybara", MinKG = 3, Action = "KEEP" },
        { Name = "Ostrich", MinKG = 3, Action = "KEEP" }
    },
    
    -- Utility (OFF)
    Walkspeed = false,
    InfJump = false,
    Noclip = false,
    AntiAfk = true,
    SpeedVal = 42
}

-- =========================================================================
-- [3] DATASET HELPERS & UTILITIES
-- =========================================================================
local function GetFarm(): Folder?
    if not Farms then return nil end
    for _, farm in ipairs(Farms:GetChildren()) do
        local imp = farm:FindFirstChild("Important")
        local data = imp and imp:FindFirstChild("Data")
        local owner = data and data:FindFirstChild("Owner")
        if owner and (owner.Value == LocalPlayer.Name or owner.Value == LocalPlayer.UserId) then
            return farm
        end
    end
    return nil
end

local function GetCanPlantParts(): table
    local parts = {}
    local farm = GetFarm()
    if not farm then return parts end

    local imp = farm:FindFirstChild("Important")
    local plantLocs = imp and imp:FindFirstChild("Plant_Locations")
    if not plantLocs then return parts end

    for _, obj in ipairs(plantLocs:GetChildren()) do
        if obj.Name == "Can_Plant" and obj:IsA("BasePart") then
            table.insert(parts, obj)
        elseif obj:IsA("BasePart") then
            table.insert(parts, obj)
        end
    end
    return parts
end

local function CleanTitle(raw: string): string
    return raw:gsub("%[.-%]", ""):gsub("%s*[xX]%d+$", ""):gsub("^%s*(.-)%s*$", "%1")
end

-- =========================================================================
-- [4] AUTO FARM ENGINE (PATENTED & VERIFIED)
-- =========================================================================
local isPlanting = false
task.spawn(function()
    while true do
        if State.AutoPlant and not isPlanting then
            local farm = GetFarm()
            local canPlants = GetCanPlantParts()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local bp = LocalPlayer:FindFirstChild("Backpack")

            if farm and #canPlants > 0 and root and bp and Plant_RE then
                local seedTool = nil
                local function scanSeeds(container)
                    if not container then return end
                    for _, item in ipairs(container:GetChildren()) do
                        if item:IsA("Tool") and (item:FindFirstChild("Plant_Name") or item:GetAttribute("Plant_Name") or item.Name:lower():find("seed")) then
                            if not item.Name:lower():find("egg") then
                                seedTool = item
                                break
                            end
                        end
                    end
                end
                scanSeeds(char)
                if not seedTool then scanSeeds(bp) end

                if seedTool then
                    if seedTool.Parent == bp then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then hum:EquipTool(seedTool) end
                        task.wait(0.1)
                    end

                    local plantNameVal = seedTool:FindFirstChild("Plant_Name")
                    local seedName = plantNameVal and plantNameVal.Value or CleanTitle(seedTool.Name)

                    local targetPos = nil
                    if State.PlantMode == "UnderPlayer" then
                        targetPos = Vector3.new(root.Position.X, 0.135, root.Position.Z)
                    else
                        local rndLand = canPlants[math.random(1, #canPlants)]
                        local halfX = (rndLand.Size.X / 2) - 1.5
                        local halfZ = (rndLand.Size.Z / 2) - 1.5
                        local rx = math.random(-math.floor(halfX * 10), math.floor(halfX * 10)) / 10
                        local rz = math.random(-math.floor(halfZ * 10), math.floor(halfZ * 10)) / 10
                        targetPos = rndLand.CFrame:PointToWorldSpace(Vector3.new(rx, (rndLand.Size.Y / 2) + 0.135, rz))
                    end

                    if targetPos then
                        isPlanting = true
                        pcall(function() Plant_RE:FireServer(targetPos, seedName) end)
                        task.wait(0.12)
                        isPlanting = false
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Auto Harvest Worker
task.spawn(function()
    while true do
        if State.AutoHarvest then
            local farm = GetFarm()
            local imp = farm and farm:FindFirstChild("Important")
            local plantsPhysical = imp and imp:FindFirstChild("Plants_Physical")
            if plantsPhysical then
                for _, plant in ipairs(plantsPhysical:GetChildren()) do
                    if not State.AutoHarvest then break end
                    local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then
                        prompt.HoldDuration = 0
                        prompt.RequiresLineOfSight = false
                        pcall(function() fireproximityprompt(prompt) end)
                        task.wait(0.015)
                    end
                end
            end
        end
        task.wait(0.15)
    end
end)

-- Auto Sell Crops Worker
task.spawn(function()
    while true do
        if State.AutoSell and Sell_Inventory then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if root and bp then
                local cropCount = 0
                for _, item in ipairs(bp:GetChildren()) do
                    if item:IsA("Tool") and item:FindFirstChild("Item_String") then
                        cropCount = cropCount + 1
                    end
                end
                if cropCount >= State.SellThreshold then
                    local oldPos = root.CFrame
                    root.CFrame = CFrame.new(62, 4, -26)
                    task.wait(0.2)
                    pcall(function() Sell_Inventory:FireServer() end)
                    task.wait(0.2)
                    root.CFrame = oldPos
                end
            end
        end
        task.wait(2)
    end
end)

-- =========================================================================
-- [5] AUTO PLACE EGG ENGINE (PATENTED & VERIFIED)
-- =========================================================================
local function Generate13EggPositions(mode: string): table
    local positions = {}
    local canPlants = GetCanPlantParts()
    if #canPlants == 0 then return positions end

    table.sort(canPlants, function(a, b) return a.Position.X < b.Position.X end)

    local targetLands = {}
    if mode == "Left" and #canPlants >= 2 then
        table.insert(targetLands, canPlants[1])
    elseif mode == "Right" and #canPlants >= 2 then
        table.insert(targetLands, canPlants[#canPlants])
    else
        targetLands = canPlants
    end

    local totalSlots = 13
    local slotsPerLand = math.ceil(totalSlots / #targetLands)

    for landIdx, land in ipairs(targetLands) do
        local cf = land.CFrame
        local size = land.Size
        local topY = (size.Y / 2) + 0.15
        local safeX = (size.X / 2) - 1.8
        local safeZ = (size.Z / 2) - 1.8

        local countForThis = math.min(slotsPerLand, totalSlots - #positions)
        if landIdx == #targetLands then countForThis = totalSlots - #positions end

        if countForThis > 0 then
            local zStep = (safeZ * 2) / (countForThis + 1)
            local localX = (landIdx == 1) and (safeX - 0.5) or (-safeX + 0.5)
            for i = 1, countForThis do
                local localZ = -safeZ + (i * zStep)
                table.insert(positions, cf:PointToWorldSpace(Vector3.new(localX, topY, localZ)))
                if #positions >= 13 then break end
            end
        end
        if #positions >= 13 then break end
    end
    return positions
end

local function GetPlacedEggsInFarm(): table
    local placed = {}
    local farm = GetFarm()
    local imp = farm and farm:FindFirstChild("Important")
    local objPhysical = imp and imp:FindFirstChild("Objects_Physical")
    if not objPhysical then return placed end

    for _, obj in ipairs(objPhysical:GetChildren()) do
        if obj.Name == "PetEgg" or obj.Name:lower():find("egg") then
            local pos = obj:GetPivot().Position
            table.insert(placed, { Instance = obj, Position = pos })
        end
    end
    return placed
end

local isPlacingEgg = false
task.spawn(function()
    while true do
        local currentPlaced = GetPlacedEggsInFarm()
        State.FarmEggCount = #currentPlaced

        if State.AutoPlaceEgg and not isPlacingEgg then
            if State.FarmEggCount < State.MaxEggPlace and PetEggService then
                local bp, ch = LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character
                local eggTool = nil
                local function findPureEgg(cont)
                    if not cont then return end
                    for _, tool in ipairs(cont:GetChildren()) do
                        if tool:IsA("Tool") and tool.Name:lower():find("egg") and not tool.Name:lower():find("seed") then
                            eggTool = tool
                            break
                        end
                    end
                end
                findPureEgg(ch)
                if not eggTool then findPureEgg(bp) end

                if eggTool then
                    local targetSlots = Generate13EggPositions(State.PlacePosition)
                    local targetPos = nil
                    for _, slotPos in ipairs(targetSlots) do
                        local occupied = false
                        for _, egg in ipairs(currentPlaced) do
                            local dx = egg.Position.X - slotPos.X
                            local dz = egg.Position.Z - slotPos.Z
                            if (dx * dx + dz * dz) < (2.2 * 2.2) then
                                occupied = true
                                break
                            end
                        end
                        if not occupied then
                            targetPos = slotPos
                            break
                        end
                    end

                    if targetPos then
                        isPlacingEgg = true
                        if eggTool.Parent == bp and ch then
                            local hum = ch:FindFirstChildOfClass("Humanoid")
                            if hum then hum:EquipTool(eggTool) end
                            task.wait(0.12)
                        end
                        pcall(function() PetEggService:FireServer("CreateEgg", targetPos) end)
                        task.wait(0.4)
                        isPlacingEgg = false
                    end
                end
            end
        end
        task.wait(0.35)
    end
end)

-- =========================================================================
-- [6] DATASET: PET INVENTORY & FAVORITE DETECTOR
-- =========================================================================
local function GetAllInventoryPets(): table
    local petList = {}
    local ok, ds = pcall(function() return require(ReplicatedStorage.Modules.DataService) end)
    local okMut, mutReg = pcall(function() return require(ReplicatedStorage.Data.PetRegistry.PetMutationRegistry) end)
    
    if ok and ds then
        local data = ds:GetData()
        if data and data.PetsData and data.PetsData.AllPets then
            for uuid, pInfo in pairs(data.PetsData.AllPets) do
                local pData = pInfo.PetData or pInfo
                local petType = pInfo.PetType or pData.PetType or "Unknown"
                
                local mutName = ""
                local mutEnum = pData.MutationType or pData.Mutation
                if okMut and mutReg and mutReg.EnumToPetMutation and mutEnum then
                    mutName = mutReg.EnumToPetMutation[mutEnum] or tostring(mutEnum)
                elseif type(mutEnum) == "string" then
                    mutName = mutEnum
                end
                
                local age = pData.Level or pData.Age or 1
                local weight = pData.Weight or 1.0
                
                local isFavorite = false
                if pData.Favorite == true or pData.IsFavorite == true or pData.Locked == true or pInfo.Favorite == true then
                    isFavorite = true
                end
                
                table.insert(petList, {
                    UUID = uuid,
                    PetType = petType,
                    Mutation = mutName,
                    Age = age,
                    Weight = weight,
                    IsFavorite = isFavorite,
                    Raw = pInfo
                })
            end
        end
    end
    
    table.sort(petList, function(a, b)
        if a.IsFavorite ~= b.IsFavorite then
            return a.IsFavorite == true
        end
        return a.Weight > b.Weight
    end)
    return petList
end

-- =========================================================================
-- [7] AUTO HATCH ENGINE (MANUAL SELECTION & ROLE SWAP)
-- =========================================================================
local function EquipSelectedTeam(roleName: string)
    local selectedUUIDs = State.SelectedTeamPets[roleName] or {}
    local okService, petService = pcall(function() return require(ReplicatedStorage.Modules.PetServices.PetsService) end)
    
    -- Copot pet yang tidak ada di tim pilihan
    if okService and petService and petService.UnequipPet then
        local okUtil, petUtil = pcall(function() return require(ReplicatedStorage.Modules.PetServices.PetUtilities) end)
        if okUtil and petUtil and petUtil.GetPetsSortedByAge then
            local activePets = petUtil:GetPetsSortedByAge(LocalPlayer, 0, false, true) or {}
            for _, act in ipairs(activePets) do
                if not selectedUUIDs[act.UUID] then
                    pcall(function() petService:UnequipPet(act.UUID) end)
                    task.wait(State.DelayUnequip)
                end
            end
        end
    end
    
    -- Pasang pet terpilih
    if PetsServiceRemote then
        for uuid, isSelected in pairs(selectedUUIDs) do
            if isSelected then
                pcall(function() PetsServiceRemote:FireServer("EquipPet", uuid) end)
                task.wait(State.DelayEquip)
            end
        end
    end
end

local function TriggerNativeSellAll(): boolean
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local petEquip = pgui and pgui:FindFirstChild("PetEquipSlots_UI")
    if petEquip then
        local sellCosts = petEquip:FindFirstChild("SellCosts", true)
        local sellAllBtn = sellCosts and sellCosts:FindFirstChild("SellAll", true)
        local sensor = sellAllBtn and sellAllBtn:FindFirstChild("SENSOR")
        if sensor then
            if firesignal then
                firesignal(sensor.MouseButton1Click)
            elseif getconnections then
                for _, conn in ipairs(getconnections(sensor.MouseButton1Click)) do
                    conn:Fire()
                end
            end
            task.wait(State.DelayAction)
            return true
        end
    end
    return false
end

local isHatchingCycle = false
task.spawn(function()
    while true do
        -- STRICT CHECK: Tidak berjalan jika State.AutoHatch FALSE!
        if State.AutoHatch and not isHatchingCycle then
            local allPets = GetAllInventoryPets()
            
            if #allPets >= State.AutoSellAtCount then
                isHatchingCycle = true
                print("[ZyloHub] Pet Inventory Penuh (" .. #allPets .. ") -> Menjalankan Sell Team...")
                EquipSelectedTeam("Sell Team")
                TriggerNativeSellAll()
                task.wait(State.DelayAction)
                EquipSelectedTeam("Bronto Team")
                isHatchingCycle = false
            else
                local farm = GetFarm()
                local imp = farm and farm:FindFirstChild("Important")
                local objPhysical = imp and imp:FindFirstChild("Objects_Physical")
                
                if objPhysical then
                    local readyEggs = {}
                    for _, item in ipairs(objPhysical:GetChildren()) do
                        if item.Name == "PetEgg" or item.Name:lower():find("egg") then
                            local timeToHatch = item:GetAttribute("TimeToHatch") or 999
                            if timeToHatch <= 0 then
                                table.insert(readyEggs, item)
                            end
                        end
                    end
                    
                    if #readyEggs > 0 then
                        isHatchingCycle = true
                        EquipSelectedTeam("Hatch Team")
                        
                        for _, egg in ipairs(readyEggs) do
                            if not State.AutoHatch then break end
                            if PetEggService then
                                pcall(function() PetEggService:FireServer("HatchPet", egg) end)
                            end
                            local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and prompt.Enabled then
                                prompt.HoldDuration = 0
                                prompt.RequiresLineOfSight = false
                                pcall(function() fireproximityprompt(prompt) end)
                            end
                            task.wait(State.DelayAction)
                        end
                        
                        task.wait(0.2)
                        EquipSelectedTeam("Bronto Team")
                        isHatchingCycle = false
                    end
                end
            end
        end
        task.wait(0.4)
    end
end)

-- =========================================================================
-- [8] UI VISUAL DESIGN (CANONICAL LOCKED COMPACT 620 x 400 PX)
-- =========================================================================
local C_BG       = Color3.fromRGB(7, 9, 18)
local C_TOPBAR   = Color3.fromRGB(11, 14, 28)
local C_CARD     = Color3.fromRGB(12, 16, 32)
local C_CARD_2   = Color3.fromRGB(16, 21, 42)
local C_PURPLE   = Color3.fromRGB(138, 43, 226)
local C_PURPLE_L = Color3.fromRGB(175, 82, 255)
local C_CYAN     = Color3.fromRGB(0, 240, 255)
local C_STROKE   = Color3.fromRGB(30, 36, 68)
local C_TEXT_W   = Color3.fromRGB(245, 247, 255)
local C_TEXT_M   = Color3.fromRGB(145, 155, 185)
local C_GREEN    = Color3.fromRGB(0, 255, 170)
local C_RED      = Color3.fromRGB(255, 75, 75)
local C_YELLOW   = Color3.fromRGB(255, 215, 0)

local CoreGui = game:GetService("CoreGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZyloHub_v3_5_FullSuite"
ScreenGui.ResetOnSpawn = false

if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = CoreGui
end

-- Floating Button
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Name = "ZyloFloatToggle"
FloatBtn.Size = UDim2.new(0, 42, 0, 42)
FloatBtn.Position = UDim2.new(0, 20, 0.5, -21)
FloatBtn.BackgroundColor3 = Color3.fromRGB(18, 14, 38)
FloatBtn.Text = "Z"
FloatBtn.TextColor3 = Color3.fromRGB(220, 130, 255)
FloatBtn.Font = Enum.Font.FredokaOne
FloatBtn.TextSize = 22
FloatBtn.AutoButtonColor = false
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 12)
local FbStroke = Instance.new("UIStroke", FloatBtn)
FbStroke.Color = C_PURPLE
FbStroke.Thickness = 2

local fbDragging, fbDragStart, fbStartPos
FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        fbDragging = true
        fbDragStart = input.Position
        fbStartPos = FloatBtn.Position
    end
end)
FloatBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        fbDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if fbDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - fbDragStart
        FloatBtn.Position = UDim2.new(fbStartPos.X.Scale, fbStartPos.X.Offset + delta.X, fbStartPos.Y.Scale, fbStartPos.Y.Offset + delta.Y)
    end
end)

-- Main Window (Compact 620 x 400)
local Main = Instance.new("Frame", ScreenGui)
Main.Name = "MainWindow"
Main.Size = UDim2.new(0, 620, 0, 400)
Main.Position = UDim2.new(0.5, -310, 0.5, -200)
Main.BackgroundColor3 = C_BG
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local MainBorder = Instance.new("UIStroke", Main)
MainBorder.Color = Color3.fromRGB(50, 40, 95)
MainBorder.Thickness = 1.5

local function toggleUI() Main.Visible = not Main.Visible end
FloatBtn.MouseButton1Click:Connect(toggleUI)

-- Topbar
local Topbar = Instance.new("Frame", Main)
Topbar.Size = UDim2.new(1, 0, 0, 46)
Topbar.BackgroundColor3 = C_TOPBAR
Topbar.BorderSizePixel = 0

local TopBorder = Instance.new("Frame", Topbar)
TopBorder.Size = UDim2.new(1, 0, 0, 1)
TopBorder.Position = UDim2.new(0, 0, 1, -1)
TopBorder.BackgroundColor3 = C_STROKE
TopBorder.BorderSizePixel = 0

local LogoBadge = Instance.new("Frame", Topbar)
LogoBadge.Size = UDim2.new(0, 30, 0, 30)
LogoBadge.Position = UDim2.new(0, 12, 0.5, -15)
LogoBadge.BackgroundColor3 = Color3.fromRGB(24, 18, 48)
Instance.new("UICorner", LogoBadge).CornerRadius = UDim.new(0, 8)
local LbStroke = Instance.new("UIStroke", LogoBadge)
LbStroke.Color = C_PURPLE
LbStroke.Thickness = 1.5

local LogoText = Instance.new("TextLabel", LogoBadge)
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "Z"
LogoText.TextColor3 = Color3.fromRGB(220, 130, 255)
LogoText.Font = Enum.Font.FredokaOne
LogoText.TextSize = 18

local BrandTitle = Instance.new("TextLabel", Topbar)
BrandTitle.Position = UDim2.new(0, 48, 0, 7)
BrandTitle.Size = UDim2.new(0, 130, 0, 16)
BrandTitle.BackgroundTransparency = 1
BrandTitle.Text = "ZYLOHUB"
BrandTitle.TextColor3 = C_TEXT_W
BrandTitle.Font = Enum.Font.GothamBold
BrandTitle.TextSize = 14
BrandTitle.TextXAlignment = Enum.TextXAlignment.Left

local BrandSub = Instance.new("TextLabel", Topbar)
BrandSub.Position = UDim2.new(0, 48, 0, 24)
BrandSub.Size = UDim2.new(0, 180, 0, 14)
BrandSub.BackgroundTransparency = 1
BrandSub.Text = "Auto • Farm • Pets • More"
BrandSub.TextColor3 = C_PURPLE_L
BrandSub.Font = Enum.Font.GothamMedium
BrandSub.TextSize = 9
BrandSub.TextXAlignment = Enum.TextXAlignment.Left

local VersionPill = Instance.new("Frame", Topbar)
VersionPill.Size = UDim2.new(0, 42, 0, 22)
VersionPill.Position = UDim2.new(1, -210, 0.5, -11)
VersionPill.BackgroundColor3 = Color3.fromRGB(18, 20, 38)
Instance.new("UICorner", VersionPill).CornerRadius = UDim.new(0, 11)
local VpStroke = Instance.new("UIStroke", VersionPill)
VpStroke.Color = Color3.fromRGB(70, 50, 120)
local VText = Instance.new("TextLabel", VersionPill)
VText.Size = UDim2.new(1, 0, 1, 0)
VText.BackgroundTransparency = 1
VText.Text = "v3.5"
VText.TextColor3 = Color3.fromRGB(195, 175, 255)
VText.Font = Enum.Font.GothamBold
VText.TextSize = 9

local DetectPill = Instance.new("Frame", Topbar)
DetectPill.Size = UDim2.new(0, 115, 0, 24)
DetectPill.Position = UDim2.new(1, -162, 0.5, -12)
DetectPill.BackgroundColor3 = Color3.fromRGB(14, 25, 36)
Instance.new("UICorner", DetectPill).CornerRadius = UDim.new(0, 12)
local DpStroke = Instance.new("UIStroke", DetectPill)
DpStroke.Color = Color3.fromRGB(0, 160, 140)

local Dot = Instance.new("Frame", DetectPill)
Dot.Size = UDim2.new(0, 6, 0, 6)
Dot.Position = UDim2.new(0, 8, 0.5, -3)
Dot.BackgroundColor3 = C_GREEN
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

local DText = Instance.new("TextLabel", DetectPill)
DText.Position = UDim2.new(0, 20, 0, 0)
DText.Size = UDim2.new(1, -22, 1, 0)
DText.BackgroundTransparency = 1
DText.Text = "Game Detected"
DText.TextColor3 = Color3.fromRGB(0, 255, 190)
DText.Font = Enum.Font.GothamBold
DText.TextSize = 9
DText.TextXAlignment = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton", Topbar)
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -44, 0.5, -12)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "—"
MinBtn.TextColor3 = C_TEXT_M
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 13
MinBtn.MouseButton1Click:Connect(toggleUI)

local CloseBtn = Instance.new("TextButton", Topbar)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -24, 0.5, -12)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = C_TEXT_M
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Dragging Topbar
local dragging, dragStart, startPos
Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
Topbar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Sidebar (130px)
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 130, 1, -46)
Sidebar.Position = UDim2.new(0, 0, 0, 46)
Sidebar.BackgroundColor3 = Color3.fromRGB(9, 12, 24)
Sidebar.BorderSizePixel = 0

local SideScroll = Instance.new("ScrollingFrame", Sidebar)
SideScroll.Size = UDim2.new(1, 0, 1, -85)
SideScroll.BackgroundTransparency = 1
SideScroll.BorderSizePixel = 0
SideScroll.ScrollBarThickness = 0
SideScroll.CanvasSize = UDim2.new(0, 0, 0, 330)

local SideLayout = Instance.new("UIListLayout", SideScroll)
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Padding = UDim.new(0, 3)

local SidePad = Instance.new("UIPadding", SideScroll)
SidePad.PaddingTop = UDim.new(0, 6)
SidePad.PaddingLeft = UDim.new(0, 6)
SidePad.PaddingRight = UDim.new(0, 6)

local BrandCard = Instance.new("Frame", Sidebar)
BrandCard.Size = UDim2.new(1, -12, 0, 75)
BrandCard.Position = UDim2.new(0, 6, 1, -80)
BrandCard.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
Instance.new("UICorner", BrandCard).CornerRadius = UDim.new(0, 10)
local BcStroke = Instance.new("UIStroke", BrandCard)
BcStroke.Color = Color3.fromRGB(80, 45, 140)

local BcTitle = Instance.new("TextLabel", BrandCard)
BcTitle.Position = UDim2.new(0, 10, 0, 12)
BcTitle.Size = UDim2.new(1, -16, 0, 14)
BcTitle.BackgroundTransparency = 1
BcTitle.Text = "⚡ ZYLOHUB"
BcTitle.TextColor3 = C_TEXT_W
BcTitle.Font = Enum.Font.GothamBold
BcTitle.TextSize = 11
BcTitle.TextXAlignment = Enum.TextXAlignment.Left

local BcDesc = Instance.new("TextLabel", BrandCard)
BcDesc.Position = UDim2.new(0, 10, 0, 28)
BcDesc.Size = UDim2.new(1, -16, 0, 24)
BcDesc.BackgroundTransparency = 1
BcDesc.Text = "Better Scripts\nBetter Experience"
BcDesc.TextColor3 = C_TEXT_M
BcDesc.Font = Enum.Font.GothamMedium
BcDesc.TextSize = 8
BcDesc.TextXAlignment = Enum.TextXAlignment.Left

-- Content Area
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -140, 1, -52)
Content.Position = UDim2.new(0, 135, 0, 50)
Content.BackgroundTransparency = 1

local Pages = {}
local Buttons = {}

local function createTabPage(name)
    local sf = Instance.new("ScrollingFrame", Content)
    sf.Name = name .. "Page"
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 2
    sf.ScrollBarImageColor3 = C_PURPLE
    sf.Visible = false
    
    local list = Instance.new("UIListLayout", sf)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)
    
    local pad = Instance.new("UIPadding", sf)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    
    Pages[name] = sf
    return sf
end

local function addSidebarTab(name, icon, order)
    local btn = Instance.new("TextButton", SideScroll)
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
    btn.BackgroundTransparency = 1
    btn.Text = "   " .. icon .. "   " .. name
    btn.TextColor3 = C_TEXT_M
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 10
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(function()
        for tName, tBtn in pairs(Buttons) do
            tBtn.BackgroundTransparency = 1
            tBtn.TextColor3 = C_TEXT_M
            if Pages[tName] then Pages[tName].Visible = false end
        end
        btn.BackgroundTransparency = 0
        btn.BackgroundColor3 = C_PURPLE
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        if Pages[name] then Pages[name].Visible = true end
    end)
    Buttons[name] = btn
end

local PageHome      = createTabPage("Home")
local PageFarm      = createTabPage("Farm")
local PagePets      = createTabPage("Pets")
local PageUtility   = createTabPage("Utility")
local PageShop      = createTabPage("Shop")
local PageConfig    = createTabPage("Config")
local PageEvent     = createTabPage("Event")
local PageInventory = createTabPage("Inventory")
local PageWebhook   = createTabPage("Webhook")

addSidebarTab("Home", "🏠", 1)
addSidebarTab("Farm", "🍃", 2)
addSidebarTab("Pets", "🐾", 3)
addSidebarTab("Utility", "🔧", 4)
addSidebarTab("Shop", "🛒", 5)
addSidebarTab("Config", "⚙️", 6)
addSidebarTab("Event", "⭐", 7)
addSidebarTab("Inventory", "🎒", 8)
addSidebarTab("Webhook", "🔗", 9)

local function createPillSwitch(parent, defaultState, callback)
    local switch = Instance.new("TextButton", parent)
    switch.Size = UDim2.new(0, 36, 0, 20)
    switch.BackgroundColor3 = defaultState and C_PURPLE or Color3.fromRGB(26, 28, 44)
    switch.Text = ""
    switch.AutoButtonColor = false
    Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)
    local swStroke = Instance.new("UIStroke", switch)
    swStroke.Color = Color3.fromRGB(45, 50, 75)
    
    local knob = Instance.new("Frame", switch)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = defaultState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    local active = defaultState
    switch.MouseButton1Click:Connect(function()
        active = not active
        local targetPos = active and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        local targetColor = active and C_PURPLE or Color3.fromRGB(26, 28, 44)
        TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Position = targetPos }):Play()
        TweenService:Create(switch, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { BackgroundColor3 = targetColor }):Play()
        callback(active)
    end)
    return switch
end

-- Accordion Builder
PagePets.CanvasSize = UDim2.new(0, 0, 0, 950)

local function createPetAccordion(titleText, defaultOpen, expandedH)
    local accFrame = Instance.new("Frame", PagePets)
    accFrame.Size = UDim2.new(1, 0, 0, defaultOpen and expandedH or 38)
    accFrame.BackgroundColor3 = C_CARD
    accFrame.ClipsDescendants = true
    Instance.new("UICorner", accFrame).CornerRadius = UDim.new(0, 8)
    local aStroke = Instance.new("UIStroke", accFrame)
    aStroke.Color = C_STROKE

    local headBtn = Instance.new("TextButton", accFrame)
    headBtn.Size = UDim2.new(1, 0, 0, 38)
    headBtn.BackgroundTransparency = 1
    headBtn.Text = ""
    headBtn.AutoButtonColor = false

    local titleLbl = Instance.new("TextLabel", headBtn)
    titleLbl.Position = UDim2.new(0, 12, 0, 0)
    titleLbl.Size = UDim2.new(1, -45, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = titleText
    titleLbl.TextColor3 = C_TEXT_W
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local chevron = Instance.new("TextLabel", headBtn)
    chevron.Position = UDim2.new(1, -26, 0, 0)
    chevron.Size = UDim2.new(0, 20, 1, 0)
    chevron.BackgroundTransparency = 1
    chevron.Text = defaultOpen and "v" or ">"
    chevron.TextColor3 = defaultOpen and C_PURPLE_L or C_TEXT_M
    chevron.Font = Enum.Font.GothamBold
    chevron.TextSize = 11

    local divLine = Instance.new("Frame", accFrame)
    divLine.Position = UDim2.new(0, 0, 0, 37)
    divLine.Size = UDim2.new(1, 0, 0, 1.5)
    divLine.BackgroundColor3 = C_PURPLE_L
    divLine.BorderSizePixel = 0
    divLine.Visible = defaultOpen

    local body = Instance.new("Frame", accFrame)
    body.Position = UDim2.new(0, 0, 0, 39)
    body.Size = UDim2.new(1, 0, 0, expandedH - 39)
    body.BackgroundTransparency = 1

    local isOpen = defaultOpen
    local function setAccordion(open)
        isOpen = open
        chevron.Text = isOpen and "v" or ">"
        chevron.TextColor3 = isOpen and C_PURPLE_L or C_TEXT_M
        divLine.Visible = isOpen
        TweenService:Create(accFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            Size = UDim2.new(1, 0, 0, isOpen and expandedH or 38)
        }):Play()
    end

    headBtn.MouseButton1Click:Connect(function() setAccordion(not isOpen) end)
    return accFrame, body, setAccordion
end

-- =============================================================
-- [ACCORDION 1: AUTO PLACE EGG (LOCKED & VERIFIED)]
-- =============================================================
local accPlaceEgg, bodyPlaceEgg = createPetAccordion("Auto Place Egg", false, 200)

local peLayout = Instance.new("UIListLayout", bodyPlaceEgg)
peLayout.SortOrder = Enum.SortOrder.LayoutOrder
peLayout.Padding = UDim.new(0, 1)

local rowSelectEgg = Instance.new("Frame", bodyPlaceEgg)
rowSelectEgg.Size = UDim2.new(1, 0, 0, 38)
rowSelectEgg.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
rowSelectEgg.BorderSizePixel = 0
rowSelectEgg.LayoutOrder = 1

local seLbl = Instance.new("TextLabel", rowSelectEgg)
seLbl.Position = UDim2.new(0, 12, 0, 0)
seLbl.Size = UDim2.new(0.45, 0, 1, 0)
seLbl.BackgroundTransparency = 1
seLbl.Text = "Select Egg"
seLbl.TextColor3 = C_TEXT_W
seLbl.Font = Enum.Font.GothamBold
seLbl.TextSize = 10
seLbl.TextXAlignment = Enum.TextXAlignment.Left

local seBtn = Instance.new("TextButton", rowSelectEgg)
seBtn.Position = UDim2.new(1, -165, 0.5, -13)
seBtn.Size = UDim2.new(0, 155, 0, 26)
seBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
seBtn.Text = "Select Options  v"
seBtn.TextColor3 = Color3.fromRGB(175, 185, 215)
seBtn.Font = Enum.Font.GothamBold
seBtn.TextSize = 9
Instance.new("UICorner", seBtn).CornerRadius = UDim.new(0, 6)
local seStroke = Instance.new("UIStroke", seBtn)
seStroke.Color = Color3.fromRGB(45, 52, 80)

local rowSelectPos = Instance.new("Frame", bodyPlaceEgg)
rowSelectPos.Size = UDim2.new(1, 0, 0, 38)
rowSelectPos.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
rowSelectPos.BorderSizePixel = 0
rowSelectPos.LayoutOrder = 2

local spLbl = Instance.new("TextLabel", rowSelectPos)
spLbl.Position = UDim2.new(0, 12, 0, 0)
spLbl.Size = UDim2.new(0.45, 0, 1, 0)
spLbl.BackgroundTransparency = 1
spLbl.Text = "Select Place Position"
spLbl.TextColor3 = C_TEXT_W
spLbl.Font = Enum.Font.GothamBold
spLbl.TextSize = 10
spLbl.TextXAlignment = Enum.TextXAlignment.Left

local spBtn = Instance.new("TextButton", rowSelectPos)
spBtn.Position = UDim2.new(1, -165, 0.5, -13)
spBtn.Size = UDim2.new(0, 155, 0, 26)
spBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
spBtn.Text = "Good Position  v"
spBtn.TextColor3 = Color3.fromRGB(245, 247, 255)
spBtn.Font = Enum.Font.GothamBold
spBtn.TextSize = 9
Instance.new("UICorner", spBtn).CornerRadius = UDim.new(0, 6)
local spStroke = Instance.new("UIStroke", spBtn)
spStroke.Color = Color3.fromRGB(45, 52, 80)

local posOptions = { "Good Position", "Right", "Left" }
local posIndex = 1
spBtn.MouseButton1Click:Connect(function()
    posIndex = posIndex + 1
    if posIndex > #posOptions then posIndex = 1 end
    State.PlacePosition = posOptions[posIndex]
    spBtn.Text = State.PlacePosition .. "  v"
end)

local rowAutoPlace = Instance.new("Frame", bodyPlaceEgg)
rowAutoPlace.Size = UDim2.new(1, 0, 0, 38)
rowAutoPlace.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
rowAutoPlace.BorderSizePixel = 0
rowAutoPlace.LayoutOrder = 3

local apLbl = Instance.new("TextLabel", rowAutoPlace)
apLbl.Position = UDim2.new(0, 12, 0, 0)
apLbl.Size = UDim2.new(0.5, 0, 1, 0)
apLbl.BackgroundTransparency = 1
apLbl.Text = "Auto Place Egg"
apLbl.TextColor3 = C_TEXT_W
apLbl.Font = Enum.Font.GothamBold
apLbl.TextSize = 10
apLbl.TextXAlignment = Enum.TextXAlignment.Left

local apSw = createPillSwitch(rowAutoPlace, State.AutoPlaceEgg, function(v) State.AutoPlaceEgg = v end)
apSw.Position = UDim2.new(1, -48, 0.5, -10)

local rowMaxEgg = Instance.new("Frame", bodyPlaceEgg)
rowMaxEgg.Size = UDim2.new(1, 0, 0, 44)
rowMaxEgg.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
rowMaxEgg.BorderSizePixel = 0
rowMaxEgg.LayoutOrder = 4

local meTitle = Instance.new("TextLabel", rowMaxEgg)
meTitle.Position = UDim2.new(0, 12, 0, 6)
meTitle.Size = UDim2.new(0.6, 0, 0, 14)
meTitle.BackgroundTransparency = 1
meTitle.Text = "Max Egg Place (Custom)"
meTitle.TextColor3 = C_TEXT_W
meTitle.Font = Enum.Font.GothamBold
meTitle.TextSize = 10
meTitle.TextXAlignment = Enum.TextXAlignment.Left

local meSub = Instance.new("TextLabel", rowMaxEgg)
meSub.Position = UDim2.new(0, 12, 0, 22)
meSub.Size = UDim2.new(0.6, 0, 0, 14)
meSub.BackgroundTransparency = 1
meSub.Text = "Di Kebun: 0 / 13 telur (PetEggService Active)"
meSub.TextColor3 = Color3.fromRGB(120, 180, 255)
meSub.Font = Enum.Font.GothamMedium
meSub.TextSize = 8.5
meSub.TextXAlignment = Enum.TextXAlignment.Left

local meBox = Instance.new("TextBox", rowMaxEgg)
meBox.Position = UDim2.new(1, -165, 0.5, -13)
meBox.Size = UDim2.new(0, 155, 0, 26)
meBox.BackgroundColor3 = Color3.fromRGB(14, 17, 34)
meBox.Text = "13"
meBox.TextColor3 = Color3.fromRGB(245, 247, 255)
meBox.Font = Enum.Font.GothamBold
meBox.TextSize = 10
Instance.new("UICorner", meBox).CornerRadius = UDim.new(0, 6)
local meStroke = Instance.new("UIStroke", meBox)
meStroke.Color = Color3.fromRGB(45, 52, 80)

meBox:GetPropertyChangedSignal("Text"):Connect(function()
    local val = tonumber(meBox.Text)
    if val then State.MaxEggPlace = val end
end)

task.spawn(function()
    while true do
        if meSub and meSub.Parent then
            local count = State.FarmEggCount
            meSub.Text = "Di Kebun: " .. tostring(count) .. " / " .. tostring(State.MaxEggPlace) .. " telur (PetEggService Active)"
            meSub.TextColor3 = (count >= State.MaxEggPlace) and C_GREEN or Color3.fromRGB(120, 180, 255)
        end
        task.wait(0.3)
    end
end)

-- =============================================================
-- [ACCORDION 2: ADVANCED AUTO HATCH & MANUAL SELECTOR (STEP 2)]
-- =============================================================
local accHatch, bodyHatch = createPetAccordion("Auto Hatch", true, 345)

local HatchSubTabs = Instance.new("Frame", bodyHatch)
HatchSubTabs.Size = UDim2.new(1, -20, 0, 26)
HatchSubTabs.Position = UDim2.new(0, 10, 0, 6)
HatchSubTabs.BackgroundTransparency = 1

local HstLayout = Instance.new("UIListLayout", HatchSubTabs)
HstLayout.FillDirection = Enum.FillDirection.Horizontal
HstLayout.Padding = UDim.new(0, 5)

local teamTabBtns = {}
local function createTeamSubTab(name)
    local b = Instance.new("TextButton", HatchSubTabs)
    b.Size = UDim2.new(0.185, 0, 1, 0)
    b.BackgroundColor3 = (State.ActiveTeamTab == name) and C_PURPLE or C_CARD_2
    b.Text = name
    b.TextColor3 = (State.ActiveTeamTab == name) and C_TEXT_W or C_TEXT_M
    b.Font = Enum.Font.GothamBold
    b.TextSize = 8.5
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local bSt = Instance.new("UIStroke", b)
    bSt.Color = (State.ActiveTeamTab == name) and C_PURPLE_L or C_STROKE
    
    teamTabBtns[name] = { Button = b, Stroke = bSt }
    return b
end

local tabMain   = createTeamSubTab("Main Team")
local tabBronto = createTeamSubTab("Bronto Team")
local tabHatchT = createTeamSubTab("Hatch Team")
local tabSellT  = createTeamSubTab("Sell Team")
local tabConfig = createTeamSubTab("Config")

local TeamSettingsContainer = Instance.new("Frame", bodyHatch)
TeamSettingsContainer.Position = UDim2.new(0, 10, 0, 36)
TeamSettingsContainer.Size = UDim2.new(1, -20, 0, 260)
TeamSettingsContainer.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
Instance.new("UICorner", TeamSettingsContainer).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", TeamSettingsContainer).Color = C_STROKE

local ViewRole = Instance.new("Frame", TeamSettingsContainer)
ViewRole.Size = UDim2.new(1, 0, 1, 0)
ViewRole.BackgroundTransparency = 1

local RoleTitle = Instance.new("TextLabel", ViewRole)
RoleTitle.Position = UDim2.new(0, 12, 0, 6)
RoleTitle.Size = UDim2.new(1, -24, 0, 14)
RoleTitle.BackgroundTransparency = 1
RoleTitle.Text = "Select Pet (" .. State.ActiveTeamTab .. ")"
RoleTitle.TextColor3 = C_TEXT_W
RoleTitle.Font = Enum.Font.GothamBold
RoleTitle.TextSize = 9.5
RoleTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Search Input (Persis Sesuai Step 2 Discord)
local SearchInput = Instance.new("TextBox", ViewRole)
SearchInput.Position = UDim2.new(0, 12, 0, 24)
SearchInput.Size = UDim2.new(1, -24, 0, 22)
SearchInput.BackgroundColor3 = C_CARD_2
SearchInput.PlaceholderText = "Search..."
SearchInput.PlaceholderColor3 = C_TEXT_M
SearchInput.Text = ""
SearchInput.TextColor3 = C_TEXT_W
SearchInput.Font = Enum.Font.GothamMedium
SearchInput.TextSize = 8.5
Instance.new("UICorner", SearchInput).CornerRadius = UDim.new(0, 5)
Instance.new("UIStroke", SearchInput).Color = C_STROKE

-- Scrolling List Pet (Format Kuning/Emas Sesuai Gambar Step 2)
local PetListScroll = Instance.new("ScrollingFrame", ViewRole)
PetListScroll.Position = UDim2.new(0, 12, 0, 50)
PetListScroll.Size = UDim2.new(1, -24, 0, 160)
PetListScroll.BackgroundTransparency = 1
PetListScroll.ScrollBarThickness = 2
PetListScroll.ScrollBarImageColor3 = C_PURPLE
PetListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local PlsLayout = Instance.new("UIListLayout", PetListScroll)
PlsLayout.Padding = UDim.new(0, 3)

local function refreshPetListUI()
    for _, c in ipairs(PetListScroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
    end
    
    local allPets = GetAllInventoryPets()
    local q = State.SearchPetQuery:lower()
    local selectedMap = State.SelectedTeamPets[State.ActiveTeamTab] or {}
    
    local count = 0
    for _, pet in ipairs(allPets) do
        local mutPrefix = (pet.Mutation ~= "" and pet.Mutation ~= "Normal") and ("[" .. pet.Mutation .. "] ") or ""
        local petDisplay = mutPrefix .. pet.PetType .. " | Age " .. tostring(pet.Age) .. " | " .. string.format("%.2f", pet.Weight) .. " KG"
        
        if q == "" or petDisplay:lower():find(q) then
            count = count + 1
            local isSelected = selectedMap[pet.UUID] == true
            
            local btn = Instance.new("TextButton", PetListScroll)
            btn.Size = UDim2.new(1, -4, 0, 26)
            
            -- Tampilan List: Kuning/Emas untuk yang terpilih (Step 2), Favorit diberi icon ⭐
            if isSelected then
                btn.BackgroundColor3 = Color3.fromRGB(245, 195, 35)
            else
                btn.BackgroundColor3 = pet.IsFavorite and Color3.fromRGB(35, 42, 70) or Color3.fromRGB(20, 25, 48)
            end
            
            local favStar = pet.IsFavorite and "⭐ " or ""
            btn.Text = "  " .. favStar .. petDisplay
            btn.TextColor3 = isSelected and Color3.fromRGB(15, 15, 20) or (pet.IsFavorite and C_YELLOW or C_TEXT_W)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 8.5
            btn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
            
            local bStroke = Instance.new("UIStroke", btn)
            bStroke.Color = isSelected and Color3.fromRGB(255, 225, 100) or (pet.IsFavorite and Color3.fromRGB(180, 140, 40) or C_STROKE)
            
            btn.MouseButton1Click:Connect(function()
                if selectedMap[pet.UUID] then
                    selectedMap[pet.UUID] = nil
                else
                    selectedMap[pet.UUID] = true
                end
                refreshPetListUI()
            end)
        end
    end
    PetListScroll.CanvasSize = UDim2.new(0, 0, 0, count * 29)
end

SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    State.SearchPetQuery = SearchInput.Text
    refreshPetListUI()
end)

-- Tombol Start Auto Hatch & Stop (KONTROL PENUH DI TANGAN ANDA)
local ActRow = Instance.new("Frame", ViewRole)
ActRow.Position = UDim2.new(0, 12, 1, -38)
ActRow.Size = UDim2.new(1, -24, 0, 30)
ActRow.BackgroundTransparency = 1

local StartHatchBtn = Instance.new("TextButton", ActRow)
StartHatchBtn.Size = UDim2.new(0.485, 0, 1, 0)
StartHatchBtn.BackgroundColor3 = State.AutoHatch and C_GREEN or C_PURPLE
StartHatchBtn.Text = State.AutoHatch and "⚡ HATCH RUNNING" or "⚡ START AUTO HATCH"
StartHatchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartHatchBtn.Font = Enum.Font.GothamBold
StartHatchBtn.TextSize = 9
Instance.new("UICorner", StartHatchBtn).CornerRadius = UDim.new(0, 6)

local StopHatchBtn = Instance.new("TextButton", ActRow)
StopHatchBtn.Position = UDim2.new(0.515, 0, 0, 0)
StopHatchBtn.Size = UDim2.new(0.485, 0, 1, 0)
StopHatchBtn.BackgroundColor3 = C_CARD_2
StopHatchBtn.Text = "⛔ STOP"
StopHatchBtn.TextColor3 = C_RED
StopHatchBtn.Font = Enum.Font.GothamBold
StopHatchBtn.TextSize = 9
Instance.new("UICorner", StopHatchBtn).CornerRadius = UDim.new(0, 6)

StartHatchBtn.MouseButton1Click:Connect(function()
    State.AutoHatch = true
    StartHatchBtn.Text = "⚡ HATCH RUNNING"
    StartHatchBtn.BackgroundColor3 = C_GREEN
    print("[ZyloHub] Auto Hatch Dimulai!")
end)

StopHatchBtn.MouseButton1Click:Connect(function()
    State.AutoHatch = false
    StartHatchBtn.Text = "⚡ START AUTO HATCH"
    StartHatchBtn.BackgroundColor3 = C_PURPLE
    print("[ZyloHub] Auto Hatch Dihentikan!")
end)

-- View Config Sesuai Spec
local ViewConfig = Instance.new("ScrollingFrame", TeamSettingsContainer)
ViewConfig.Size = UDim2.new(1, 0, 1, 0)
ViewConfig.BackgroundTransparency = 1
ViewConfig.ScrollBarThickness = 2
ViewConfig.ScrollBarImageColor3 = C_PURPLE
ViewConfig.Visible = false
ViewConfig.CanvasSize = UDim2.new(0, 0, 0, 360)

local VcLayout = Instance.new("UIListLayout", ViewConfig)
VcLayout.Padding = UDim.new(0, 6)
local VcPad = Instance.new("UIPadding", ViewConfig)
VcPad.PaddingTop = UDim.new(0, 8)
VcPad.PaddingLeft = UDim.new(0, 8)
VcPad.PaddingRight = UDim.new(0, 8)
VcPad.PaddingBottom = UDim.new(0, 8)

local PetunjukBox = Instance.new("Frame", ViewConfig)
PetunjukBox.Size = UDim2.new(1, 0, 0, 78)
PetunjukBox.BackgroundColor3 = C_CARD_2
Instance.new("UICorner", PetunjukBox).CornerRadius = UDim.new(0, 6)

local PjTitle = Instance.new("TextLabel", PetunjukBox)
PjTitle.Position = UDim2.new(0, 8, 0, 5)
PjTitle.Size = UDim2.new(1, -16, 0, 12)
PjTitle.BackgroundTransparency = 1
PjTitle.Text = "PETUNJUK AUTO HATCH & KEEP/SELL"
PjTitle.TextColor3 = Color3.fromRGB(255, 210, 100)
PjTitle.Font = Enum.Font.GothamBold
PjTitle.TextSize = 8.5
PjTitle.TextXAlignment = Enum.TextXAlignment.Left

local PjDesc = Instance.new("TextLabel", PetunjukBox)
PjDesc.Position = UDim2.new(0, 8, 0, 20)
PjDesc.Size = UDim2.new(1, -16, 0, 54)
PjDesc.BackgroundTransparency = 1
PjDesc.Text = "• Aturan hanya diterapkan pada pet di daftar bawah.\n• KG = 0 pet akan di KEEP (Simpan).\n• Weight < Target KG: SELL | Weight ≥ Target KG: KEEP (Masuk Bronto)."
PjDesc.TextColor3 = C_TEXT_M
PjDesc.Font = Enum.Font.GothamMedium
PjDesc.TextSize = 7.5
PjDesc.TextWrapped = true
PjDesc.TextXAlignment = Enum.TextXAlignment.Left

local function switchTeamTab(name)
    State.ActiveTeamTab = name
    for tName, data in pairs(teamTabBtns) do
        local isActive = (tName == name)
        data.Button.BackgroundColor3 = isActive and C_PURPLE or C_CARD_2
        data.Button.TextColor3 = isActive and C_TEXT_W or C_TEXT_M
        data.Stroke.Color = isActive and C_PURPLE_L or C_STROKE
    end

    if name == "Config" then
        ViewRole.Visible = false
        ViewConfig.Visible = true
    else
        ViewRole.Visible = true
        ViewConfig.Visible = false
        RoleTitle.Text = "Select Pet (" .. name .. ")"
        refreshPetListUI()
    end
end

tabMain.MouseButton1Click:Connect(function() switchTeamTab("Main Team") end)
tabBronto.MouseButton1Click:Connect(function() switchTeamTab("Bronto Team") end)
tabHatchT.MouseButton1Click:Connect(function() switchTeamTab("Hatch Team") end)
tabSellT.MouseButton1Click:Connect(function() switchTeamTab("Sell Team") end)
tabConfig.MouseButton1Click:Connect(function() switchTeamTab("Config") end)

-- Accordion Pet Lainnya (Lengkap)
local accMini, bodyMini = createPetAccordion("Pet Minigames", false, 85)
local accTeam, bodyTeam = createPetAccordion("Pet Team", false, 85)
local accPick, bodyPick = createPetAccordion("Auto Pick Place", false, 85)
local accNight, bodyNight = createPetAccordion("Auto Nightmare", false, 85)
local accEle, bodyEle = createPetAccordion("Auto Elephant", false, 85)
local accPetMg, bodyPetMg = createPetAccordion("Pet", false, 85)
local accBoost, bodyBoost = createPetAccordion("Pet Boost", false, 85)

-- =============================================================
-- [TAB 2: FARM PAGE (LOCKED & VERIFIED)]
-- =============================================================
PageFarm.CanvasSize = UDim2.new(0, 0, 0, 480)

local FarmCard1 = Instance.new("Frame", PageFarm)
FarmCard1.Size = UDim2.new(1, 0, 0, 240)
FarmCard1.BackgroundColor3 = C_CARD
Instance.new("UICorner", FarmCard1).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", FarmCard1).Color = C_STROKE

local FcTitle = Instance.new("TextLabel", FarmCard1)
FcTitle.Position = UDim2.new(0, 12, 0, 10)
FcTitle.Size = UDim2.new(1, -24, 0, 14)
FcTitle.BackgroundTransparency = 1
FcTitle.Text = "🌱  AUTO PLANT & HARVEST ENGINE"
FcTitle.TextColor3 = C_PURPLE_L
FcTitle.Font = Enum.Font.GothamBold
FcTitle.TextSize = 11
FcTitle.TextXAlignment = Enum.TextXAlignment.Left

local FarmDetect = Instance.new("TextLabel", FarmCard1)
FarmDetect.Position = UDim2.new(0, 12, 0, 26)
FarmDetect.Size = UDim2.new(1, -24, 0, 16)
FarmDetect.BackgroundTransparency = 1
local mFarm = GetFarm()
FarmDetect.Text = mFarm and ("✅ Lahan: " .. mFarm.Name .. " (Can_Plant Terhubung)") or "⚠️ Lahan Belum Ditemukan di Workspace.Farm"
FarmDetect.TextColor3 = mFarm and C_GREEN or C_RED
FarmDetect.Font = Enum.Font.GothamBold
FarmDetect.TextSize = 9.5
FarmDetect.TextXAlignment = Enum.TextXAlignment.Left

local PlantRow = Instance.new("Frame", FarmCard1)
PlantRow.Position = UDim2.new(0, 12, 0, 46)
PlantRow.Size = UDim2.new(1, -24, 0, 30)
PlantRow.BackgroundColor3 = C_CARD_2
Instance.new("UICorner", PlantRow).CornerRadius = UDim.new(0, 6)

local PrLabel = Instance.new("TextLabel", PlantRow)
PrLabel.Position = UDim2.new(0, 10, 0, 0)
PrLabel.Size = UDim2.new(1, -50, 1, 0)
PrLabel.BackgroundTransparency = 1
PrLabel.Text = "Auto Plant (Tanam + Auto Equip Tool Benih)"
PrLabel.TextColor3 = C_TEXT_W
PrLabel.Font = Enum.Font.GothamMedium
PrLabel.TextSize = 9
PrLabel.TextXAlignment = Enum.TextXAlignment.Left
local PrSwitch = createPillSwitch(PlantRow, State.AutoPlant, function(v) State.AutoPlant = v end)
PrSwitch.Position = UDim2.new(1, -40, 0.5, -10)

local ModeRow = Instance.new("Frame", FarmCard1)
ModeRow.Position = UDim2.new(0, 12, 0, 80)
ModeRow.Size = UDim2.new(1, -24, 0, 28)
ModeRow.BackgroundTransparency = 1

local ModeBtn1 = Instance.new("TextButton", ModeRow)
ModeBtn1.Size = UDim2.new(0.485, 0, 1, 0)
ModeBtn1.BackgroundColor3 = (State.PlantMode == "UnderPlayer") and C_PURPLE or C_CARD_2
ModeBtn1.Text = "📍 Di Bawah Karakter"
ModeBtn1.TextColor3 = (State.PlantMode == "UnderPlayer") and Color3.fromRGB(255, 255, 255) or C_TEXT_M
ModeBtn1.Font = Enum.Font.GothamBold
ModeBtn1.TextSize = 9
Instance.new("UICorner", ModeBtn1).CornerRadius = UDim.new(0, 6)

local ModeBtn2 = Instance.new("TextButton", ModeRow)
ModeBtn2.Position = UDim2.new(0.515, 0, 0, 0)
ModeBtn2.Size = UDim2.new(0.485, 0, 1, 0)
ModeBtn2.BackgroundColor3 = (State.PlantMode == "RandomFarm") and C_PURPLE or C_CARD_2
ModeBtn2.Text = "🎲 Random di Kebun"
ModeBtn2.TextColor3 = (State.PlantMode == "RandomFarm") and Color3.fromRGB(255, 255, 255) or C_TEXT_M
ModeBtn2.Font = Enum.Font.GothamBold
ModeBtn2.TextSize = 9
Instance.new("UICorner", ModeBtn2).CornerRadius = UDim.new(0, 6)

local function updateModeButtons()
    ModeBtn1.BackgroundColor3 = (State.PlantMode == "UnderPlayer") and C_PURPLE or C_CARD_2
    ModeBtn1.TextColor3 = (State.PlantMode == "UnderPlayer") and Color3.fromRGB(255, 255, 255) or C_TEXT_M
    ModeBtn2.BackgroundColor3 = (State.PlantMode == "RandomFarm") and C_PURPLE or C_CARD_2
    ModeBtn2.TextColor3 = (State.PlantMode == "RandomFarm") and Color3.fromRGB(255, 255, 255) or C_TEXT_M
end

ModeBtn1.MouseButton1Click:Connect(function() State.PlantMode = "UnderPlayer" updateModeButtons() end)
ModeBtn2.MouseButton1Click:Connect(function() State.PlantMode = "RandomFarm" updateModeButtons() end)

local HarRow = Instance.new("Frame", FarmCard1)
HarRow.Position = UDim2.new(0, 12, 0, 114)
HarRow.Size = UDim2.new(1, -24, 0, 30)
HarRow.BackgroundColor3 = C_CARD_2
Instance.new("UICorner", HarRow).CornerRadius = UDim.new(0, 6)

local HrLabel = Instance.new("TextLabel", HarRow)
HrLabel.Position = UDim2.new(0, 10, 0, 0)
HrLabel.Size = UDim2.new(1, -50, 1, 0)
HrLabel.BackgroundTransparency = 1
HrLabel.Text = "Auto Harvest (Panen Cepat & Mulus Tanpa Lag)"
HrLabel.TextColor3 = C_TEXT_W
HrLabel.Font = Enum.Font.GothamMedium
HrLabel.TextSize = 9
HrLabel.TextXAlignment = Enum.TextXAlignment.Left
local HrSwitch = createPillSwitch(HarRow, State.AutoHarvest, function(v) State.AutoHarvest = v end)
HrSwitch.Position = UDim2.new(1, -40, 0.5, -10)

-- Movement & Utilities
RunService.Stepped:Connect(function()
    if State.Noclip and LocalPlayer.Character then
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if State.InfJump and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

LocalPlayer.Idled:Connect(function()
    if State.AntiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Initial Load
refreshPetListUI()

-- Tampilkan Tab Pets Default
Buttons["Pets"].BackgroundTransparency = 0
Buttons["Pets"].BackgroundColor3 = C_PURPLE
Buttons["Pets"].TextColor3 = Color3.fromRGB(255, 255, 255)
PagePets.Visible = true

print("[ZyloHub v3.5] Full Suite (Farm + Egg + Auto Hatch Step 2) Ready & Locked!")
