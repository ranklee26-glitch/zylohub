-- =========================================================================
--  ZYLOHUB UI FRAMEWORK (v3.5 - OFFICIAL PetEggService & COMPLETE HATCH EDITION)
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  VERIFIED FROM LOCAL DECOMPILE:
--   Remote: ReplicatedStorage.GameEvents.PetEggService
--   Method: FireServer("CreateEgg", targetPosition)
--   Target Part: Farm.Important.Plant_Locations.Can_Plant
--   Auto Hatch: Adapted 100% from Discord UI (4 Roles + Config + Pet Selector)
-- =========================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- =========================================================================
-- [1] SERVICES & REMOTES RESMI DARI DECOMPILE
-- =========================================================================
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)
local Plant_RE = GameEvents and GameEvents:WaitForChild("Plant_RE", 5)
local Sell_Inventory = GameEvents and GameEvents:WaitForChild("Sell_Inventory", 5)
local BuySeedStock = GameEvents and GameEvents:WaitForChild("BuySeedStock", 5)

-- REMOTE RESMI PENEMPATAN TELUR & PETS
local PetEggService = GameEvents and GameEvents:WaitForChild("PetEggService", 5)
local PetsServiceRemote = GameEvents and GameEvents:WaitForChild("PetsService", 5)

local Farms = workspace:WaitForChild("Farm", 10)

local State = {
    AutoPlant = false,
    PlantMode = "UnderPlayer",
    AutoHarvest = false,
    AutoSell = false,
    SelectedSeed = "",
    SearchSeedQuery = "",
    SellThreshold = 15,
    
    SelectedEgg = "All Eggs",
    PlacePosition = "Good Position",
    AutoPlaceEgg = false,
    MaxEggPlace = 13,
    FarmEggCount = 0,
    
    -- Auto Hatch (Default OFF - Mutlak hanya jalan saat tombol START ditekan)
    AutoHatch = false,
    DelayEquip = 0,
    DelayUnequip = 1,
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
    
    PetMinigames = false,
    AutoPickUpPet = false,
    AutoPlacePet = false,
    AutoNightmare = false,
    AutoElephant = false,
    AutoPetBoost = false,
    
    Walkspeed = false,
    InfJump = false,
    Noclip = false,
    AntiAfk = true,
    SpeedVal = 42
}

-- =========================================================================
-- [2] PENDETEKSI KEBUN & Can_Plant RESMI (LOCKED & UNTOUCHED)
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

-- =========================================================================
-- [3] ALGORITMA 13 TITIK TELUR (100% PRESET DI DALAM Can_Plant - LOCKED)
-- =========================================================================
local function Generate13EggPositions(mode: string): table
    local positions = {}
    local canPlants = GetCanPlantParts()
    if #canPlants == 0 then return positions end

    table.sort(canPlants, function(a, b)
        return a.Position.X < b.Position.X
    end)

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
        if landIdx == #targetLands then
            countForThis = totalSlots - #positions
        end

        if countForThis > 0 then
            local zStep = (safeZ * 2) / (countForThis + 1)
            local localX = (landIdx == 1) and (safeX - 0.5) or (-safeX + 0.5)
            
            for i = 1, countForThis do
                local localZ = -safeZ + (i * zStep)
                local worldPoint = cf:PointToWorldSpace(Vector3.new(localX, topY, localZ))
                table.insert(positions, worldPoint)
                if #positions >= 13 then break end
            end
        end

        if #positions >= 13 then break end
    end

    return positions
end

-- =========================================================================
-- [4] SCANNER TELUR DI Objects_Physical (LOCKED)
-- =========================================================================
local function GetPlacedEggsInFarm(): table
    local placed = {}
    local farm = GetFarm()
    if not farm then return placed end

    local imp = farm:FindFirstChild("Important")
    local objPhysical = imp and imp:FindFirstChild("Objects_Physical")
    if not objPhysical then return placed end

    for _, obj in ipairs(objPhysical:GetChildren()) do
        if obj.Name == "PetEgg" or obj.Name:lower():find("egg") then
            local pos = nil
            local hitBox = obj:FindFirstChild("HitBox")
            if hitBox and hitBox:IsA("BasePart") then
                pos = hitBox.Position
            elseif obj:IsA("BasePart") then
                pos = obj.Position
            else
                pos = obj:GetPivot().Position
            end

            if pos then
                table.insert(placed, { Instance = obj, Position = pos })
            end
        end
    end
    return placed
end

-- =========================================================================
-- [5] PURE SEEDS & PURE EGGS FILTER (LOCKED)
-- =========================================================================
local BLACKLISTED_KEYWORDS = {
    "shard", "pack", "bundle", "crate", "chest", "box", "gift", "present",
    "ticket", "token", "pass", "badge", "coupon", "potion", "elixir", 
    "scroll", "book", "tome", "watering can", "sprinkler", "shovel", 
    "trowel", "sickle", "hoe", "basket", "fishing rod", "rod", "bug net", 
    "net", "fertilizer", "key", "lantern", "scythe", "shears", "gloves", 
    "sword", "hammer", "pickaxe"
}

local function isPureSeed(tool: Tool): boolean
    if not tool:IsA("Tool") then return false end
    if tool:FindFirstChild("Item_String") then return false end
    if tool:FindFirstChild("EggData") or tool:FindFirstChild("PetData") then return false end

    local nameLower = tool.Name:lower()
    if nameLower:find("pet") and not nameLower:find("petunia") then return false end
    if nameLower:find("egg") and not nameLower:find("eggplant") then return false end

    for _, kw in ipairs(BLACKLISTED_KEYWORDS) do
        if nameLower:find(kw) then return false end
    end
    return true
end

local function GetSeedInfo(tool: Tool)
    if not isPureSeed(tool) then return nil end
    local plantNameVal = tool:FindFirstChild("Plant_Name")
    local numbersVal = tool:FindFirstChild("Numbers")
    local cleanName = ""
    local count = 1

    if plantNameVal and plantNameVal:IsA("ValueBase") and tostring(plantNameVal.Value) ~= "" then
        cleanName = tostring(plantNameVal.Value)
    elseif tool:GetAttribute("Plant_Name") then
        cleanName = tostring(tool:GetAttribute("Plant_Name"))
    elseif tool:GetAttribute("Seed") then
        cleanName = tostring(tool:GetAttribute("Seed"))
    else
        cleanName = tool.Name:gsub("%[.-%]", ""):gsub(" Seed", ""):gsub("Seed", ""):gsub("^%s*(.-)%s*$", "%1")
    end

    if cleanName == "" or cleanName:lower():find("shard") or cleanName:lower():find("pack") then return nil end

    if numbersVal and numbersVal:IsA("ValueBase") and tonumber(numbersVal.Value) then
        count = tonumber(numbersVal.Value)
    else
        local bracketCount = tool.Name:match("%[X(%d+)%]") or tool.Name:match("%[(%d+)%]")
        if bracketCount then count = tonumber(bracketCount) or 1 end
    end
    return cleanName, count
end

local function GetOwnedSeeds(): table
    local seeds = {}
    local function scan(parent)
        if not parent then return end
        for _, tool in ipairs(parent:GetChildren()) do
            if tool:IsA("Tool") then
                local plantName, count = GetSeedInfo(tool)
                if plantName then
                    seeds[plantName] = { Name = plantName, ToolName = tool.Name, Count = count, Tool = tool }
                end
            end
        end
    end
    scan(LocalPlayer:FindFirstChild("Backpack"))
    scan(LocalPlayer.Character)
    return seeds
end

local function isPureEgg(tool: Tool): boolean
    if not tool:IsA("Tool") then return false end
    local nameLower = tool.Name:lower()
    if nameLower:find("seed") then return false end
    if tool:FindFirstChild("Plant_Name") or tool:GetAttribute("Plant_Name") or tool:GetAttribute("Seed") then return false end
    if tool:FindFirstChild("Item_String") then return false end
    if nameLower:find("eggfruit") or nameLower:find("eggplant") then return false end
    for _, kw in ipairs(BLACKLISTED_KEYWORDS) do if nameLower:find(kw) then return false end end
    return tool:FindFirstChild("PetEggToolLocal") or tool:FindFirstChild("EggData") or nameLower:find("egg")
end

local function cleanEggTitle(rawName: string): string
    return rawName:gsub("%[.-%]", ""):gsub("%s*[xX]%d+$", ""):gsub("^%s*(.-)%s*$", "%1")
end

local function GetPureEggsInBackpack()
    local eggs = {}
    local bp, ch = LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character
    local function check(p)
        if not p then return end
        for _, item in ipairs(p:GetChildren()) do
            if isPureEgg(item) then table.insert(eggs, item) end
        end
    end
    check(bp)
    check(ch)
    return eggs
end

local function EquipCheck(Tool: Tool)
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    if not Humanoid or not Backpack or not Tool then return end
    if Tool.Parent == Backpack then
        Humanoid:EquipTool(Tool)
        task.wait(0.12)
    end
end

-- =========================================================================
-- [6] LOOP WORKER AUTO PLACE EGG (LOCKED)
-- =========================================================================
local isPlacingEgg = false

task.spawn(function()
    while true do
        local placed = GetPlacedEggsInFarm()
        State.FarmEggCount = #placed

        if State.AutoPlaceEgg and not isPlacingEgg then
            local maxLimit = State.MaxEggPlace

            if State.FarmEggCount < maxLimit then
                local eggs = GetPureEggsInBackpack()
                local canPlants = GetCanPlantParts()

                if #eggs > 0 and #canPlants > 0 and PetEggService then
                    local targetSlots = Generate13EggPositions(State.PlacePosition)
                    local currentPlaced = GetPlacedEggsInFarm()

                    local activeTool = nil
                    for _, tool in ipairs(eggs) do
                        local cTitle = cleanEggTitle(tool.Name)
                        if State.SelectedEgg == "All Eggs" or cTitle:lower() == State.SelectedEgg:lower() then
                            activeTool = tool
                            break
                        end
                    end

                    if activeTool then
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
                            EquipCheck(activeTool)
                            PetEggService:FireServer("CreateEgg", targetPos)
                            task.wait(0.4)
                            isPlacingEgg = false
                        else
                            task.wait(0.5)
                        end
                    else
                        task.wait(0.5)
                    end
                else
                    task.wait(0.5)
                end
            else
                task.wait(0.6)
            end
        else
            task.wait(0.3)
        end
    end
end)

-- =========================================================================
-- [6B] AUTO HATCH ENGINE (STEP 2 MANUAL ROTATION PIPELINE)
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

local function EquipSelectedTeam(roleName: string)
    local selectedUUIDs = State.SelectedTeamPets[roleName] or {}
    local okService, petService = pcall(function() return require(ReplicatedStorage.Modules.PetServices.PetsService) end)
    
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
        if State.AutoHatch and not isHatchingCycle then
            local allPets = GetAllInventoryPets()
            
            if #allPets >= State.AutoSellAtCount then
                isHatchingCycle = true
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

-- Auto Plant & Harvest Worker (Locked)
task.spawn(function()
    while true do
        if State.AutoPlant then
            local owned = GetOwnedSeeds()
            local activeData = nil
            if State.SelectedSeed ~= "" and owned[State.SelectedSeed] and owned[State.SelectedSeed].Count > 0 then
                activeData = owned[State.SelectedSeed]
            else
                for sName, sData in pairs(owned) do
                    if sData.Count > 0 then
                        State.SelectedSeed = sName
                        activeData = sData
                        break
                    end
                end
            end

            if activeData and activeData.Tool and activeData.Count > 0 then
                EquipCheck(activeData.Tool)
                if State.PlantMode == "UnderPlayer" then
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root and Plant_RE then
                        Plant_RE:FireServer(Vector3.new(root.Position.X, 0.135, root.Position.Z), activeData.Name)
                    end
                elseif State.PlantMode == "RandomFarm" then
                    local canPlants = GetCanPlantParts()
                    if #canPlants > 0 and Plant_RE then
                        local land = canPlants[math.random(1, #canPlants)]
                        local cf = land.CFrame
                        local sz = land.Size
                        local rx = (math.random() - 0.5) * (sz.X - 2)
                        local rz = (math.random() - 0.5) * (sz.Z - 2)
                        local randPoint = cf:PointToWorldSpace(Vector3.new(rx, (sz.Y / 2) + 0.135, rz))
                        Plant_RE:FireServer(randPoint, activeData.Name)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if State.AutoHarvest then
            local farm = GetFarm()
            local imp = farm and farm:FindFirstChild("Important")
            local plantsPhysical = imp and imp:FindFirstChild("Plants_Physical")
            if plantsPhysical then
                local readyPrompts = {}
                for _, plant in ipairs(plantsPhysical:GetChildren()) do
                    if not State.AutoHarvest then break end
                    local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then table.insert(readyPrompts, prompt) end
                end

                for _, prompt in ipairs(readyPrompts) do
                    if not State.AutoHarvest then break end
                    if prompt and prompt.Parent and prompt.Enabled then
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

local IsSelling = false
local function SellInventory()
    if IsSelling or not Sell_Inventory or not State.AutoSell then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local sheckles = leaderstats and leaderstats:FindFirstChild("Sheckles")
    if not root then return end

    IsSelling = true
    local oldPos = root.CFrame
    local prevCash = sheckles and sheckles.Value or 0

    root.CFrame = CFrame.new(62, 4, -26)
    task.wait(0.2)

    local tries = 0
    while tries < 8 and State.AutoSell do
        Sell_Inventory:FireServer()
        task.wait(0.2)
        if sheckles and sheckles.Value ~= prevCash then break end
        tries = tries + 1
    end

    root.CFrame = oldPos
    task.wait(0.2)
    IsSelling = false
end

local function getCropCount()
    local count = 0
    local bp, ch = LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character
    if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and t:FindFirstChild("Item_String") then count = count + 1 end end end
    if ch then for _, t in ipairs(ch:GetChildren()) do if t:IsA("Tool") and t:FindFirstChild("Item_String") then count = count + 1 end end end
    return count
end

task.spawn(function()
    while true do
        if State.AutoSell and not IsSelling then
            if getCropCount() >= State.SellThreshold then SellInventory() end
        end
        task.wait(1)
    end
end)

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

-- =============================================================
-- [7] UI VISUAL DESIGN (LOCKED: COMPACT 620 x 400 PX)
-- =============================================================
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

local CoreGui = game:GetService("CoreGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZyloHub_v3_5_FullMaster"
ScreenGui.ResetOnSpawn = false

if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = CoreGui
end

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

local Main = Instance.new("Frame")
Main.Name = "MainWindow"
Main.Size = UDim2.new(0, 620, 0, 400)
Main.Position = UDim2.new(0.5, -310, 0.5, -200)
Main.BackgroundColor3 = C_BG
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local MainBorder = Instance.new("UIStroke", Main)
MainBorder.Color = Color3.fromRGB(50, 40, 95)
MainBorder.Thickness = 1.5

local function toggleUI() Main.Visible = not Main.Visible end
FloatBtn.MouseButton1Click:Connect(toggleUI)

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
Dot.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
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

-- =============================================================
-- [TAB 3: PETS PAGE - ACCORDION SYSTEM & AUTO PLACE EGG]
-- =============================================================
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

-- Accordion 1: Auto Place Egg (Master Asli)
local accPlaceEgg, bodyPlaceEgg = createPetAccordion("Auto Place Egg", true, 200)

local peLayout = Instance.new("UIListLayout", bodyPlaceEgg)
peLayout.SortOrder = Enum.SortOrder.LayoutOrder
peLayout.Padding = UDim.new(0, 1)

-- Row 1: Select Egg
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

local seDropFrame = Instance.new("Frame", Main)
seDropFrame.Size = UDim2.new(0, 175, 0, 135)
seDropFrame.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
seDropFrame.Visible = false
seDropFrame.ZIndex = 50
Instance.new("UICorner", seDropFrame).CornerRadius = UDim.new(0, 8)
local seDfStroke = Instance.new("UIStroke", seDropFrame)
seDfStroke.Color = C_PURPLE
seDfStroke.Thickness = 1.5

local seDropScroll = Instance.new("ScrollingFrame", seDropFrame)
seDropScroll.Size = UDim2.new(1, 0, 1, 0)
seDropScroll.BackgroundTransparency = 1
seDropScroll.ScrollBarThickness = 2
seDropScroll.ZIndex = 51
local seDropList = Instance.new("UIListLayout", seDropScroll)
seDropList.Padding = UDim.new(0, 2)
Instance.new("UIPadding", seDropScroll).PaddingTop = UDim.new(0, 4)

local function refreshEggOptions()
    for _, c in ipairs(seDropScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    local eggs = GetPureEggsInBackpack()
    local eggCounts = {}
    local eggOrder = { "All Eggs" }

    for _, egg in ipairs(eggs) do
        local cleanName = cleanEggTitle(egg.Name)
        if not eggCounts[cleanName] then
            eggCounts[cleanName] = 0
            table.insert(eggOrder, cleanName)
        end

        local numVal = egg:FindFirstChild("Numbers")
        local cnt = 1
        if numVal and numVal:IsA("ValueBase") and tonumber(numVal.Value) then
            cnt = tonumber(numVal.Value)
        else
            local b = egg.Name:match("%[X(%d+)%]") or egg.Name:match("%[(%d+)%]") or egg.Name:match("[xX](%d+)")
            if b then cnt = tonumber(b) or 1 end
        end
        eggCounts[cleanName] = eggCounts[cleanName] + cnt
    end

    for _, opt in ipairs(eggOrder) do
        local displayTitle = opt
        if opt ~= "All Eggs" and eggCounts[opt] then
            displayTitle = opt .. " x" .. tostring(eggCounts[opt])
        end

        local b = Instance.new("TextButton", seDropScroll)
        b.Size = UDim2.new(1, -8, 0, 24)
        b.Position = UDim2.new(0, 4, 0, 0)
        b.BackgroundColor3 = (State.SelectedEgg == opt) and C_PURPLE or Color3.fromRGB(22, 28, 52)
        b.Text = "  " .. displayTitle
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 8.5
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.ZIndex = 52
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)

        b.MouseButton1Click:Connect(function()
            State.SelectedEgg = opt
            seBtn.Text = (opt == "All Eggs" and "Select Options  v" or (displayTitle .. "  v"))
            seDropFrame.Visible = false
        end)
    end
    seDropScroll.CanvasSize = UDim2.new(0, 0, 0, #eggOrder * 26 + 8)
end

seBtn.MouseButton1Click:Connect(function()
    refreshEggOptions()
    local absPos = seBtn.AbsolutePosition
    local mainPos = Main.AbsolutePosition
    seDropFrame.Position = UDim2.new(0, absPos.X - mainPos.X - 10, 0, absPos.Y - mainPos.Y + 30)
    seDropFrame.Visible = not seDropFrame.Visible
end)

-- Row 2: Select Place Position
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

-- Row 3: Auto Place Egg Toggle
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

-- Row 4: Max Egg Place (Custom)
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
meSub.Text = "Maksimal 13 butir telur sesuai slot lahan."
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
            local maxStr = tostring(State.MaxEggPlace)
            meSub.Text = "Di Kebun: " .. tostring(count) .. " / " .. maxStr .. " telur (PetEggService Active)"
            meSub.TextColor3 = (count >= State.MaxEggPlace) and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(120, 180, 255)
        end
        task.wait(0.3)
    end
end)

-- =============================================================
-- [ACCORDION 2: AUTO HATCH - PERSIS SESUAI GAMBAR DISCORD]
-- =============================================================
local accHatch, bodyHatch = createPetAccordion("Auto Hatch", true, 345)

-- Baris 1: 5 Sub-Tab Kapsul (Main, Bronto, Hatch, Sell, Config, Gear)
local HatchSubTabs = Instance.new("Frame", bodyHatch)
HatchSubTabs.Size = UDim2.new(1, -20, 0, 26)
HatchSubTabs.Position = UDim2.new(0, 10, 0, 6)
HatchSubTabs.BackgroundTransparency = 1

local HstLayout = Instance.new("UIListLayout", HatchSubTabs)
HstLayout.FillDirection = Enum.FillDirection.Horizontal
HstLayout.Padding = UDim.new(0, 4)

local teamTabBtns = {}
local function createTeamSubTab(name, flexWidth)
    local b = Instance.new("TextButton", HatchSubTabs)
    b.Size = UDim2.new(flexWidth or 0.18, 0, 1, 0)
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
local tabGear   = createTeamSubTab("⚙️", 0.08)

-- Container Utama Pengaturan Tim
local TeamSettingsContainer = Instance.new("Frame", bodyHatch)
TeamSettingsContainer.Position = UDim2.new(0, 10, 0, 36)
TeamSettingsContainer.Size = UDim2.new(1, -20, 0, 260)
TeamSettingsContainer.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
Instance.new("UICorner", TeamSettingsContainer).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", TeamSettingsContainer).Color = C_STROKE

local ViewRole = Instance.new("Frame", TeamSettingsContainer)
ViewRole.Size = UDim2.new(1, 0, 1, 0)
ViewRole.BackgroundTransparency = 1

-- Header Accordion Sub: "( Main Team ) Delay Settings" + Dropdown ▼
local DelayHeader = Instance.new("Frame", ViewRole)
DelayHeader.Position = UDim2.new(0, 10, 0, 6)
DelayHeader.Size = UDim2.new(1, -20, 0, 22)
DelayHeader.BackgroundColor3 = C_CARD_2
Instance.new("UICorner", DelayHeader).CornerRadius = UDim.new(0, 5)
Instance.new("UIStroke", DelayHeader).Color = C_STROKE

local RoleTitle = Instance.new("TextLabel", DelayHeader)
RoleTitle.Position = UDim2.new(0, 8, 0, 0)
RoleTitle.Size = UDim2.new(1, -30, 1, 0)
RoleTitle.BackgroundTransparency = 1
RoleTitle.Text = "( Main Team ) Delay Settings"
RoleTitle.TextColor3 = C_PURPLE_L
RoleTitle.Font = Enum.Font.GothamBold
RoleTitle.TextSize = 9
RoleTitle.TextXAlignment = Enum.TextXAlignment.Left

local DropArrow = Instance.new("TextLabel", DelayHeader)
DropArrow.Position = UDim2.new(1, -22, 0, 0)
DropArrow.Size = UDim2.new(0, 16, 1, 0)
DropArrow.BackgroundTransparency = 1
DropArrow.Text = "▼"
DropArrow.TextColor3 = C_TEXT_M
DropArrow.Font = Enum.Font.GothamBold
DropArrow.TextSize = 8

-- Summary Bar (Jumlah Pet Terpilih Per-Role Sesuai Gambar)
local SummaryBar = Instance.new("TextLabel", ViewRole)
SummaryBar.Position = UDim2.new(0, 12, 0, 32)
SummaryBar.Size = UDim2.new(1, -24, 0, 14)
SummaryBar.BackgroundTransparency = 1
SummaryBar.Text = "🐾 Main (0)   🦕 Bronto (0)   🥚 Hatch (0)   💰 Sell (0)"
SummaryBar.TextColor3 = C_TEXT_M
SummaryBar.Font = Enum.Font.GothamBold
SummaryBar.TextSize = 8
SummaryBar.TextXAlignment = Enum.TextXAlignment.Left

local function updateSummaryBar()
    local function countMap(m)
        local c = 0
        for _ in pairs(m) do c = c + 1 end
        return c
    end
    local mC = countMap(State.SelectedTeamPets["Main Team"])
    local bC = countMap(State.SelectedTeamPets["Bronto Team"])
    local hC = countMap(State.SelectedTeamPets["Hatch Team"])
    local sC = countMap(State.SelectedTeamPets["Sell Team"])
    SummaryBar.Text = string.format("🐾 Main (%d)   🦕 Bronto (%d)   🥚 Hatch (%d)   💰 Sell (%d)", mC, bC, hC, sC)
end

-- Delay Equip (sec)
local rowDelEquip = Instance.new("Frame", ViewRole)
rowDelEquip.Position = UDim2.new(0, 12, 0, 48)
rowDelEquip.Size = UDim2.new(1, -24, 0, 22)
rowDelEquip.BackgroundTransparency = 1

local deLbl = Instance.new("TextLabel", rowDelEquip)
deLbl.Size = UDim2.new(0.65, 0, 1, 0)
deLbl.BackgroundTransparency = 1
deLbl.Text = "Delay Equip (sec)"
deLbl.TextColor3 = C_TEXT_W
deLbl.Font = Enum.Font.GothamMedium
deLbl.TextSize = 8.5
deLbl.TextXAlignment = Enum.TextXAlignment.Left

local deBox = Instance.new("TextBox", rowDelEquip)
deBox.Position = UDim2.new(1, -45, 0, 0)
deBox.Size = UDim2.new(0, 45, 1, 0)
deBox.BackgroundColor3 = C_CARD_2
deBox.Text = tostring(State.DelayEquip)
deBox.TextColor3 = C_CYAN
deBox.Font = Enum.Font.GothamBold
deBox.TextSize = 8.5
Instance.new("UICorner", deBox).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", deBox).Color = C_STROKE
deBox:GetPropertyChangedSignal("Text"):Connect(function()
    local n = tonumber(deBox.Text)
    if n then State.DelayEquip = n end
end)

-- Delay Unequip (sec)
local rowDelUnequip = Instance.new("Frame", ViewRole)
rowDelUnequip.Position = UDim2.new(0, 12, 0, 72)
rowDelUnequip.Size = UDim2.new(1, -24, 0, 22)
rowDelUnequip.BackgroundTransparency = 1

local duLbl = Instance.new("TextLabel", rowDelUnequip)
duLbl.Size = UDim2.new(0.65, 0, 1, 0)
duLbl.BackgroundTransparency = 1
duLbl.Text = "Delay Unequip (sec)"
duLbl.TextColor3 = C_TEXT_W
duLbl.Font = Enum.Font.GothamMedium
duLbl.TextSize = 8.5
duLbl.TextXAlignment = Enum.TextXAlignment.Left

local duBox = Instance.new("TextBox", rowDelUnequip)
duBox.Position = UDim2.new(1, -45, 0, 0)
duBox.Size = UDim2.new(0, 45, 1, 0)
duBox.BackgroundColor3 = C_CARD_2
duBox.Text = tostring(State.DelayUnequip)
duBox.TextColor3 = C_CYAN
duBox.Font = Enum.Font.GothamBold
duBox.TextSize = 8.5
Instance.new("UICorner", duBox).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", duBox).Color = C_STROKE
duBox:GetPropertyChangedSignal("Text"):Connect(function()
    local n = tonumber(duBox.Text)
    if n then State.DelayUnequip = n end
end)

-- Section: Select Pet (Role Name)
local SelPetTitle = Instance.new("TextLabel", ViewRole)
SelPetTitle.Position = UDim2.new(0, 12, 0, 96)
SelPetTitle.Size = UDim2.new(1, -24, 0, 14)
SelPetTitle.BackgroundTransparency = 1
SelPetTitle.Text = "Select Pet (Main Team)"
SelPetTitle.TextColor3 = C_TEXT_W
SelPetTitle.Font = Enum.Font.GothamBold
SelPetTitle.TextSize = 8.5
SelPetTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Container Pet List + Search Box
local PetContainer = Instance.new("Frame", ViewRole)
PetContainer.Position = UDim2.new(0, 10, 0, 112)
PetContainer.Size = UDim2.new(1, -20, 0, 110)
PetContainer.BackgroundColor3 = Color3.fromRGB(8, 10, 20)
Instance.new("UICorner", PetContainer).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", PetContainer).Color = C_STROKE

local SearchInput = Instance.new("TextBox", PetContainer)
SearchInput.Position = UDim2.new(0, 8, 0, 6)
SearchInput.Size = UDim2.new(1, -16, 0, 20)
SearchInput.BackgroundColor3 = C_CARD_2
SearchInput.PlaceholderText = "Search..."
SearchInput.PlaceholderColor3 = C_TEXT_M
SearchInput.Text = ""
SearchInput.TextColor3 = C_TEXT_W
SearchInput.Font = Enum.Font.GothamMedium
SearchInput.TextSize = 8
Instance.new("UICorner", SearchInput).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", SearchInput).Color = C_STROKE

local PetListScroll = Instance.new("ScrollingFrame", PetContainer)
PetListScroll.Position = UDim2.new(0, 8, 0, 28)
PetListScroll.Size = UDim2.new(1, -16, 0, 76)
PetListScroll.BackgroundTransparency = 1
PetListScroll.ScrollBarThickness = 2
PetListScroll.ScrollBarImageColor3 = C_PURPLE
PetListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local PlsLayout = Instance.new("UIListLayout", PetListScroll)
PlsLayout.Padding = UDim.new(0, 2)

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
            btn.Size = UDim2.new(1, -2, 0, 22)
            
            if isSelected then
                btn.BackgroundColor3 = C_PURPLE
            else
                btn.BackgroundColor3 = pet.IsFavorite and Color3.fromRGB(24, 28, 52) or Color3.fromRGB(14, 18, 34)
            end
            
            local favStar = pet.IsFavorite and "⭐ " or ""
            btn.Text = "  " .. favStar .. petDisplay
            btn.TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or (pet.IsFavorite and Color3.fromRGB(255, 215, 0) or C_TEXT_W)
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 8
            btn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            local bStroke = Instance.new("UIStroke", btn)
            bStroke.Color = isSelected and C_PURPLE_L or (pet.IsFavorite and Color3.fromRGB(150, 120, 40) or C_STROKE)
            
            btn.MouseButton1Click:Connect(function()
                if selectedMap[pet.UUID] then
                    selectedMap[pet.UUID] = nil
                else
                    selectedMap[pet.UUID] = true
                end
                updateSummaryBar()
                refreshPetListUI()
            end)
        end
    end
    PetListScroll.CanvasSize = UDim2.new(0, 0, 0, count * 24)
end

SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    State.SearchPetQuery = SearchInput.Text
    refreshPetListUI()
end)

-- Tombol Mandiri di Bawah: ⚡ START & STOP (Persis Sesuai Gambar Discord)
local ActRow = Instance.new("Frame", ViewRole)
ActRow.Position = UDim2.new(0, 10, 1, -30)
ActRow.Size = UDim2.new(1, -20, 0, 24)
ActRow.BackgroundTransparency = 1

local StartHatchBtn = Instance.new("TextButton", ActRow)
StartHatchBtn.Size = UDim2.new(0.48, 0, 1, 0)
StartHatchBtn.BackgroundColor3 = State.AutoHatch and Color3.fromRGB(0, 255, 170) or C_PURPLE
StartHatchBtn.Text = State.AutoHatch and "⚡ RUNNING" or "⚡ START"
StartHatchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartHatchBtn.Font = Enum.Font.GothamBold
StartHatchBtn.TextSize = 9
Instance.new("UICorner", StartHatchBtn).CornerRadius = UDim.new(0, 5)

local StopHatchBtn = Instance.new("TextButton", ActRow)
StopHatchBtn.Position = UDim2.new(0.52, 0, 0, 0)
StopHatchBtn.Size = UDim2.new(0.48, 0, 1, 0)
StopHatchBtn.BackgroundColor3 = C_CARD_2
StopHatchBtn.Text = "STOP"
StopHatchBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
StopHatchBtn.Font = Enum.Font.GothamBold
StopHatchBtn.TextSize = 9
Instance.new("UICorner", StopHatchBtn).CornerRadius = UDim.new(0, 5)

StartHatchBtn.MouseButton1Click:Connect(function()
    State.AutoHatch = true
    StartHatchBtn.Text = "⚡ RUNNING"
    StartHatchBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
end)

StopHatchBtn.MouseButton1Click:Connect(function()
    State.AutoHatch = false
    StartHatchBtn.Text = "⚡ START"
    StartHatchBtn.BackgroundColor3 = C_PURPLE
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

    if name == "Config" or name == "⚙️" then
        ViewRole.Visible = false
        ViewConfig.Visible = true
    else
        ViewRole.Visible = true
        ViewConfig.Visible = false
        RoleTitle.Text = "( " .. name .. " ) Delay Settings"
        SelPetTitle.Text = "Select Pet (" .. name .. ")"
        refreshPetListUI()
    end
end

tabMain.MouseButton1Click:Connect(function() switchTeamTab("Main Team") end)
tabBronto.MouseButton1Click:Connect(function() switchTeamTab("Bronto Team") end)
tabHatchT.MouseButton1Click:Connect(function() switchTeamTab("Hatch Team") end)
tabSellT.MouseButton1Click:Connect(function() switchTeamTab("Sell Team") end)
tabConfig.MouseButton1Click:Connect(function() switchTeamTab("Config") end)
tabGear.MouseButton1Click:Connect(function() switchTeamTab("Config") end)

-- Accordion Pet Lainnya (2-9)
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
FarmCard1.Size = UDim2.new(1, 0, 0, 300)
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
if mFarm then
    FarmDetect.Text = "✅ Lahan: " .. mFarm.Name .. " (Can_Plant Terhubung)"
    FarmDetect.TextColor3 = Color3.fromRGB(0, 255, 170)
else
    FarmDetect.Text = "⚠️ Lahan Belum Ditemukan di Workspace.Farm"
    FarmDetect.TextColor3 = Color3.fromRGB(255, 100, 100)
end
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
local MbStroke1 = Instance.new("UIStroke", ModeBtn1)
MbStroke1.Color = (State.PlantMode == "UnderPlayer") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 55, 80)

local ModeBtn2 = Instance.new("TextButton", ModeRow)
ModeBtn2.Position = UDim2.new(0.515, 0, 0, 0)
ModeBtn2.Size = UDim2.new(0.485, 0, 1, 0)
ModeBtn2.BackgroundColor3 = (State.PlantMode == "RandomFarm") and C_PURPLE or C_CARD_2
ModeBtn2.Text = "🎲 Random di Kebun"
ModeBtn2.TextColor3 = (State.PlantMode == "RandomFarm") and Color3.fromRGB(255, 255, 255) or C_TEXT_M
ModeBtn2.Font = Enum.Font.GothamBold
ModeBtn2.TextSize = 9
Instance.new("UICorner", ModeBtn2).CornerRadius = UDim.new(0, 6)
local MbStroke2 = Instance.new("UIStroke", ModeBtn2)
MbStroke2.Color = (State.PlantMode == "RandomFarm") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 55, 80)

local function updateModeButtons()
    ModeBtn1.BackgroundColor3 = (State.PlantMode == "UnderPlayer") and C_PURPLE or C_CARD_2
    ModeBtn1.TextColor3 = (State.PlantMode == "UnderPlayer") and Color3.fromRGB(255, 255, 255) or C_TEXT_M
    MbStroke1.Color = (State.PlantMode == "UnderPlayer") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 55, 80)

    ModeBtn2.BackgroundColor3 = (State.PlantMode == "RandomFarm") and C_PURPLE or C_CARD_2
    ModeBtn2.TextColor3 = (State.PlantMode == "RandomFarm") and Color3.fromRGB(255, 255, 255) or C_TEXT_M
    MbStroke2.Color = (State.PlantMode == "RandomFarm") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 55, 80)
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

local SeedHeaderRow = Instance.new("Frame", FarmCard1)
SeedHeaderRow.Position = UDim2.new(0, 12, 0, 150)
SeedHeaderRow.Size = UDim2.new(1, -24, 0, 24)
SeedHeaderRow.BackgroundTransparency = 1

local SeedSelectTitle = Instance.new("TextLabel", SeedHeaderRow)
SeedSelectTitle.Size = UDim2.new(0.55, 0, 1, 0)
SeedSelectTitle.BackgroundTransparency = 1
SeedSelectTitle.Text = "Pilih Benih dari Inventory (Klik):"
SeedSelectTitle.TextColor3 = C_CYAN
SeedSelectTitle.Font = Enum.Font.GothamBold
SeedSelectTitle.TextSize = 9.5
SeedSelectTitle.TextXAlignment = Enum.TextXAlignment.Left

local SearchBox = Instance.new("TextBox", SeedHeaderRow)
SearchBox.Position = UDim2.new(0.55, 5, 0, 0)
SearchBox.Size = UDim2.new(0.45, -5, 1, 0)
SearchBox.BackgroundColor3 = C_CARD_2
SearchBox.PlaceholderText = "🔍 Search seed..."
SearchBox.PlaceholderColor3 = C_TEXT_M
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.Font = Enum.Font.GothamMedium
SearchBox.TextSize = 9
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)
local SbStroke = Instance.new("UIStroke", SearchBox)
SbStroke.Color = Color3.fromRGB(60, 70, 100)

local SeedScroll = Instance.new("ScrollingFrame", FarmCard1)
SeedScroll.Position = UDim2.new(0, 12, 0, 178)
SeedScroll.Size = UDim2.new(1, -24, 0, 78)
SeedScroll.BackgroundColor3 = C_CARD_2
SeedScroll.ScrollBarThickness = 3
SeedScroll.ScrollBarImageColor3 = C_PURPLE
Instance.new("UICorner", SeedScroll).CornerRadius = UDim.new(0, 6)

local SclLayout = Instance.new("UIListLayout", SeedScroll)
SclLayout.FillDirection = Enum.FillDirection.Horizontal
SclLayout.Padding = UDim.new(0, 6)
local SclPad = Instance.new("UIPadding", SeedScroll)
SclPad.PaddingTop = UDim.new(0, 8)
SclPad.PaddingLeft = UDim.new(0, 8)
SclPad.PaddingRight = UDim.new(0, 8)

local function refreshSeedChips()
    for _, c in ipairs(SeedScroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end

    local owned = GetOwnedSeeds()
    local count = 0
    local query = State.SearchSeedQuery:lower()

    for sName, sData in pairs(owned) do
        if query == "" or sName:lower():find(query) or sData.ToolName:lower():find(query) then
            count = count + 1
            local isSelected = (State.SelectedSeed == sName) or (State.SelectedSeed == "" and count == 1)
            if isSelected and State.SelectedSeed == "" then State.SelectedSeed = sName end

            local chip = Instance.new("TextButton", SeedScroll)
            chip.Size = UDim2.new(0, 120, 0, 56)
            chip.BackgroundColor3 = isSelected and C_PURPLE or Color3.fromRGB(24, 30, 48)
            chip.Text = ""
            Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 6)
            local cStroke = Instance.new("UIStroke", chip)
            cStroke.Color = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 55, 80)

            local icon = Instance.new("TextLabel", chip)
            icon.Position = UDim2.new(0, 6, 0, 8)
            icon.Size = UDim2.new(0, 16, 0, 16)
            icon.BackgroundTransparency = 1
            icon.Text = "🌱"
            icon.TextSize = 12

            local nameL = Instance.new("TextLabel", chip)
            nameL.Position = UDim2.new(0, 24, 0, 6)
            nameL.Size = UDim2.new(1, -28, 0, 24)
            nameL.BackgroundTransparency = 1
            nameL.Text = sData.ToolName
            nameL.TextColor3 = C_TEXT_W
            nameL.Font = Enum.Font.GothamBold
            nameL.TextSize = 8.5
            nameL.TextWrapped = true
            nameL.TextXAlignment = Enum.TextXAlignment.Left

            local qtyL = Instance.new("TextLabel", chip)
            qtyL.Position = UDim2.new(0, 24, 0, 32)
            qtyL.Size = UDim2.new(1, -28, 0, 14)
            qtyL.BackgroundTransparency = 1
            qtyL.Text = "Stok: " .. tostring(sData.Count) .. "x"
            qtyL.TextColor3 = isSelected and Color3.fromRGB(220, 240, 255) or C_TEXT_M
            qtyL.Font = Enum.Font.Gotham
            qtyL.TextSize = 8
            qtyL.TextXAlignment = Enum.TextXAlignment.Left

            chip.MouseButton1Click:Connect(function()
                State.SelectedSeed = sName
                refreshSeedChips()
            end)
        end
    end

    if count == 0 then
        local empty = Instance.new("TextLabel", SeedScroll)
        empty.Size = UDim2.new(1, 0, 1, 0)
        empty.BackgroundTransparency = 1
        empty.Text = (query ~= "") and "Tidak ada benih cocok: '" .. State.SearchSeedQuery .. "'" or "Tidak ada benih murni di Backpack."
        empty.TextColor3 = Color3.fromRGB(255, 120, 120)
        empty.Font = Enum.Font.GothamMedium
        empty.TextSize = 8.5
        SeedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    else
        SeedScroll.CanvasSize = UDim2.new(0, count * 128, 0, 0)
    end
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    State.SearchSeedQuery = SearchBox.Text
    refreshSeedChips()
end)

task.defer(refreshSeedChips)

local RefSeedBtn = Instance.new("TextButton", FarmCard1)
RefSeedBtn.Position = UDim2.new(0, 12, 0, 264)
RefSeedBtn.Size = UDim2.new(1, -24, 0, 24)
RefSeedBtn.BackgroundColor3 = Color3.fromRGB(22, 28, 44)
RefSeedBtn.Text = "🔄 Refresh Inventaris Benih Sekarang"
RefSeedBtn.TextColor3 = C_CYAN
RefSeedBtn.Font = Enum.Font.GothamBold
RefSeedBtn.TextSize = 9
Instance.new("UICorner", RefSeedBtn).CornerRadius = UDim.new(0, 6)
RefSeedBtn.MouseButton1Click:Connect(refreshSeedChips)

local FarmCard2 = Instance.new("Frame", PageFarm)
FarmCard2.Size = UDim2.new(1, 0, 0, 125)
FarmCard2.BackgroundColor3 = C_CARD
Instance.new("UICorner", FarmCard2).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", FarmCard2).Color = C_STROKE

local SellTitle = Instance.new("TextLabel", FarmCard2)
SellTitle.Position = UDim2.new(0, 12, 0, 10)
SellTitle.Size = UDim2.new(1, -24, 0, 14)
SellTitle.BackgroundTransparency = 1
SellTitle.Text = "💰  AUTO SELL & MERCHANT ENGINE"
SellTitle.TextColor3 = C_CYAN
SellTitle.Font = Enum.Font.GothamBold
SellTitle.TextSize = 11
SellTitle.TextXAlignment = Enum.TextXAlignment.Left

local SellRow = Instance.new("Frame", FarmCard2)
SellRow.Position = UDim2.new(0, 12, 0, 32)
SellRow.Size = UDim2.new(1, -24, 0, 32)
SellRow.BackgroundColor3 = C_CARD_2
Instance.new("UICorner", SellRow).CornerRadius = UDim.new(0, 6)

local SrLabel = Instance.new("TextLabel", SellRow)
SrLabel.Position = UDim2.new(0, 10, 0, 0)
SrLabel.Size = UDim2.new(1, -50, 1, 0)
SrLabel.BackgroundTransparency = 1
SrLabel.Text = "Auto Sell Saat Panenan Mencapai Batas (Threshold)"
SrLabel.TextColor3 = C_TEXT_W
SrLabel.Font = Enum.Font.GothamMedium
SrLabel.TextSize = 9.5
SrLabel.TextXAlignment = Enum.TextXAlignment.Left
local SrSwitch = createPillSwitch(SellRow, State.AutoSell, function(v) State.AutoSell = v end)
SrSwitch.Position = UDim2.new(1, -40, 0.5, -10)

local ManualSellBtn = Instance.new("TextButton", FarmCard2)
ManualSellBtn.Position = UDim2.new(0, 12, 0, 74)
ManualSellBtn.Size = UDim2.new(1, -24, 0, 34)
ManualSellBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 54)
ManualSellBtn.Text = "⚡ Jual Semua Hasil Panen Sekarang (Teleport NPC & Balik)"
ManualSellBtn.TextColor3 = C_CYAN
ManualSellBtn.Font = Enum.Font.GothamBold
ManualSellBtn.TextSize = 10
Instance.new("UICorner", ManualSellBtn).CornerRadius = UDim.new(0, 6)
local MsStroke = Instance.new("UIStroke", ManualSellBtn)
MsStroke.Color = Color3.fromRGB(0, 180, 200)

ManualSellBtn.MouseButton1Click:Connect(function()
    State.AutoSell = true
    SellInventory()
end)

-- Initial Load Pet List & Summary
refreshPetListUI()
updateSummaryBar()

Buttons["Pets"].BackgroundTransparency = 0
Buttons["Pets"].BackgroundColor3 = C_PURPLE
Buttons["Pets"].TextColor3 = Color3.fromRGB(255, 255, 255)
PagePets.Visible = true

print("[ZyloHub v3.5] Official Master Codebase + Complete Auto Hatch Discord UI Ready!")
