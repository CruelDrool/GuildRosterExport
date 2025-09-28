---@class Private
local Private = select(2, ...)

local L = Private.Translate:RegisterLocale("deDE")
if not L then return end

--@localization(locale="deDE", format="lua_additive_table", same-key-is-true=true)@
