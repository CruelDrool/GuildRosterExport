---@class Private
local Private = select(2, ...)

local L = Private.Translate:RegisterLocale("zhCN")
if not L then return end

--@localization(locale="zhCN", format="lua_additive_table", same-key-is-true=true)@
