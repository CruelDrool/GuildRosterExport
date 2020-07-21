local addonName = ...
-- English localization file for enUS and enGB.
local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale(addonName, "enUS", true)
if not L then return end

-- EXPORT FRAME --
L["Close"] = true
L["Close & Return"] = true

-- MINIMAP ICON --
L["Minimap Icon"] = true
L["Show a Icon to open the config at the Minimap"] = true
L["|cffffff00Right-click|r to open the export interface.\nOr use /%s"] = true

-- CONFIGURATION --
L["Export"] = true
L["WARNING! Large exports may freeze your game for several seconds!"] = true
L["Global"] = true
L["Remove realm name"] = true
L["With this setting enabled, the realm name will be removed from character names in column #1."] = true
L["Adjust %s"] = true -- rankIndex
L["%s normally starts at 0, but this setting adjust that to 1."] = true -- rankIndex
L["Maximum letters"] = true
L["Set the maximum number of letters that the export window can show."] = true
L["Tab size"] = true
L["Set the tab size in number of spaces. Used when exporting JSON, XML and YAML. Shorter tab size shortens the time before the data is displayed. Note: YAML-exports ignores a value of 0, and will default to 1."] = true
L["Settings"] = true
L["Export type"] = true
L["CSV"] = true
L["Delimiter"] = true
L["Enclosure"] = true
L["XML"] = true
L["Root element name"] = true
L["Each record's element name"] = true
L["Columns"] = true
L["Ranks"] = true
L["|cffff0000Unable to extract rank name information. You are currently not in a guild.|r"] = true
L["Unknown"] = true
L["%1$s Default column name: \"%2$s\"."] = true

-- COLUMN DESCRIPTIONS --
L["String - Name of character with realm (e.g. \"Arthas-Silvermoon\"). This addon defaults to removing the realm name."] = true
L["String - Name of character's guild rank."] = true
L["Number - Index of rank, starting at 0 for Guild Master. This addon defaults to adjusting that to 1."] = true
L["Number - Character's level."] = true
L["String - Localised class name."] = true
L["String - Character's location (last location if offline)."] = true
L["String - Character's public note. Empty if you can't view notes."] = true
L["String - Character's officer note. Empty if you can't view officer notes."] = true
L["Boolean - true: online; false: offline."] = true
L["Number - 0: none; 1: AFK; 2: Busy."] = true
L["String - Upper-case, localisation-independent class name."] = true
L["Number - Character's achievement points."] = true
L["Number - Where the character ranks in guild in terms of achievement points."] = true
L["Boolean - true: player logged in via mobile app."] = true
L["Boolean - Scroll of Resurrection eligible."] = true
L["Number - Standing ID for character's guild reputation"] = true
L["String - Character's Globally Unique Identifier."] = true