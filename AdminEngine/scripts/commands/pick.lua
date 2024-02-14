local modutil = require("utils/modutil")
local config = require("../config")
local UEHelpers = require("UEHelpers")

pick = {}

-- router
function pick.route_cmd(args)
    if args[2] == "common" then
        scan_pickup_items("PalMapObjectPickupItemOnLevelModel", true) -- skill fruit, stone, wood, etc
        scan_pickup_items("PalMapObjectDropItemModel", true) -- mushrooms, berries, souls, pal_drops, etc
    elseif args[2] == "all" then
        scan_pickup_items("PalMapObjectPickupItemOnLevelModel", true) -- skill fruit, stone, wood, etc
        scan_pickup_items("PalMapObjectDropItemModel", true) -- mushrooms, berries, souls, pal_drops, etc
        scan_pickup_items("PalMapObjectPalEggModel", true)
    elseif args[2] == "eggs" then
        scan_pickup_items("PalMapObjectPalEggModel", true)
    -- elseif args[2] == "treasure" then
    --     -- -- temporarily disabled while we research
    --     scan_pickup_treasure(true)
    -- elseif args[2] == "journals" then
    --     -- -- temporarily disabled while we research
    elseif args[2] == "relic" then
        source_and_pick_relic()
    elseif args[2] == "scan" then
        scan_pickup_items("", false)
    else
        modutil.log("Unknown Pick command")
    end
end

-- processors
function scan_pickup_items(searchKey, bPickup)
    local pickableItems = FindAllOf("PalMapObjectPickableItemModelBase")
    for k, item in pairs(pickableItems) do
        if item:GetFullName():find(searchKey) then
            if bPickup then
                item:RequestPickup()
            else
                modutil.log("Found: " .. tostring(item:GetFullName()))
            end
        end
    end
end

-- -- temporarily disabled while we research
-- function scan_pickup_treasure(bPickup)
--     local pickableItems = FindAllOf("PalMapObjectTreasureBoxModel") -- try the non model version
--     local playerId = modutil.GetPlayerID()
--     for k, item in pairs(pickableItems) do
--         local grade = item:GetTreasureGradeType()
--         if bPickup then
--             modutil.log("Found: [" .. tostring(grade) .. "] " .. tostring(item:GetFullName()))
--             --item.bOpened = true
--             item:RequestOpen_ServerInternal(playerId)
--             --item:TriggerOpen()
--         else
--             modutil.log("Found: " .. tostring(item:GetFullName()))
--         end
--     end
-- end

function source_and_pick_relic()
    print("source_and_pick_relic")
    PlayerController = UEHelpers:GetPlayerController()
    local pickableItems = FindAllOf("PalLevelObjectRelic") -- PalLevelObjectObtainable
    for k, item in pairs(pickableItems) do
        if not item.bPickedInClient then
            PlayerController.Pawn.PlayerState:RequestObtainLevelObject_ToServer(item)
        end
    end
end

return pick