---@class Private
local Private = select(2, ...)

local L = Private.Translate:RegisterLocale("esMX")
if not L then return end

--@localization(locale="esMX", format="lua_additive_table", same-key-is-true=true)@
