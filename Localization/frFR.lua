---@class Private
local Private = select(2, ...)

local L = Private.Translate:RegisterLocale("frFR")
if not L then return end

--@localization(locale="frFR", format="lua_additive_table", same-key-is-true=true)@
