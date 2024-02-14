local UEHelpers = require("UEHelpers")

local config = require("config")
local modutil = require("utils/modutil")
local hostcontext = require("utils/hostcontext")
local prompt = require("utils/prompt")
local trigger_crouch = require("utils/trigger_crouch")

local mutate = require("commands/mutate")
local give = require("commands/give")
local tp = require("commands/tp")
local pick = require("commands/pick")
local settime = require("commands/settime")

--[[

        Instance types

            Human (w/ or w/o Admin) [Co-Op Client / Dedicated Client]
                VulnCmd => Local => OnReceivedChat
                VulnCmd => Local => CustomInput
            
            Human w/ Host [Singleplayer / Co-Op Host]
                HostCmd => Local => OnReceivedChat
                VulnCmd => Local => OnReceivedChat
                VulnCmd => Local => CustomInput

            Human w/ Host w/ Multiplayer [Co-Op Host]
                HostCmd => Remote => EnterChat_Receive

            Server w/ Host [Dedicated Host]
                HostCmd => Remote => EnterChat_Receive
                VulnCmd => Remote => EnterChat_Receive

        Default => Enable OnReceivedChat (local, enforce sender)
        IsHost => Enable EnterChat_Receive (remote)

]]

modutil.hello()
modutil.lognotice()

HasHostContext = nil
HookData = {}

DidHooks = false

function process_command(PlayerState, args)
    modutil.log("Raw Command: " .. table.concat(args, " "))
    if args[1] == "mutate" then
        mutate.route_cmd(PlayerState, args)
    elseif args[1] == "give" then
        give.route_cmd(PlayerState, args)
    elseif args[1] == "tp" then
        tp.route_cmd(PlayerState:GetPlayerController(), args)
    elseif args[1] == "pick" then
        pick.route_cmd(args)
    elseif args[1] == "time" then
        settime.route_cmd(args)
    else
        modutil.log("Unknown Command: " .. args[1])
    end
end

function ProcessCommandRoute_Local(PlayerState, user_input)
    if modutil.qualified_local_command(PlayerState) then
        if modutil.possible_command(user_input) then
            args = modutil.parse_command(user_input:sub(2))
            if (modutil.requires_host_command_context(args[1]) and HasHostContext) or not modutil.requires_host_command_context(args[1]) then
                process_command(PlayerState, args)
            else
                modutil.log("Warning, command requires host context.")
            end
        end
    end
end

function HookCommandRoute_Local(context, message)
    local received = message:get()
    local user_input = received.Message:ToString()
    --local Sender = received.Sender:ToString()
    local SenderPlayerUId = modutil.GuidToString(received.SenderPlayerUId)
    --local ReceiverPlayerUId = received.ReceiverPlayerUId -- 0:0:0:0

    -- verify that I only process my own commands
    local MyController = UEHelpers.GetPlayerController()
    local MyUId = modutil.GuidToString(MyController:GetPlayerUId())
    if SenderPlayerUId ~= MyUId then
        return
    end
    local PlayerState = MyController.PlayerState

    ProcessCommandRoute_Local(PlayerState, user_input)
end
function HookCommandRoute_Remote(context, chatmessage)
    local user_input = chatmessage:get().Message:ToString()
    local PlayerState = context:get()

    if modutil.possible_command(user_input) then
        args = modutil.parse_command(user_input:sub(2))
        if modutil.requires_host_command_context(args[1]) then
            if modutil.qualified_remote_command(PlayerState, args[1]) then
                    process_command(PlayerState, args)
            else
                modutil.log("Player '" .. tostring(PlayerState.PlayerNamePrivate:ToString()) .. "' is not qualified to command: " .. args[1])
                --modutil.message_player(PlayerState, "You must be an admin to access this command")
            end
        end
    end
end

-- Stealth Prompt Hooking
function HookStealthPrompts()
    if not config.force_dedicated_mode then
        if config.enable_trigger_crouch then
            trigger_crouch.register(callback_crouch_triggered)
        end
        if config.enable_trigger_keybind then
            if HookData["StealthPrompt_Keybind"] ~= nil then
                UnregisterHook(config.keybind_prompt, HookData["StealthPrompt_Keybind"][1], HookData["StealthPrompt_Keybind"][2])
            end
            preid, postid = RegisterKeyBind(config.keybind_prompt, function()
                modutil.log("keybind_trigger")
                prompt.open(callback_popup_exited)
            end)
            HookData["StealthPrompt_Keybind"] = {preid, postid}
            modutil.log("Registered Trigger: Keybind => " .. tostring(config.keybind_prompt))
        end
    end
end

-- Stealth Prompt Callbacks
function callback_crouch_triggered()
    modutil.log("callback_crouch_triggered")
    prompt.open(callback_popup_exited)
end
function callback_popup_exited(user_input)
    modutil.log("callback_popup_exited")
    ProcessCommandRoute_Local(UEHelpers.GetPlayerController().PlayerState, user_input)
end

-- Register Remote Command Routes
function RegisterCommandRoute_Remote()
    modutil.log("Detected Available Host Context => Host Mode")
    if HookData["RemoteCommandRoute"] ~= nil then
        UnregisterHook("/Script/Pal.PalPlayerState:EnterChat_Receive", HookData["RemoteCommandRoute"][1], HookData["RemoteCommandRoute"][2])
    end
    preid, postid = RegisterHook("/Script/Pal.PalPlayerState:EnterChat_Receive", HookCommandRoute_Remote)
    HookData["RemoteCommandRoute"] = {preid, postid}
    modutil.log("Successfully Enabled Remote Command Routes")
end

-- Register Local Command Routes
function RegisterCommandRoute_Local()
    if not config.force_dedicated_mode then
        if HookData["LocalCommandRoute"] ~= nil then
            UnregisterHook("/Script/Pal.PalUIChat:OnReceivedChat", HookData["LocalCommandRoute"][1], HookData["LocalCommandRoute"][2])
        end
        preid, postid = RegisterHook("/Script/Pal.PalUIChat:OnReceivedChat", HookCommandRoute_Local)
        HookData["LocalCommandRoute"] = {preid, postid}
        modutil.log("Successfully Enabled Local Command Routes")
    end
end

-- Standard Command Route Hooking
function CheckRegisterCommandRoutes()
    if not DidHooks then
        DidHooks = true

        modutil.log("Determining Appropriate Command Routes...")
        if HasHostContext then
            local success, result = pcall(RegisterCommandRoute_Remote)
            if not success then
                modutil.log("Failed to hook remote routes. Unable to process remote commands.")
            end
        else
            modutil.log("Failed To Detect Available Host Context => Client Mode")
            modutil.log("Did Not Enable Remote Command Routes")
        end

        -- Update to have this not called on Dedicated Servers (moar perfor)
        local success, result = pcall(RegisterCommandRoute_Local)
        if not success then
            modutil.log("Failed to hook local routes. Local chat commands disabled.")
        end

        -- Update to have this not called on Dedicated Servers
        local success, result = pcall(HookStealthPrompts)
        if not success then
            modutil.log("Failed to hook stealth prompts. Local keybind and crouch disabled.")
        end
    end
end
function callback_success_hostcontext()
    HasHostContext = true
    CheckRegisterCommandRoutes()
end
function callback_failure_hostcontext()
    HasHostContext = false
    CheckRegisterCommandRoutes()
end
function determine_hostcontext()
    hostcontext.determine(callback_success_hostcontext, callback_failure_hostcontext)
end

function join_load_delay()
    modutil.log("join_load_delay")
    ExecuteWithDelay(4000, determine_hostcontext)
end


-- Let them Race!
RegisterHook("/Script/Engine.PlayerController:ServerAcknowledgePossession", join_load_delay)
RegisterHook("/Script/Engine.PlayerController:ClientRestart", join_load_delay)

RegisterHook("/Script/Pal.PalPlayerController:OnDestroyPawn", function()
    DidHooks = false
    modutil.log("Leaving Game World.")
end)

