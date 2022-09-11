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
L["|cffffff00Click|r to toggle the export interface.\nOr use /%s"] = true

-- CONFIGURATION --
L["Export"] = true
L["WARNING! Large exports may freeze your game for several seconds!"] = true
L["Global"] = true
L["Remove realm name"] = true
L["With this setting enabled, the realm name will be removed from character names in column #1."] = true
L["Adjust %s"] = true -- rankIndex
L["%s normally starts at 0, but this setting adjust that to 1."] = true -- rankIndex
L["Maximum letters"] = true
L["Set the maximum number of letters that the export window can show. Set to empty or 0 to use Blizzard's default."] = true
L["Indentation style"] = true
L["Set indentation style. Used when exporting JSON and XML."] = true
L["Spaces"] = true
L["Tabs"] = true
L["Indentation depth (spaces)"] = true
L["Set the depth used when spaces are set as indentation style. Smaller depth shortens the time before the data is displayed."] = true
L["Spaces are the default indentation style because tabs may be displayed as a strange symbol in the export window. However, copying the tabs work just fine and will be displayed correctly in a text editor."] = true
L["Settings"] = true
L["File format"] = true
L["CSV"] = true
L["Delimiter"] = true
L["Enclosure"] = true
L["XML"] = true
L["Root element name"] = true
L["Each record's element name"] = true
L["Columns"] = true
L["Ranks"] = true
L["Unknown"] = true
L["%1$s Default column name: \"%2$s\"."] = true
L["JSON"] = true
L["YAML"] = true
L["Minify"] = true
L["Quotation mark"] = true
L["What type of quotation mark to use when strings need to be put in quotes."] = true
L["Double"] = true
L["Single"] = true

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
