local modutil = require("../utils/modutil")
local UEHelpers = require("UEHelpers") 
-- Maintain the original SkillUnlock functionality
local skill_unlock_pals = require("ItemSetLua/SkillUnlock_Give")

-- New: Dynamically load and store references to item lists
local dynamicItemLists = {}

give = {}

-- router
function give.route_cmd(PlayerState, args)
    spawnItems(PlayerState, args)
end

-- processors
function spawnItems(PlayerState, args)
    for i = 2, #args do
        local itemType = args[i]
        -- Check for the specific "SkillUnlock" command
        if itemType == "SkillUnlock" then
            spawnAllSkillUnlocks(PlayerState)
        else
            -- Attempt to dynamically handle other types
            spawnDynamicItems(PlayerState, itemType)
        end
    end
end

-- Original SkillUnlock functionality preserved
function spawnAllSkillUnlocks(PlayerState)
    for _, item in ipairs(skill_unlock_pals) do
        spawnItemSingle(PlayerState, item)
    end
end

-- New function to handle dynamic item spawning
function spawnDynamicItems(PlayerState, itemType)
    if not dynamicItemLists[itemType] then
        -- Attempt to dynamically require the item list if not already loaded
        local status, itemList = pcall(require, "ItemSetLua/" .. itemType .. "_Give")
        if status then
            dynamicItemLists[itemType] = itemList
        else
            -- Fallback to spawning a single item if the module is not found
            spawnItemSingle(PlayerState, itemType)
            return
        end
    end
    
    -- Spawn all items from the dynamically loaded list
    for _, item in ipairs(dynamicItemLists[itemType]) do
        spawnItemSingle(PlayerState, item)
    end
end

function spawnItemSingle(PlayerState, item)
    if string.find(string.lower(item), "relic") then
        print(">>>>>> These are not useable Relics, Please try using '!pick relic'")
        return
    end
    if string.find(string.lower(item), "palegg") then
        print(">>>>>> These are not useable Eggs, Please try using '!pick eggs'")
        return
    end
    modutil.log("Spawning Item: " .. tostring(item))
    local quantity = 1
    if string.find(item, ":") then
        item, quantity = string.match(item, "(.*):(.*)")
    end

    -- check for special items
    if string.find(item, "techpoint") then
        wire_points(PlayerState, quantity)
        return
    end
    if string.find(item, "exp") then
        wire_exp(PlayerState, quantity)
        return
    end

    local Player = PlayerState.GetPlayerController()
    local PalPlayerState = Player.GetPalPlayerState()
    local PalPlayerInventoryData = PalPlayerState:GetInventoryData()
    PalPlayerInventoryData:RequestAddItem(FName(item), quantity, false)
end

-- Special processing for technology points and experience
function wire_points(PlayerState, quantity)
    local PalNetworkPlayerComponent = FindFirstOf("PalNetworkPlayerComponent")
    PalNetworkPlayerComponent:RequestAddTechnolgyPoint_ToServer(quantity)
end

function wire_exp(PlayerState, quantity)
    PlayerState:GrantExpForParty(quantity)
end

return give
