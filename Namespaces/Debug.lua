---@class Private
local Private = select(2, ...)
local addonName = ...

local DLAPI = _G["DLAPI"]
--@debug@
DEVTOOLS_MAX_ENTRY_CUTOFF = 100
DEVTOOLS_DEPTH_CUTOFF = 20
--@end-debug@

---@class Debug
local Debug = {}

function Debug:IsEnabled()
	return DLAPI and true
end

function Debug:Log(...)
	if self:IsEnabled() then
		local status, res = pcall(format, ...)
		if status then
			DLAPI.DebugLog(addonName, res)
		end
	end
end

-- Add to the addon's private namespace.
Private.Debug = setmetatable(Debug, {
	__call = Debug.Log
})
