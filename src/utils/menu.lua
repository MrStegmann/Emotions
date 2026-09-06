local addonName, addon = ...
local Emotions = addon.Emotions
Emotions.Menu = {}

Emotions.Menu.EMOTES_PER_PAGE = 9 -- Option 1 is "Add Emote", 9 slots available for emotes per page

--- Calculates total number of pagination pages needed for emotes
-- @param totalEmotes number Count of saved emotes
-- @return number Total pages (minimum 1)
function Emotions.Menu.GetTotalPages(totalEmotes)
    if not totalEmotes or totalEmotes <= 0 then
        return 1
    end
    return math.max(1, math.ceil(totalEmotes / Emotions.Menu.EMOTES_PER_PAGE))
end

--- Returns the slice of emotes to display for a given page index
-- @param emotes table Array of emote objects { label, id }
-- @param pageIndex number 1-based page number
-- @return table Slice of emote objects, number startIndex
function Emotions.Menu.GetPageSlice(emotes, pageIndex)
    emotes = emotes or {}
    local totalPages = Emotions.Menu.GetTotalPages(#emotes)
    pageIndex = math.min(math.max(1, pageIndex or 1), totalPages)

    local startIndex = (pageIndex - 1) * Emotions.Menu.EMOTES_PER_PAGE + 1
    local endIndex = math.min(#emotes, pageIndex * Emotions.Menu.EMOTES_PER_PAGE)

    local slice = {}
    for i = startIndex, endIndex do
        table.insert(slice, {
            globalIndex = emotes[i].globalIndex or i,
            label = emotes[i].label,
            id = emotes[i].id
        })
    end

    return slice, startIndex
end
