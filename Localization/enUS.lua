local addonName = ...
-- English localization file for enUS and enGB.
local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale(addonName, "enUS", true)
if not L then return end

-- EXPORT FRAME --
L["Close"] = true

-- MINIMAP ICON --
L["Minimap Icon"] = true
L["Show a Icon to open the config at the Minimap"] = true
L["|cffffff00Right-click|r to open the options menu"] = true
L["|cffffff00Left-click|r to export data based upon your settings"] = true

-- CONFIGURATION --
L["Settings"] = true
L["Export type"] = true
L["CSV export settings"] = true
L["Delimiter"] = true
L["Enclosure"] = true
L["Columns"] = true
L["%s Default column name: \"%s\"."] = true
L["Miscellaneous"] = true
L["Remove realm name from player names (column #1)"] = true
L["Adjust %s"] = true -- rankIndex
L["%s normally starts at 0, but this setting adjust that to 1."] = true -- rankIndex

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