BINDING_HEADER_WORLDMARKERCYCLER = "World Marker Cycler"
BINDING_NAME_WORLDMARKERCYCLER_CYCLE = "WMC - Cycle"
BINDING_NAME_WORLDMARKERCYCLER_CLEAR = "WMC - Clear"

local ADDON_NAME = "WorldMarkerCycler"

-- Shared marker info table used by Core and Options
WorldMarkerCycler_MarkerInfo = {
    [0] = { name = "None",     texture = nil },
    [1] = { name = "Star",     texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1" },
    [2] = { name = "Circle",   texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2" },
    [3] = { name = "Diamond",  texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3" },
    [4] = { name = "Triangle", texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4" },
    [5] = { name = "Moon",     texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5" },
    [6] = { name = "Square",   texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6" },
    [7] = { name = "Cross",    texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7" },
    [8] = { name = "Skull",    texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8" },
}

local DEFAULTS = {
    sequence     = { 1, 2, 3, 4, 5, 6, 7, 8 },
    currentIndex = 1,
}

local function InitDB()
    if not WorldMarkerCyclerDB then
        WorldMarkerCyclerDB = CopyTable(DEFAULTS)
        return
    end
    if not WorldMarkerCyclerDB.sequence then
        WorldMarkerCyclerDB.sequence = CopyTable(DEFAULTS.sequence)
    end
    if not WorldMarkerCyclerDB.currentIndex then
        WorldMarkerCyclerDB.currentIndex = 1
    end
end

-- Slash command to open the options panel.
SLASH_WORLDMARKERCYCLER1 = "/wmc"
SlashCmdList["WORLDMARKERCYCLER"] = function()
    WorldMarkerCycler_OpenOptions()
end

-- Initialise the saved-variable database when the addon finishes loading.
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == ADDON_NAME then
        InitDB()
        -- Sync the DB data to the secure buttons
        if WorldMarkerCycler_UpdateSecureButtons then
            WorldMarkerCycler_UpdateSecureButtons()
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
