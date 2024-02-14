local UEHelpers = require("UEHelpers")

modutil = {}

local config = require("../config")

function modutil.hello()
    msg = config.name .. " v" .. config.version .. " Started Successfully!"
    print("[" .. config.name .. "] " .. tostring(msg) .. "\n")
end

function modutil.log(msg)
    if config.print_logs then
        print("[" .. config.name .. "] " .. tostring(msg) .. "\n")
    end
end

function modutil.lognotice()
    msg = "Logging Enabled (this can be configured in config.lua)"
    modutil.log(msg)
end



function modutil.possible_command(msg)
    return msg:sub(1, 1) == config.command_header
end

function modutil.qualified_local_command(ContextPlayerState)
    -- todo: check if the player is "me"
    return true
end

-- function modutil.qualified_command_context(command, host_context)
--     -- see if we have a table entry for this command
--     if config.command_requires_host_context[command] then
--         -- if the command requires host context and the player does not have host context, return false
--         if not host_context then
--             return false
--         end
--     end
--     return true
-- end

function modutil.requires_host_command_context(command)
    -- see if we have a table entry for this command
    if config.command_requires_host_context[command] then
        return config.command_requires_host_context[command]
    end
    return false
end

function modutil.qualified_remote_command(PlayerState, command)
    -- see if we have a table entry for this command
    if config.remote_command_admin_required[command] then
        -- if the command requires admin and the player is not an admin, return false
        if config.remote_command_admin_required[command] and not PlayerState:GetPlayerController().bAdmin then
            return false
        end
    end
    return true
end

function modutil.parse_command(command)
    local args = {}
    for word in command:gmatch("%S+") do
        table.insert(args, word)
    end
    args[1] = string.lower(args[1])
    return args
end

function modutil.GuidToString(guid)
    return tostring(guid.A) .. ":" .. tostring(guid.B) .. ":" .. tostring(guid.C) .. ":" .. tostring(guid.D)
end

return modutil