---@class Private
local Private = select(2, ...)

local L = Private.Translate:RegisterLocale("itIT")
if not L then return end

--@localization(locale="itIT", format="lua_additive_table", same-key-is-true=true)@
