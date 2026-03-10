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

-- Called by the keybinding to advance the cycle and place the next marker.
function WorldMarkerCycler_PlaceNextMarker()
    local db = WorldMarkerCyclerDB
    if not db then return end

    local seq   = db.sequence
    local total = #seq

    -- Walk from currentIndex, wrapping around, until a non-zero slot is found.
    for i = 1, total do
        local slotIndex = ((db.currentIndex - 1 + (i - 1)) % total) + 1
        local markerID  = seq[slotIndex]

        if markerID and markerID > 0 then
            -- Advance the index past this slot for the next call.
            db.currentIndex = (slotIndex % total) + 1
            RunMacroText("/wm [@cursor] " .. markerID)
            return
        end
    end

    print("|cffff9900WorldMarkerCycler:|r No markers are configured. Use /wmc to set up your sequence.")
end

-- Called by the keybinding to wipe all world markers and reset the cycle.
function WorldMarkerCycler_ClearAllMarkers()
    C_WorldMarker.ClearAllMarkers()
    if WorldMarkerCyclerDB then
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
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
