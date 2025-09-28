---@class Private
local Private = select(2, ...)
local addonName = ...

---@class Debug
local Debug = Private.Debug

---@class Translate
Translate = Private.Translate

---@class Addon: AceAddon
---@class Addon: AceConsole-3.0
---@class Addon: AceEvent-3.0
local Addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")


Private.Addon = Addon

Private.libs = {
	LibDataBroker = LibStub("LibDataBroker-1.1", true),
	LibDBIcon = LibStub("LibDBIcon-1.0", true),
	AceConfigDialog = LibStub("AceConfigDialog-3.0"),
	AceConfigRegistry = LibStub("AceConfigRegistry-3.0"),
	AceDB = LibStub("AceDB-3.0"),
	AceDBOptions = LibStub("AceDBOptions-3.0"),
}

Private.colors = {
	tooltip = {
		default = CreateColor(1, 1, 1,0),
		highlight = CreateColor(1, 1, 0, 0),
	}
}