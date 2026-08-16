local addonName, addon = ...

local currentPage = 1
local isEditMode = false
local menuFrame = nil
local addFrame = nil
local confirmDeleteFrame = nil
local launcherButton = nil
local editButton = nil
local addButton = nil
local itemSlots = {}
local pageText = nil
local searchQuery = ""

local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

--- Executes the Epsilon command for the given emote ID
-- @param emoteId string
local function ExecuteEmoteCommand(emoteId)
    if not emoteId or emoteId == "" then return end
    local command = ".mod stand " .. tostring(emoteId)
    
    -- Primary: SendChatMessage using valid chatType "SAY"
    SendChatMessage(command, "SAY")

    -- Fallback: Macro execution line if available
    if MacroFrame_ExecuteMacroLine then
        pcall(MacroFrame_ExecuteMacroLine, command)
    end
end

--- Refreshes the options inside the conceptual menu
local function RefreshMenu()
    if not menuFrame or not menuFrame:IsShown() then return end

    local allEmotes = addon.Storage.GetEmotes()
    local displayList = {}
    
    for i, v in ipairs(allEmotes) do
        table.insert(displayList, { globalIndex = i, label = v.label, id = v.id })
    end
    
    if searchQuery and searchQuery ~= "" then
        local filtered = {}
        for _, v in ipairs(displayList) do
            if string.find(string.lower(v.label), searchQuery, 1, true) or string.find(string.lower(v.id), searchQuery, 1, true) then
                table.insert(filtered, v)
            end
        end
        table.sort(filtered, function(a, b) return string.lower(a.label) < string.lower(b.label) end)
        displayList = filtered
    end

    local totalPages = addon.Menu.GetTotalPages(#displayList)
    if currentPage > totalPages then
        currentPage = totalPages
    end

    local slice, startIndex = addon.Menu.GetPageSlice(displayList, currentPage)

    -- Update 9 emote slot buttons
    for i = 1, addon.Menu.EMOTES_PER_PAGE do
        local btn = itemSlots[i]
        local emoteData = slice[i]

        if emoteData then
            btn:SetText(emoteData.label) -- Render custom label
            btn:SetNormalFontObject("GameFontHighlight")
            btn.emoteId = emoteData.id
            btn.globalIndex = emoteData.globalIndex
            btn:Show()

            if isEditMode then
                btn:SetWidth(178) -- Reduced width to accommodate X button
                btn.deleteBtn.globalIndex = emoteData.globalIndex
                btn.deleteBtn.emoteLabel = emoteData.label
                btn.deleteBtn:Show()
            else
                btn:SetWidth(204) -- Full width
                btn.deleteBtn:Hide()
            end
            if GameTooltip:GetOwner() == btn then
                if btn.emoteId and btn.emoteId ~= "" then
                    GameTooltip:SetText("ID: [" .. tostring(btn.emoteId) .. "]")
                    GameTooltip:Show()
                else
                    GameTooltip:Hide()
                end
            end
        else
            btn:Hide()
            btn.emoteId = nil
            btn.globalIndex = nil
            btn.deleteBtn:Hide()
            if GameTooltip:GetOwner() == btn then
                GameTooltip:Hide()
            end
        end
    end

    -- Update Footer Page Indicator
    if pageText then
        if #displayList > addon.Menu.EMOTES_PER_PAGE then
            pageText:SetText("Page " .. currentPage .. " / " .. totalPages .. " (Scroll)")
            pageText:Show()
        else
            pageText:SetText("")
            pageText:Hide()
        end
    end
end

--- Opens the context dialog modal in Add Mode
local function OpenAddEmoteDialog()
    if not addFrame then return end
    addFrame.title:SetText("Add Custom Emote")
    addFrame.editIndex = nil
    addFrame.labelInput:SetText("")
    addFrame.idInput:SetText("")
    addFrame:Show()
    addFrame.labelInput:SetFocus()
end

--- Opens the context dialog modal in Edit Mode
local function OpenEditEmoteDialog(globalIndex, label, emoteId)
    if not addFrame then return end
    addFrame.title:SetText("Edit Emote")
    addFrame.editIndex = globalIndex
    addFrame.labelInput:SetText(label or "")
    addFrame.idInput:SetText(emoteId or "")
    addFrame:Show()
    addFrame.labelInput:SetFocus()
end

--- Opens the delete confirmation dialog modal
local function OpenDeleteConfirmationDialog(deleteIndex, emoteLabel)
    if not confirmDeleteFrame then return end
    confirmDeleteFrame.deleteIndex = deleteIndex
    confirmDeleteFrame.msgText:SetText("Are you sure you want to delete\n'" .. (emoteLabel or "") .. "'?")
    confirmDeleteFrame:Show()
end

--- Creates the Add/Edit Emote context window modal
local function CreateAddEmoteFrame()
    local frame = CreateFrame("Frame", "EmotionsAddFrame", UIParent, backdropTemplate)
    frame:SetSize(280, 180)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
        frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    end

    -- Modal Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    title:SetPoint("TOP", frame, "TOP", 0, -12)
    title:SetText("Add Custom Emote")
    frame.title = title

    -- Label EditBox
    local labelTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -38)
    labelTitle:SetText("Label (Menu Display):")

    local labelInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    labelInput:SetSize(235, 22)
    labelInput:SetPoint("TOPLEFT", labelTitle, "BOTTOMLEFT", 4, -4)
    labelInput:SetAutoFocus(false)
    frame.labelInput = labelInput

    -- Emote ID EditBox
    local idTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    idTitle:SetPoint("TOPLEFT", labelInput, "BOTTOMLEFT", -4, -8)
    idTitle:SetText("Emote ID (.mod stand ID):")

    local idInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    idInput:SetSize(235, 22)
    idInput:SetPoint("TOPLEFT", idTitle, "BOTTOMLEFT", 4, -4)
    idInput:SetAutoFocus(false)
    idInput:SetNumeric(true)
    frame.idInput = idInput

    -- Save Button
    local saveBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveBtn:SetSize(90, 22)
    saveBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 25, 15)
    saveBtn:SetText("Save")
    saveBtn:SetScript("OnClick", function()
        local labelVal = labelInput:GetText()
        local idVal = idInput:GetText()

        local ok, err
        if frame.editIndex then
            ok, err = addon.Storage.UpdateEmote(frame.editIndex, labelVal, idVal)
        else
            ok, err = addon.Storage.AddEmote(labelVal, idVal)
        end

        if ok then
            frame:Hide()
            RefreshMenu()
        else
            UIErrorsFrame:AddMessage(err or "Invalid input.", 1.0, 0.1, 0.1, 1.0)
        end
    end)

    -- Cancel Button
    local cancelBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelBtn:SetSize(90, 22)
    cancelBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -25, 15)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame:Hide()
    return frame
end

--- Creates the Delete Confirmation Modal dialog
local function CreateConfirmDeleteFrame()
    local frame = CreateFrame("Frame", "EmotionsConfirmDeleteFrame", UIParent, backdropTemplate)
    frame:SetSize(260, 140)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
        frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    end

    -- Modal Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    title:SetPoint("TOP", frame, "TOP", 0, -12)
    title:SetText("Confirm Deletion")

    -- Confirmation Message Text
    local msgText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    msgText:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
    msgText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -35)
    msgText:SetJustifyH("CENTER")
    frame.msgText = msgText

    -- Warning Notice Text
    local warnText = frame:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
    warnText:SetPoint("TOP", msgText, "BOTTOM", 0, -8)
    warnText:SetText("This action cannot be undone.")

    -- Delete Button
    local deleteBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteBtn:SetSize(90, 22)
    deleteBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 25, 15)
    deleteBtn:SetText("Delete")
    deleteBtn:SetScript("OnClick", function()
        if frame.deleteIndex then
            addon.Storage.RemoveEmote(frame.deleteIndex)
            frame:Hide()
            RefreshMenu()
        end
    end)

    -- Cancel Button
    local cancelBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelBtn:SetSize(90, 22)
    cancelBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -25, 15)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame:Hide()
    return frame
end

--- Creates the conceptual menu frame with header icons and scroll pagination
local function CreateMenuFrame()
    local frame = CreateFrame("Frame", "EmotionsMenuFrame", UIParent, backdropTemplate)
    frame:SetSize(220, 316)
    frame:SetPoint("BOTTOMLEFT", launcherButton, "TOPLEFT", 0, 8)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
        addon.Storage.SaveMenuPosition(point, relativePoint or "BOTTOMLEFT", xOfs, yOfs)
    end)

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        frame:SetBackdropColor(0.08, 0.08, 0.1, 0.95)
    end

    -- Menu Header Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -8)
    title:SetText("Emotions")

    -- Close Button
    local closeBtn = CreateFrame("Button", "EmotionsCloseButton", frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Edit Icon Button
    local editBtn = CreateFrame("Button", "EmotionsEditButton", frame)
    editBtn:SetSize(22, 22)
    editBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)

    -- Add Icon Button
    local addBtn = CreateFrame("Button", "EmotionsAddButton", frame)
    addBtn:SetSize(22, 22)
    addBtn:SetPoint("RIGHT", editBtn, "LEFT", -6, 0)

    local addTex = addBtn:CreateTexture(nil, "ARTWORK")
    addTex:SetAllPoints()
    addTex:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")

    local addHl = addBtn:CreateTexture(nil, "HIGHLIGHT")
    addHl:SetAllPoints()
    addHl:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight")

    addBtn:SetScript("OnMouseDown", function()
        addTex:SetTexture("Interface\\Buttons\\UI-PlusButton-Down")
    end)
    addBtn:SetScript("OnMouseUp", function()
        addTex:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
    end)
    addBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Add Emote")
        GameTooltip:Show()
    end)
    addBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    addBtn:SetScript("OnClick", function()
        OpenAddEmoteDialog()
    end)
    addButton = addBtn

    local editTex = editBtn:CreateTexture(nil, "ARTWORK")
    editTex:SetAllPoints()
    editTex:SetTexture("Interface\\WorldMap\\GEAR_64")

    local editHl = editBtn:CreateTexture(nil, "HIGHLIGHT")
    editHl:SetAllPoints()
    editHl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")

    local editActive = editBtn:CreateTexture(nil, "OVERLAY")
    editActive:SetAllPoints()
    editActive:SetColorTexture(1, 0.8, 0, 0.35)
    editActive:Hide()
    editBtn.activeTex = editActive

    editBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Toggle Edit Mode")
        GameTooltip:Show()
    end)
    editBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    editBtn:SetScript("OnClick", function()
        isEditMode = not isEditMode
        if isEditMode then
            editActive:Show()
        else
            editActive:Hide()
        end
        RefreshMenu()
    end)
    editButton = editBtn

    -- Search EditBox
    local searchInput = CreateFrame("EditBox", "EmotionsSearchInput", frame, "InputBoxTemplate")
    searchInput:SetSize(196, 22)
    searchInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -32)
    searchInput:SetAutoFocus(false)
    -- Add placeholder text
    searchInput.placeholder = searchInput:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    searchInput.placeholder:SetPoint("LEFT", searchInput, "LEFT", 0, 0)
    searchInput.placeholder:SetText("Search by name or id")
    searchInput:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text == "" then
            self.placeholder:Show()
        else
            self.placeholder:Hide()
        end
        searchQuery = string.lower(text)
        currentPage = 1
        RefreshMenu()
    end)

    -- Generate 9 emote slots (Options 1 to 9)
    for i = 1, addon.Menu.EMOTES_PER_PAGE do
        local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        btn:SetSize(204, 22)

        if i == 1 then
            btn:SetPoint("TOPLEFT", searchInput, "BOTTOMLEFT", -4, -6)
        else
            btn:SetPoint("TOPLEFT", itemSlots[i - 1], "BOTTOMLEFT", 0, -2)
        end

        -- Child Quick-Delete "X" Button
        local deleteBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        deleteBtn:SetSize(22, 22)
        deleteBtn:SetPoint("LEFT", btn, "RIGHT", 4, 0)
        deleteBtn:SetText("X")
        deleteBtn:SetNormalFontObject("GameFontRed")
        deleteBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Delete Emote")
            GameTooltip:Show()
        end)
        deleteBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        deleteBtn:SetScript("OnClick", function(self)
            if self.globalIndex and self.emoteLabel then
                OpenDeleteConfirmationDialog(self.globalIndex, self.emoteLabel)
            end
        end)
        deleteBtn:Hide()
        btn.deleteBtn = deleteBtn

        btn:SetScript("OnEnter", function(self)
            if self.emoteId and self.emoteId ~= "" then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("ID: " .. tostring(self.emoteId))
                GameTooltip:Show()
            end
        end)

        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        btn:SetScript("OnClick", function(self)
            if isEditMode then
                if self.globalIndex and self.emoteId then
                    OpenEditEmoteDialog(self.globalIndex, self:GetText(), self.emoteId)
                end
            elseif self.emoteId then
                ExecuteEmoteCommand(self.emoteId)
            end
        end)

        itemSlots[i] = btn
    end

    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(self, delta)
        -- Actually totalPages could be dependent on the current list
        -- A simpler way is to just call GetTotalPages inside RefreshMenu or recalculate
        -- We can just check the global pageText or get current filtered size.
        -- But for now we can just rely on the bounded currentPage in RefreshMenu.
        if delta < 0 then
            currentPage = currentPage + 1
            RefreshMenu()
        elseif delta > 0 then
            if currentPage > 1 then
                currentPage = currentPage - 1
                RefreshMenu()
            end
        end
    end)

    -- Page Indicator Text at Bottom
    pageText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    pageText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 6)

    frame:Hide()
    return frame
end

--- Creates the persistent launcher icon button over native chat controls
local function CreateLauncherButton()
    local parentFrame = ChatFrame1ButtonFrame or ChatFrame1 or UIParent
    local btn = CreateFrame("Button", "EmotionsLauncherButton", parentFrame)
    btn:SetSize(21, 21)

    -- Icon Texture
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Icons\\ability_warrior_intensifyrage")
    btn.icon = icon

    -- Highlight Texture
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.3)

    -- Mouse Press Feedback
    btn:SetScript("OnMouseDown", function()
        icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    end)
    btn:SetScript("OnMouseUp", function()
        icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    end)

    -- Anchor relative to native chat options buttons (on top) or editbox fallback
    if ChatFrameChannelButton then
        btn:SetPoint("BOTTOM", ChatFrameChannelButton, "BOTTOM", 0, -60)
    elseif ChatFrameMenuButton then
        btn:SetPoint("BOTTOM", ChatFrameMenuButton, "BOTTOM", 0, -60)
    elseif QuickJoinToastButton then
        btn:SetPoint("BOTTOM", QuickJoinToastButton, "BOTTOM", 0, -60)
    elseif ChatFrame1EditBox then
        btn:SetPoint("BOTTOMLEFT", ChatFrame1EditBox, "BOTTOMLEFT", 0, -60)
    else
        btn:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 18, -60)
    end

    btn:SetFrameStrata("MEDIUM")

    btn:SetScript("OnClick", function()
        if menuFrame:IsShown() then
            menuFrame:Hide()
        else
            local pos = addon.Storage.GetMenuPosition()
            if pos then
                menuFrame:ClearAllPoints()
                menuFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
            end
            menuFrame:Show()
            RefreshMenu()
        end
    end)

    return btn
end

--- Main initialization orchestrator called on PLAYER_LOGIN
local function OnPlayerLogin()
    launcherButton = CreateLauncherButton()
    addFrame = CreateAddEmoteFrame()
    confirmDeleteFrame = CreateConfirmDeleteFrame()
    menuFrame = CreateMenuFrame()
end

-- Register addon event callbacks
addon.Events.Init(
    function() -- ADDON_LOADED
        addon.Storage.Init()
    end,
    function() -- PLAYER_LOGIN
        OnPlayerLogin()
    end
)
