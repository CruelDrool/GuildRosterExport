---@class Private
local Private = select(2, ...)

---@class Debug
local Debug = Private.Debug

---@class Translate
local Translate = Private.Translate

---@class Utils
local Utils = {}

Utils.colors = {
	tooltip = {
		default = CreateColor(1, 1, 1,0),
		highlight = CreateColor(1, 1, 0, 0),
	}
}

Utils.sounds = {
	openOptions = 88, -- "GAMEDIALOGOPEN"
	closeOptions = 624, -- "GAMEGENERICBUTTONPRESS"
	closeExportFrame = SOUNDKIT.GS_TITLE_OPTION_EXIT
}

Utils.libs = {
	AceAddon = LibStub("AceAddon-3.0"),
	LibDataBroker = LibStub("LibDataBroker-1.1", true),
	LibDBIcon = LibStub("LibDBIcon-1.0", true),
	AceConfigDialog = LibStub("AceConfigDialog-3.0"),
	AceConfigRegistry = LibStub("AceConfigRegistry-3.0"),
	AceDB = LibStub("AceDB-3.0"),
	AceDBOptions = LibStub("AceDBOptions-3.0"),
}

function Utils.GetTabSub(n)
	local str = ""

	for i=1, n do
		str = str .. " "
	end

	return str
end

Private.Utils = Utils
