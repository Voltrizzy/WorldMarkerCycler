-- WorldMarkerCycler – Options Panel
-- Builds a configuration panel with 8 dropdown rows (one per cycle step).
-- Each dropdown lists the 8 world markers plus "None".
-- Selecting a marker in one row removes it from all other rows' menus,
-- preventing duplicate assignments.

local ADDON_NAME  = "WorldMarkerCycler"
local PANEL_TITLE = "WorldMarkerCycler"
local NUM_STEPS   = 8

-- Dropdown frame references kept so we can refresh menus on changes.
local dropdowns = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- Returns a set of markerIDs that are currently selected in OTHER rows.
local function GetUsedMarkers(excludeStep)
    local used = {}
    local seq  = WorldMarkerCyclerDB and WorldMarkerCyclerDB.sequence or {}
    for step = 1, NUM_STEPS do
        if step ~= excludeStep then
            local id = seq[step]
            if id and id > 0 then
                used[id] = true
            end
        end
    end
    return used
end

-- Refreshes every dropdown menu label to reflect the current saved sequence.
local function RefreshAllDropdowns()
    for step = 1, NUM_STEPS do
        local dd = dropdowns[step]
        if dd then
            local markerID = WorldMarkerCyclerDB and WorldMarkerCyclerDB.sequence[step] or 0
            local info     = WorldMarkerCycler_MarkerInfo[markerID]
            UIDropDownMenu_SetText(dd, info and info.name or "None")
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Dropdown initialisation function (called by the legacy UIDropDownMenu system)
-- ─────────────────────────────────────────────────────────────────────────────

local function Dropdown_Initialize(self, level)
    if not level then return end

    local step = self.wmcStep
    local used = GetUsedMarkers(step)

    -- "None" entry — always available.
    local noneEntry        = UIDropDownMenu_CreateInfo()
    noneEntry.text         = "None"
    noneEntry.value        = 0
    noneEntry.func         = function(btn)
        WorldMarkerCyclerDB.sequence[step] = 0
        UIDropDownMenu_SetText(self, "None")
        -- Re-open other dropdowns so the freed marker reappears.
        RefreshAllDropdowns()
    end
    local curID = WorldMarkerCyclerDB and WorldMarkerCyclerDB.sequence[step] or 0
    noneEntry.checked = (curID == 0)
    UIDropDownMenu_AddButton(noneEntry, level)

    -- One entry per world marker.
    for id = 1, NUM_STEPS do
        local minfo = WorldMarkerCycler_MarkerInfo[id]
        if not used[id] or curID == id then          -- show if not used elsewhere (or currently selected here)
            local entry         = UIDropDownMenu_CreateInfo()
            entry.text          = minfo.name
            entry.value         = id
            entry.icon          = minfo.texture
            entry.iconXOffset   = -4
            entry.iconYOffset   = 0
            entry.iconWidth     = 16
            entry.iconHeight    = 16
            local capturedID    = id   -- closure capture
            entry.func          = function(btn)
                WorldMarkerCyclerDB.sequence[step] = capturedID
                UIDropDownMenu_SetText(self, minfo.name)
                RefreshAllDropdowns()
            end
            entry.checked = (curID == id)
            UIDropDownMenu_AddButton(entry, level)
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Panel construction
-- ─────────────────────────────────────────────────────────────────────────────

local function BuildPanel(parent)
    -- Title
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(PANEL_TITLE)

    local subtitle = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText("Configure the order in which world markers are placed. Assign each step a marker or leave it as None to skip that step.")
    subtitle:SetWidth(parent:GetWidth() - 32)
    subtitle:SetJustifyH("LEFT")

    local LABEL_WIDTH  = 60
    local DD_WIDTH     = 180
    local ROW_HEIGHT   = 36
    local START_Y      = -80

    for step = 1, NUM_STEPS do
        local rowY = START_Y - ((step - 1) * ROW_HEIGHT)

        -- "Step N:" label
        local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", 24, rowY)
        label:SetWidth(LABEL_WIDTH)
        label:SetJustifyH("LEFT")
        label:SetText("Step " .. step .. ":")

        -- Dropdown
        local dd = CreateFrame("Frame", ADDON_NAME .. "_DD_" .. step, parent, "UIDropDownMenuTemplate")
        dd:SetPoint("LEFT", label, "RIGHT", 8, -2)
        dd.wmcStep = step
        UIDropDownMenu_SetWidth(dd, DD_WIDTH)
        UIDropDownMenu_Initialize(dd, Dropdown_Initialize)

        dropdowns[step] = dd
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Panel registration – supports both the modern Settings API (10.x+) and the
-- legacy InterfaceOptions API as a fallback.
-- ─────────────────────────────────────────────────────────────────────────────

local optionsPanel

local function CreateOptionsPanel()
    if optionsPanel then return end

    local panel = CreateFrame("Frame")
    panel.name  = PANEL_TITLE

    -- The panel needs a size for building child elements; use a sensible default.
    panel:SetSize(600, 500)

    BuildPanel(panel)
    optionsPanel = panel

    -- Populate dropdowns once the DB is ready.
    if WorldMarkerCyclerDB then
        RefreshAllDropdowns()
    end

    -- Modern Settings API (The War Within / Dragonflight 10.x+)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, PANEL_TITLE)
        -- In some WoW versions RegisterCanvasLayoutCategory returns the raw frame
        -- instead of a CategoryMixin; guard against that before calling RegisterAddOnCategory.
        if category and type(category.GetLayout) == "function" then
            Settings.RegisterAddOnCategory(category)
            panel.settingsCategory = category
        end
    elseif InterfaceOptions_AddCategory then
        -- Legacy fallback
        InterfaceOptions_AddCategory(panel)
    end
end

-- Lazily build the panel the first time the user opens it (DB will be ready by then).
function WorldMarkerCycler_OpenOptions()
    CreateOptionsPanel()
    RefreshAllDropdowns()

    if optionsPanel and optionsPanel.settingsCategory then
        -- Modern API: 12.0+ requires a numeric ID, not the category object.
        Settings.OpenToCategory(optionsPanel.settingsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        -- Legacy API
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
    else
        -- Absolute fallback: just show the raw frame near the centre of the screen.
        if not optionsPanel:IsShown() then
            optionsPanel:SetPoint("CENTER")
            optionsPanel:Show()
        else
            optionsPanel:Hide()
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Binding Support (Secure Buttons)
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Create the Secure Button for "Next Marker"
local btnNext = CreateFrame("Button", "WorldMarkerCycler_Next", UIParent, "SecureActionButtonTemplate")
btnNext:SetAttribute("type", "macro")
btnNext:RegisterForClicks("AnyDown", "AnyUp")

-- This secure snippet runs before the click is processed. It calculates the next
-- marker in the sequence and updates the 'macrotext' attribute dynamically.
local secureSnippet = [[
    -- Load the sequence string (e.g., "1,2,6,8") and current index
    local seqStr = self:GetAttribute("sequence") or ""
    local idx = tonumber(self:GetAttribute("currentIndex")) or 1

    -- Parse the comma-separated sequence into a table
    local markers = {}
    local count = 0
    for id in string.gmatch(seqStr, "([^,]+)") do
        table.insert(markers, tonumber(id))
        count = count + 1
    end

    if count == 0 then return end

    -- Cycle logic: Find the next valid marker starting from current index
    -- We loop through the list to find a non-zero marker
    local markerID = 0
    local nextIdx = idx

    for k = 1, count do
        local slot = ((idx - 1 + (k - 1)) % count) + 1
        local mid = markers[slot]
        if mid and mid > 0 then
            markerID = mid
            nextIdx = (slot % count) + 1 -- Prepare index for the *next* click
            break
        end
    end

    -- Set the macro text for THIS click
    if markerID > 0 then
        self:SetAttribute("macrotext", "/wm [@cursor] " .. markerID)
        self:SetAttribute("currentIndex", nextIdx)
        
        -- Sync the index back to the insecure Lua environment (non-critical)
        self:CallMethod("UpdateDBIndex", nextIdx)
    end
]]

-- Attach the snippet to the button's OnClick handler
SecureHandlerWrapScript(btnNext, "OnClick", btnNext, secureSnippet)

-- Method called by the secure environment to save the index state
function btnNext:UpdateDBIndex(newIdx)
    if WorldMarkerCyclerDB then
        WorldMarkerCyclerDB.currentIndex = newIdx
    end
end

-- 2. Create the Secure Button for "Clear All"
local btnClear = CreateFrame("Button", "WorldMarkerCycler_Clear", UIParent, "SecureActionButtonTemplate")
btnClear:SetAttribute("type", "macro")
btnClear:SetAttribute("macrotext", "/cwm all") -- Secure command to clear world markers
btnClear:RegisterForClicks("AnyDown", "AnyUp")

-- ─────────────────────────────────────────────────────────────────────────────
-- Synchronization (Lua -> Secure)
-- ─────────────────────────────────────────────────────────────────────────────

-- Pushes the current DB settings into the secure button's attributes.
-- This must be called whenever the sequence or index changes in Lua.
function WorldMarkerCycler_UpdateSecureButtons()
    if not WorldMarkerCyclerDB or InCombatLockdown() then return end

    -- Convert sequence table {1, 2, 0, 4...} to string "1,2,0,4"
    local seq = WorldMarkerCyclerDB.sequence or {}
    local seqStr = table.concat(seq, ",")
    
    btnNext:SetAttribute("sequence", seqStr)
    btnNext:SetAttribute("currentIndex", WorldMarkerCyclerDB.currentIndex or 1)
end

-- Hook into the dropdown refresh to ensure changes apply immediately
local orig_Refresh = RefreshAllDropdowns
RefreshAllDropdowns = function()
    if orig_Refresh then orig_Refresh() end
    WorldMarkerCycler_UpdateSecureButtons()
end

-- Make sure the panel exists after the addon loads (so ESC > Options lists it).
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    CreateOptionsPanel()
    if WorldMarkerCyclerDB then
        RefreshAllDropdowns()
    end
    self:UnregisterEvent("PLAYER_LOGIN")
end)
