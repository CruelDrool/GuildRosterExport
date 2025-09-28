---@class Private
local Private = select(2, ...)

local L = Private.Translate:RegisterLocale("ptBR")
if not L then return end

--@localization(locale="ptBR", format="lua_additive_table", same-key-is-true=true)@
