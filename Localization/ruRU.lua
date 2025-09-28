---@class Private
local Private = select(2, ...)

local L = Private.Translate:RegisterLocale("ruRU")
if not L then return end

--@localization(locale="ruRU", format="lua_additive_table", same-key-is-true=true)@
