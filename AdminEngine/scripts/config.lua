config = {}

-- The name/version of the mod
config.name = "AdminEngine"
config.version = "2.0.3"

-- Enable/Disable printing generic messages to the UE4SS console
config.print_logs = true

-- Trigger the stealth command prompt by rapidly crouching
config.enable_trigger_crouch = true
config.crouch_trigger_requirement = 5

-- Trigger the stealth command prompt by pressing a keybind
config.enable_trigger_keybind = true
config.keybind_prompt = Key.F5

-- Enable/Disable forcing dedicated server mode
config.force_dedicated_mode = false

-- Add you own custom !tp locations (client-side)
-- Use just !tp in-game to see your current location in the console logs
config.custom_locations = {
    ['home'] = '-289617.57835521,39548.323308997,13935.111736738',
    ['sanct1'] = '-457802.20012442,197136.42267675,15444.275994158',
    ['sanct2'] = '-174743.09060884,-153863.08303514,15451.732724161',
    ['sanct3'] = '168641.79577948,464296.09606568,15448.875068955',
    ['f1'] = '-155769.88554761,111974.89402871,-552.3655554403'
}

-- Specify any commands that require that a remote user be an admin to execute (multiplayer only)
config.remote_command_admin_required = {
    ["mutate"] = true,
    ["give"] = true, -- a local non-host-context vulnerablility exists
    ["pick"] = true, -- a local non-host-context vulnerablility exists
    ["tp"] = true, -- a local non-host-context vulnerablility exists
    ["time"] = true,
}

-- This table is for logging and reducing detection
-- Changing this will not magically grant a command the ability to execute
-- Changing this will fuck your context'd calls like your pick interlace
config.command_requires_host_context = {
    ["mutate"] = true,
    ["give"] = false,
    ["pick"] = false,
    ["tp"] = false,
    ["time"] = true,
}

-- Prefix required to trigger a command
config.command_header = "!"

-- The altitude we airdrop from when using map coords
config.tp_airdrop_altitude = 100000.00000000

-- The number of items to interlace when using the "relic" command
config.interlace_count = 30

-- Increase this number if you crash while astral projecting
config.interlace_interval = 1000 -- (ms)

-- The step size for map coords => locs
config.tp_step = 462.962962963

--------------------------------------------------------------------------------
-- Settings

-- Available colors: white, red, yellow, blue, 
-- ingamePalName, orange, lightBlue,
-- Default color: lightBlue
config.color = "lightBlue"

-- Font size
-- Default font size: 12
config.fontSize = 12

-- Font type
-- Available font types: Regular, Bold
-- Default font type: Regular
config.fontType = "Regular"


-------------------------------------------------------------------------------

return config