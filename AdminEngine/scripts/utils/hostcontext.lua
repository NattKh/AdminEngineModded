hostcontext = {}

hostcontext.delay = 250
hostcontext.hour_offset = 1

hostcontext.PalTimeManager = nil
function hostcontext.determine(callback_success, callback_failure)
    hostcontext.PalTimeManager = FindFirstOf("PalTimeManager")
    if hostcontext.PalTimeManager == nil then
        print("Failed to find PalTimeManager")
        callback_failure()
        return
    end
    hostcontext.verify_time_control(callback_success, callback_failure)
end

function hostcontext.get_time_hour()
    return hostcontext.PalTimeManager:GetCurrentPalWorldTime_Hour()
end

function hostcontext.set_time_hour(hour)
    hostcontext.PalTimeManager:SetGameTime_FixDay(hour)
end

function hostcontext.verify_time_control(callback_success, callback_failure)
    local current_hour = hostcontext.get_time_hour()
    hostcontext.set_time_hour(current_hour + hostcontext.hour_offset)
    ExecuteWithDelay(hostcontext.delay, function()
        local litmus_hour = hostcontext.get_time_hour()
        hostcontext.set_time_hour(current_hour)

        if litmus_hour == current_hour then
            callback_failure()
        else
            callback_success()
        end
    end)
end

return hostcontext