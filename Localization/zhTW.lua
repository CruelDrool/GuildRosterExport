---@class Private
local Private = select(2, ...)

local L = Private.Translate:RegisterLocale("zhTW")
if not L then return end

--@localization(locale="zhTW", format="lua_additive_table", same-key-is-true=true)@
