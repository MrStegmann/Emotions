local addonName, addon = ...
addon.Events = {}

local eventFrame = CreateFrame("Frame")

--- Initializes event listener for lifecycle events
-- @param onLoaded function Callback executed when ADDON_LOADED fires for Emotions
-- @param onLogin function Callback executed when PLAYER_LOGIN fires
function addon.Events.Init(onLoaded, onLogin)
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")

    eventFrame:SetScript("OnEvent", function(self, event, arg1)
        if event == "ADDON_LOADED" and arg1 == addonName then
            if addon.Storage then
                addon.Storage.Init()
            end
            if type(onLoaded) == "function" then
                onLoaded()
            end
        elseif event == "PLAYER_LOGIN" then
            if type(onLogin) == "function" then
                onLogin()
            end
        end
    end)
end
