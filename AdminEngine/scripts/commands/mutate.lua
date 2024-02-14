local json = require("../libs/json")

mutate = {}

mutate.PalboxPage = 1
mutate.PalboxSlot = 1

-- helper functions
function table.contains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function mutate.get_sParam(PlayerState)
    local pal_in_storage = PlayerState:GetPalStorage():GetSlot(mutate.PalboxPage-1,mutate.PalboxSlot-1)
    if pal_in_storage == nil or pal_in_storage.Handle == nil then
        return nil
    end
    local iParam = pal_in_storage.Handle:TryGetIndividualParameter()
    if iParam == nil then
        return nil
    end
    return iParam.SaveParameter
end

-- router
function mutate.route_cmd(PlayerState, args)

    local sParam = mutate.get_sParam(PlayerState)
    if sParam == nil then
        print(">>>> Pal not found in storage at " .. tostring(mutate.PalboxPage) .. ":" .. tostring(mutate.PalboxSlot))
        return
    end

    if args[2] == "character" or args[2] == "characterid" then
        sParam.CharacterID = FName(args[3])
    elseif args[2] == "gender" then
        sParam.Gender = tonumber(args[3])
    elseif args[2] == "level" then
        sParam.Level = tonumber(args[3])

    elseif args[2] == "rank" then
        sParam.Rank = tonumber(args[3])
    elseif args[2] == "rankhp" then
        sParam.Rank_HP = tonumber(args[3])
    elseif args[2] == "rankattack" then
        sParam.Rank_Attack = tonumber(args[3])
    elseif args[2] == "rankdefense" then
        sParam.Rank_Defence = tonumber(args[3])
    elseif args[2] == "rankcraftspeed" then
        sParam.Rank_CraftSpeed = tonumber(args[3])

    elseif args[2] == "talenthp" or args[2] == "ivhp" then
        sParam.Talent_HP = tonumber(args[3])
    elseif args[2] == "talentattack" or args[2] == "ivattack" then
        sParam.Talent_Shot = tonumber(args[3])
        sParam.Talent_Melee = tonumber(args[3])
    elseif args[2] == "talentdefense" or args[2] == "ivdefense" then
        sParam.Talent_Defense = tonumber(args[3])

    elseif args[2] == "israre" or args[2] == "rare" then
        sParam.IsRarePal = (args[3] == "true")

    -- shortcut versions

    elseif args[2] == "ranks" then
        -- rank:hp:attack:defense:craftspeed
        -- 5:10:10:10:10
        local ranks = {}
        for match in args[3]:gmatch("([^:]+)") do
            table.insert(ranks, tonumber(match))
        end
        sParam.Rank = tonumber(ranks[1])
        sParam.Rank_HP = tonumber(ranks[2])
        sParam.Rank_Attack = tonumber(ranks[3])
        sParam.Rank_Defence = tonumber(ranks[4])
        sParam.Rank_CraftSpeed = tonumber(ranks[5])
    
    elseif args[2] == "talents" or args[2] == "ivs" then
        -- hp:melee:defense:shot
        -- 100:100:100
        local talents = {}
        for match in args[3]:gmatch("([^:]+)") do
            table.insert(talents, tonumber(match))
        end
        sParam.Talent_HP = tonumber(talents[1])
        sParam.Talent_Shot = tonumber(talents[2])
        sParam.Talent_Melee = tonumber(talents[2])
        sParam.Talent_Defense = tonumber(talents[3])

    -- moves

    elseif args[2] == "pass" then
        if args[3] == "clear" or args[3] == "empty" then
            sParam.PassiveSkillList:Empty()
        else
            local new_passive = args[3]
            -- load passives into table
            local existing_passives = {}
            sParam.PassiveSkillList:ForEach(function(index, existing_passive)
                table.insert(existing_passives, existing_passive:get():ToString())
            end)
            -- toggle it
            if table.contains(existing_passives, new_passive) then
                table.remove(existing_passives, table.index_of(existing_passives, new_passive))
            else
                table.insert(existing_passives, new_passive)
            end
            -- clear and re-add
            sParam.PassiveSkillList:Empty()
            for i = 1, #existing_passives+1 do
                sParam.PassiveSkillList[i] = FName("")
            end
            for i, v in ipairs(existing_passives) do
                sParam.PassiveSkillList[i] = FName(v)
                --print("Added " .. tostring(v) .. " to PassiveSkillList")
            end
        end  

    elseif args[2] == "skill" or args[2] == "skills" then
        -- array build gets really complex if we allow people to set Equipped Waza
        sParam.EquipWaza:Empty()
        if args[3] == "clear" or args[3] == "empty" then
            sParam.MasteredWaza:Empty()
        else
            local new_skill = args[3]
            -- load skills into table
            local existing_skills = {}
            sParam.MasteredWaza:ForEach(function(index, existing_skill)
                table.insert(existing_skills, tostring(existing_skill:get()))
            end)
            -- toggle it
            if table.contains(existing_skills, new_skill) then
                table.remove(existing_skills, table.index_of(existing_skills, new_skill))
            else
                table.insert(existing_skills, new_skill)
            end
            -- calculate endcap
            -- #175 => Reserve_81 is our valid backstopper (still not sure why we need to do this to prevent skill eating)
            if table.contains(existing_skills, "175") then
                table.remove(existing_skills, table.index_of(existing_skills, "175"))
            end
            table.insert(existing_skills, "175")
            -- clear and re-add
            sParam.MasteredWaza:Empty()
            for i = 1, #existing_skills do
                sParam.MasteredWaza[i] = 0
            end
            for i, v in ipairs(existing_skills) do
                sParam.MasteredWaza[i] = tonumber(v)
                --print("Added " .. tostring(v) .. " to MasteredWaza")
            end
        end

    elseif args[2] == "allskills" or args[2] == "skills all" then
        mutate.add_all_skills(sParam)

    end
end

mutate.valid_skills = {
    1,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,50,51,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,106,110,112,113,118,122,127,128,129,130,132,133,135,137,141,142,145
}

function mutate.add_all_skills(sParam)
    sParam.EquipWaza:Empty()
    sParam.MasteredWaza:Empty()

    --print("Adding skill " .. tostring(new_skill))
    local existing_skills = {}
    for _, new_skill in ipairs(mutate.valid_skills) do
        table.insert(existing_skills, tostring(new_skill))
    end
    -- calculate endcap
    -- #175 => Reserve_81 is our valid backstopper (still not sure why we need to do this to prevent skill eating)
    if table.contains(existing_skills, "175") then
        table.remove(existing_skills, table.index_of(existing_skills, "175"))
    end
    table.insert(existing_skills, "175")
    for i = 1, #existing_skills do
        sParam.MasteredWaza[i] = 0
    end
    for i, v in ipairs(existing_skills) do
        sParam.MasteredWaza[i] = tonumber(v)
        --modutil.log("Added " .. tostring(v) .. " to MasteredWaza")
    end
end

return mutate



----------------------------
-- List of Available Traits
----------------------------

-- NameProperty: CharacterID
-- NameProperty: UniqueNPCID
-- EnumProperty: Gender
-- ClassProperty: CharacterClass
-- IntProperty: Level
-- IntProperty: Rank
-- IntProperty: Rank_HP
-- IntProperty: Rank_Attack
-- IntProperty: Rank_Defence
-- IntProperty: Rank_CraftSpeed
-- IntProperty: Exp
-- StrProperty: NickName
-- BoolProperty: IsRarePal
-- ArrayProperty: EquipWaza
-- EnumProperty: EquipWaza
-- ArrayProperty: MasteredWaza
-- EnumProperty: MasteredWaza
-- StructProperty: HP
-- IntProperty: Talent_HP
-- IntProperty: Talent_Melee
-- IntProperty: Talent_Shot
-- IntProperty: Talent_Defense
-- FloatProperty: FullStomach
-- EnumProperty: PhysicalHealth
-- EnumProperty: WorkerSick
-- ArrayProperty: PassiveSkillList
-- NameProperty: PassiveSkillList
-- IntProperty: DyingTimer
-- StructProperty: MP
-- BoolProperty: IsPlayer
-- StructProperty: OwnedTime
-- StructProperty: OwnerPlayerUId
-- ArrayProperty: OldOwnerPlayerUIds
-- StructProperty: OldOwnerPlayerUIds
-- StructProperty: MaxHP
-- IntProperty: Support
-- IntProperty: CraftSpeed
-- ArrayProperty: CraftSpeeds
-- StructProperty: CraftSpeeds
-- StructProperty: ShieldHP
-- StructProperty: ShieldMaxHP
-- StructProperty: MaxMP
-- StructProperty: MaxSP
-- EnumProperty: HungerType
-- FloatProperty: SanityValue
-- EnumProperty: BaseCampWorkerEventType
-- FloatProperty: BaseCampWorkerEventProgressTime
-- StructProperty: ItemContainerId
-- StructProperty: EquipItemContainerId
-- StructProperty: SlotID
-- FloatProperty: MaxFullStomach
-- FloatProperty: FullStomachDecreaseRate_Tribe
-- IntProperty: UnusedStatusPoint
-- ArrayProperty: GotStatusPointList
-- StructProperty: GotStatusPointList
-- StructProperty: DecreaseFullStomachRates
-- StructProperty: AffectSanityRates
-- StructProperty: CraftSpeedRates
-- StructProperty: LastJumpedLocation
-- NameProperty: FoodWithStatusEffect
-- IntProperty: Tiemr_FoodWithStatusEffect
-- EnumProperty: CurrentWorkSuitability
-- BoolProperty: bAppliedDeathPenarty
-- FloatProperty: PalReviveTimer
-- IntProperty: VoiceID
-- StructProperty: Dynamic
