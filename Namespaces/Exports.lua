---@class Private
local Private = select(2, ...)
local addonName = ...

---@class Debug
local Debug = Private.Debug

---@class Settings
local Settings = Private.Settings

---@class Exports
local Exports = {}

local registry = {}

function Exports:RegisterExport(fileFormat,displayName, obj, funcName)
	registry[fileFormat] = {obj, funcName}
	Settings:RegisterFileFormat(fileFormat, displayName)
end


function Exports:DoExport(fileFormat, data)
	local obj, funcName = unpack(registry[fileFormat])

	return obj[funcName](obj, data)
end

Private.Exports = Exports
