local UEHelpers = require("UEHelpers")

prompt = {}

function prompt.open(callback_user_input)
    prompt.spawnPopup(callback_user_input)
end

--global vars
widgetref_short = "WBP_Title_WorldSelect_OverlayWindow_InputCode_C"
widgetref_full = "/Game/Pal/Blueprint/UI/UserInterface/Title/WBP_Title_WorldSelect_OverlayWindow_InputCode.WBP_Title_WorldSelect_OverlayWindow_InputCode_C"
hookref_button_submit = "/Game/Pal/Blueprint/UI/UserInterface/Title/WBP_Title_WorldSelect_OverlayWindow_InputCode.WBP_Title_WorldSelect_OverlayWindow_InputCode_C:BndEvt__WBP_Title_WorldSelect_OverlayWindow_InputCode_WBP_Title_SettingsButton_K2Node_ComponentBoundEvent_0_OnClicked__DelegateSignature"
hookref_button_close = "/Game/Pal/Blueprint/UI/UserInterface/Title/WBP_Title_WorldSelect_OverlayWindow_InputCode.WBP_Title_WorldSelect_OverlayWindow_InputCode_C:BndEvt__WBP_Buildup_Player_WBP_Menu_btn_Close_K2Node_ComponentBoundEvent_2_OnButtonClicked__DelegateSignature"

-- state management
popup_open = false

cmdPopup = nil
hookIdpre_1 = nil
hookIdpost_1 = nil
hookIdpre_2 = nil
hookIdpost_2 = nil

function prompt.trim(input)
    return input:gsub("^%s*(.-)%s*$", "%1")
end

function prompt.filter_ascii(input)
    local filtered = ""
    for i = 1, #input do
        local c = input:sub(i,i)
        local b = string.byte(c)
        if b >= 32 and b <= 126 then
            filtered = filtered .. c
        end
    end
    return filtered
end

function prompt.spawnPopup(callback_user_input)
    if popup_open then
        destroyPopup() --press again to close.
        return
    end

    popup_open = true
    modutil.log("Spawning Prompt...")

    cmdPopup = StaticConstructObject(StaticFindObject(widgetref_full), FindFirstOf("GameInstance"))
    cmdPopup:AddToViewport(99)

    cmdPopup.BP_PalTextBlock_C_166:SetText(FText("Please enter a command"))
    cmdPopup.EditableTextBox_Code:SetText(FText(""))
    cmdPopup.Text_Title:SetText(FText(""))
    cmdPopup.Text_Caution:SetText(FText(""))
    cmdPopup.WBP_Title_SettingsButton.Text_Main:SetText(FText("Execute"))
    
    UEHelpers:GetPlayerController().bShowMouseCursor = true
    cmdPopup:SetUserFocus(UEHelpers:GetPlayerController())
    
    modutil.log("Prompt Spawned")

    hookIdpre_1, hookIdpost_1 = RegisterHook(hookref_button_close, function()
        prompt.destroyPopup()
    end)

    hookIdpre_2, hookIdpost_2 = RegisterHook(hookref_button_submit, function()
        local input = cmdPopup.EditableTextBox_Code:GetText():ToString()
        modutil.log("Raw Input: " .. tostring(input))
        input = prompt.trim(prompt.filter_ascii(input))
        modutil.log("Clean Input: " .. tostring(input))

        prompt.destroyPopup()

        callback_user_input(input)
    end)

    modutil.log("Prompt Hooks Successful")
end

function prompt.destroyPopup()
    modutil.log("Destroying Prompt...")

    do
        local popups = FindAllOf(widgetref_short)
        for _, popup in ipairs(popups) do
            popup:RemoveFromViewport()
        end
        cmdPopup = nil
    end

    modutil.log("Prompt Destroyed")
    
    local PalPlayerController = UEHelpers:GetPlayerController()
    PalPlayerController:ClientForceGarbageCollection()
    PalPlayerController.bShowMouseCursor = false

    modutil.log("Character Control Adjusted")
    
    UnregisterHook(hookref_button_close, hookIdpre_1, hookIdpost_1)
    UnregisterHook(hookref_button_submit, hookIdpre_2, hookIdpost_2)
    prompt.nilVars()

    modutil.log("Prompt Hooks Removed")
    popup_open = false
end

function prompt.nilVars()
    modutil.log("Clearing globals")
    cmdPopup = nil
    hookIdpre_1 = nil
    hookIdpost_1 = nil
    hookIdpre_2 = nil
    hookIdpost_2 = nil
end

return prompt
