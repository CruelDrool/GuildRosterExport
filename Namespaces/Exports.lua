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

function Exports:RegisterExport(obj)
	registry[obj.fileFormat] = obj
	Settings:RegisterFileFormat(obj.fileFormat, obj.displayName)
	Settings:RegisterFileFormatDefaults(obj.fileFormat, obj.defaults)
	Settings:RegisterFileFormatOptions(obj.fileFormat, obj.GetOptions)
end


function Exports:DoExport(fileFormat, data)
	local obj = registry[fileFormat]

	return obj.Export(data)
end

Private.Exports = Exports
