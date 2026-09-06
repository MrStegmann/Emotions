local addonName, addon = ...
addon.Emotions = addon.Emotions or {}
local Emotions = addon.Emotions

Emotions.Storage = {}

--- Initialized SavedVariables data structure if missing
function Emotions.Storage.Init()
    if type(EmotionsDB) ~= "table" then
        EmotionsDB = {
            version = 1,
            emotes = {}
        }
    end
    if type(EmotionsDB.emotes) ~= "table" then
        EmotionsDB.emotes = {}
    end
    if type(EmotionsDB.menuPosition) ~= "table" then
        EmotionsDB.menuPosition = nil -- Initialized as nil, saved dynamically
    end
end

--- Returns the list of saved emote entries
-- @return table List of { label = string, id = string }
function Emotions.Storage.GetEmotes()
    if not EmotionsDB or not EmotionsDB.emotes then
        return {}
    end
    return EmotionsDB.emotes
end

--- Adds a new emote to SavedVariables
-- @param label string Display label in the menu
-- @param id string Emote ID number or string
-- @return boolean, string Success status and optional error message
function Emotions.Storage.AddEmote(label, id)
    Emotions.Storage.Init()
    
    local cleanLabel = tostring(label or ""):gsub("^%s*(.-)%s*$", "%1")
    local cleanId = tostring(id or ""):gsub("^%s*(.-)%s*$", "%1")

    if cleanLabel == "" or cleanId == "" then
        return false, "Label and Emote ID must be non-empty."
    end

    table.insert(EmotionsDB.emotes, {
        label = cleanLabel,
        id = cleanId
    })
    return true
end

--- Updates an existing saved emote by index
-- @param index number Position index in the table
-- @param label string New display label
-- @param id string New emote ID
-- @return boolean, string Success status and optional error message
function Emotions.Storage.UpdateEmote(index, label, id)
    if not EmotionsDB or not EmotionsDB.emotes or not EmotionsDB.emotes[index] then
        return false, "Emote index out of bounds."
    end

    local cleanLabel = tostring(label or ""):gsub("^%s*(.-)%s*$", "%1")
    local cleanId = tostring(id or ""):gsub("^%s*(.-)%s*$", "%1")

    if cleanLabel == "" or cleanId == "" then
        return false, "Label and Emote ID must be non-empty."
    end

    EmotionsDB.emotes[index] = {
        label = cleanLabel,
        id = cleanId
    }
    return true
end

--- Removes a saved emote by index
-- @param index number Position index in the table
-- @return boolean Success status
function Emotions.Storage.RemoveEmote(index)
    if EmotionsDB and EmotionsDB.emotes and EmotionsDB.emotes[index] then
        table.remove(EmotionsDB.emotes, index)
        return true
    end
    return false
end

--- Saves the main menu frame position
-- @param point string The anchor point
-- @param relativePoint string The relative anchor point on UIParent
-- @param xOfs number The X offset
-- @param yOfs number The Y offset
function Emotions.Storage.SaveMenuPosition(point, relativePoint, xOfs, yOfs)
    Emotions.Storage.Init()
    EmotionsDB.menuPosition = {
        point = point,
        relativePoint = relativePoint,
        xOfs = xOfs,
        yOfs = yOfs
    }
end

--- Returns the saved menu position
-- @return table|nil Table containing position data, or nil if not set
function Emotions.Storage.GetMenuPosition()
    if not EmotionsDB then return nil end
    return EmotionsDB.menuPosition
end
