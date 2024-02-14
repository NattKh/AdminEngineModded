local UEHelpers = require("UEHelpers")

local kismetSys = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
local lineTraceSingleFunc = StaticFindObject("/Script/Engine.KismetSystemLibrary:LineTraceSingle")

local config = require("../config")
local modutil = require("utils/modutil")

tp = {}

tp_map_to_loc_step = 462.962962963
tp_airdrop_altitude = 100000.00000000

-- router
function tp.route_cmd(Player, args)
    if #args == 1 then
        local Location = get_coords(Player)
        print(">>>>> Current Location: "..Location.X..","..Location.Y..","..Location.Z)
    else
        teleport(Player, args)
    end
end

function get_coords(Player)
    return Player.Pawn:K2_GetActorLocation()
end

function prep_coords(args)
    local search = args[2]
    local Location = {}

    -- check custom location
    if config.custom_locations[search] then
        local targetLoc = config.custom_locations[search]
        local x, y, z = string.match(targetLoc, "([^,]+),([^,]+),([^,]+)")
        Location = { X = tonumber(x), Y = tonumber(y), Z = tonumber(z)}
        return Location
    end

    -- try raw coords
    local x, y, z = string.match(args[2], "([^,]+),([^,]+),([^,]+)")
    if x and
        y and
        z then
        Location = { X = tonumber(x), Y = tonumber(y), Z = tonumber(z)}
        return Location
    end

    -- try map coords
    local x, y = string.match(args[2], "([^,]+),([^,]+)")
    if x and
        y then
        local x_loc = config.tp_step * tonumber(y) - 123467.1611767
        local y_loc = config.tp_step * tonumber(x) + 157664.55791065
        modutil.log("Airdroping => " .. x..","..y .. " => " .. x_loc..","..y_loc..","..config.tp_airdrop_altitude)
        Location = { X = tonumber(x_loc), Y = tonumber(y_loc), Z = tonumber(config.tp_airdrop_altitude)}
        return Location
    end

    print(">>>> Invalid Coordinates")
    return nil
end

local function loadLocation(Location)
    local Player = UEHelpers:GetPlayerController()
    if Location then
        local tp = Player.Transmitter.Player:RegisterRespawnLocation_ToServer(Player:GetPlayerUId(), Location)
        local PlayerHP = Player.Pawn.CharacterParameterComponent:GetHP()
        local PState = Player.PlayerState.RequestRespawn()
        Player.Pawn:ReviveCharacter_ToServer(PlayerHP)
    end
end

local function getGroundDistance(StartVec,PlayerCont)
    local PalUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
    local traceType = PalUtility:ConvertToTraceTypeQuery(1)
    local outHit = {}
    local endVec = {X = StartVec.X,Y = StartVec.Y,Z = StartVec.Z - 200000}
    local isSuccess = lineTraceSingleFunc(kismetSys, PlayerCont, StartVec, endVec, traceType, true, {}, 0, outHit,true, {}, {}, 0.0)
    return isSuccess,outHit
end

function teleport(Player, args)
    local location = prep_coords(args)
    if not location then
        return
    end

    if args[3] == "airdrop" or args[3] == "a" then
        local tp = Player.Transmitter.Player:RegisterRespawnLocation_ToServer(Player:GetPlayerUId(), location)
        local PlayerHP = Player.Pawn.CharacterParameterComponent:GetHP()
        local PState = Player.PlayerState:RequestRespawn()
        Player.Pawn:ReviveCharacter_ToServer(PlayerHP)
        return
    end

    location = {X = location.X, Y = location.Y, Z = 100000}
    loadLocation(location)
    LoopAsync(900, function()
    local PLocation = Player.Pawn:K2_GetActorLocation()
    local StartVec = {X = PLocation.X,Y = PLocation.Y,Z = PLocation.Z - 500}
    local isSuccess,outHit = getGroundDistance(StartVec,Player)
    local newZ =  location.Z - (outHit["Distance"])
    if(isSuccess and newZ > -2150) then
        location = {X = location.X, Y = location.Y, Z = newZ+50}
        loadLocation(location)
        if(Deletewaypoint) then
            LocationManager:RemoveLocalCustomLocation({A = guid.A, B = guid.B, C = guid.C, D = guid.D})
        end
    end
    return isSuccess and newZ > -2150
    end)
end




return tp