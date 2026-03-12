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

-- Forward declaration for the secure update function defined later
local WorldMarkerCycler_UpdateSecureButtons_Ref

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
            -- Update the button text (with icon) to match selection
            local displayText
            if info and info.texture then
                displayText = string.format("|T%s:16:16|t %s", info.texture, info.name)
            else
                displayText = (info and info.name) or "None"
            end
            dd:SetText(displayText)
            -- Regenerate the menu if open to update available options (filter used markers)
            dd:GenerateMenu()
        end
    end
    
    -- Sync with secure bindings
    if WorldMarkerCycler_UpdateSecureButtons_Ref then
        WorldMarkerCycler_UpdateSecureButtons_Ref()
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Dropdown Menu Generator (Modern API)
-- ─────────────────────────────────────────────────────────────────────────────

local function CreateMenuGenerator(step)
    return function(owner, rootDescription)
        local used  = GetUsedMarkers(step)
        local curID = WorldMarkerCyclerDB and WorldMarkerCyclerDB.sequence[step] or 0

        -- "None" entry
        rootDescription:CreateRadio(
            "None",
            function() return curID == 0 end,
            function()
                WorldMarkerCyclerDB.sequence[step] = 0
                RefreshAllDropdowns()
            end
        )

        -- Marker entries (1-8)
        for id = 1, NUM_STEPS do
            local minfo = WorldMarkerCycler_MarkerInfo[id]
            -- Show marker if it's not used elsewhere, or if it is the current selection for this step
            if not used[id] or curID == id then
                local radio = rootDescription:CreateRadio(
                    minfo.name,
                    function() return curID == id end,
                    function()
                        WorldMarkerCyclerDB.sequence[step] = id
                        RefreshAllDropdowns()
                    end
                )
                radio:AddInitializer(function(button)
                    local icon = button:AttachTexture()
                    icon:SetSize(16, 16)
                    icon:SetPoint("RIGHT")
                    icon:SetTexture(minfo.texture)
                end)
            end
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
        local dd = CreateFrame("DropdownButton", ADDON_NAME .. "_DD_" .. step, parent, "WowStyle1DropdownTemplate")
        dd:SetPoint("LEFT", label, "RIGHT", 8, -2)
        dd:SetWidth(DD_WIDTH)
        dd:SetupMenu(CreateMenuGenerator(step))

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

    -- Refresh dropdowns whenever the panel is shown to ensure data is current.
    panel:SetScript("OnShow", function()
        RefreshAllDropdowns()
    end)

    -- Modern Settings API (The War Within / Dragonflight 10.x+)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, PANEL_TITLE)
        Settings.RegisterAddOnCategory(category)
        panel.settingsCategory = category
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

-- This frame holds the state for our secure buttons. Attributes are read from
-- this 'header' frame during the secure execution path.
local stateFrame = CreateFrame("Frame", "WorldMarkerCycler_State", UIParent, "SecureHandlerAttributeTemplate")

-- Method called by the secure environment to save the index state.
-- It's attached to the stateFrame so the secure snippet can call it.
function stateFrame:UpdateDBIndex(newIdx)
    if WorldMarkerCyclerDB then
        WorldMarkerCyclerDB.currentIndex = newIdx
    end
end

-- 1. Create the Secure Button for "Next Marker"
local btnNext = CreateFrame("Button", "WorldMarkerCycler_Next", UIParent, "SecureActionButtonTemplate")
btnNext:SetAttribute("type", "macro")
btnNext:RegisterForClicks("AnyDown", "AnyUp")

-- This secure snippet runs before the click is processed. It calculates the next
-- marker in the sequence and updates the 'macrotext' attribute dynamically.
-- 'self' inside the snippet refers to the header (stateFrame).
-- 'button' refers to the button being clicked (btnNext).
local secureSnippet = [[
    -- Load the sequence string (e.g., "1,2,6,8") and current index from the header
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

    -- Set the macro text on the button for THIS click
    if markerID > 0 then
        button:SetAttribute("macrotext", "/wm [@cursor] " .. markerID)
        -- Update the index on the header for the NEXT click
        self:SetAttribute("currentIndex", nextIdx)
        
        -- Sync the index back to the insecure Lua environment (non-critical)
        self:CallMethod("UpdateDBIndex", nextIdx)
    end
]]

-- Attach the snippet to the button's OnClick handler.
-- The header (stateFrame) is passed as the 'self' argument to the snippet.
SecureHandlerWrapScript(btnNext, "OnClick", stateFrame, secureSnippet)

-- 2. Create the Secure Button for "Clear All"
local btnClear = CreateFrame("Button", "WorldMarkerCycler_Clear", UIParent, "SecureActionButtonTemplate")
btnClear:SetAttribute("type", "macro")
btnClear:SetAttribute("macrotext", "/cwm all") -- Secure command to clear world markers
btnClear:RegisterForClicks("AnyDown", "AnyUp")

-- Reset the cycle index back to step 1 when clearing markers
SecureHandlerWrapScript(btnClear, "OnClick", stateFrame, [[
    self:SetAttribute("currentIndex", 1)
    self:CallMethod("UpdateDBIndex", 1)
]])

-- ─────────────────────────────────────────────────────────────────────────────
-- Synchronization (Lua -> Secure)
-- ─────────────────────────────────────────────────────────────────────────────

-- Pushes the current DB settings into the secure state frame's attributes.
-- This must be called whenever the sequence or index changes in Lua.
function WorldMarkerCycler_UpdateSecureButtons()
    if not WorldMarkerCyclerDB or InCombatLockdown() then return end

    -- Convert sequence table {1, 2, 0, 4...} to string "1,2,0,4"
    local seq = WorldMarkerCyclerDB.sequence or {}
    local seqStr = table.concat(seq, ",")
    
    -- Set attributes on the state frame, not the button
    stateFrame:SetAttribute("sequence", seqStr)
    stateFrame:SetAttribute("currentIndex", WorldMarkerCyclerDB.currentIndex or 1)
end

-- Connect the forward declaration to the actual function (must be after the function is defined above)
WorldMarkerCycler_UpdateSecureButtons_Ref = WorldMarkerCycler_UpdateSecureButtons

-- Make sure the panel exists after the addon loads (so ESC > Options lists it).
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == ADDON_NAME then
        CreateOptionsPanel()
        -- The panel is now registered. Its OnShow script will handle populating the data.
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
