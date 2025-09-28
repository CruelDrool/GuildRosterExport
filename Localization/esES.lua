---@class Private
local Private = select(2, ...)

local L = Private.Translate:RegisterLocale("esES")
if not L then return end

--@localization(locale="esES", format="lua_additive_table", same-key-is-true=true)@
