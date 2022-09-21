local addonName = ...
-- English localization file for enUS and enGB.
local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale(addonName, "enUS", true)
if not L then return end

-- EXPORT FRAME --
L["Close"] = true
L["Close & Return"] = true

-- MINIMAP ICON --
L["%sClick%s to toggle options."] = true -- %s is the text color wrapping.
L["Or use /%s"] = true -- %s is the chat command.

-- CHAT COMMAND --
L["Toggle options"] = true
L["Print this help"] = true
L["Do an export"] = true
L["Supported file formats:"] = true
L["file format"] = true

-- FILE FORMATS --
L["CSV"] = true
L["HTML"] = true
L["XML"] = true
L["JSON"] = true
L["YAML"] = true

-- OPTIONS --
L["Minimap icon"] = true
L["Show an icon to open the config at the Minimap"] = true
L["Export"] = true
L["WARNING! Large exports may freeze your game for several seconds!"] = true
L["Settings"] = true
L["Minify"] = true
L["Enabled"] = true

-- OPTIONS: Settings - Columns --
L["Columns"] = true
L["%1$s Default column name: \"%2$s\"."] = true -- %1$s is column description, %2$s is column name.

-- OPTIONS: Settings - Column descriptions --
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

-- OPTIONS: Settings - Ranks --
L["Ranks"] = true
L["Unknown"] = true

-- OPTIONS: Settings -> Global --
L["Global"] = true
L["Remove realm name in column #1"] = true
L["Adjust rank index in column #3"] = true
L["The index normally starts at 0, but this setting adjust that to 1."] = true
L["Auto export"] = true
L["Automatically do an export whenever the guild roster updates and save it in this character's database profile, which is stored within this addon's saved variable. The export frame won't be shown."] = true

-- OPTIONS: Settings -> Global - Export frame --
L["Export frame"] = true
L["Maximum letters"] = true
L["Set the maximum number of letters that the export window can show. Set to empty or 0 to use Blizzard's default."] = true

-- OPTIONS: Settings -> Global - Indentation --
L["Indentation"] = true
L["Style"] = true
L["Select what style to use when exporting JSON and XML."] = true
L["Spaces"] = true
L["Tabs"] = true
L["Depth"] = true
L["Set the depth used when spaces are set as indentation style. Smaller depth shortens the time before the data is displayed."] = true
L["Spaces are the default indentation style because tabs may be displayed as a strange symbol in the export window. However, copying the tabs work just fine and will be displayed correctly in a text editor."] = true

-- OPTIONS: Settings -> CSV --
L["Delimiter"] = true
L["Enclosure"] = true

-- OPTIONS: Settings -> HTML --
L["Table header"] = true

-- OPTIONS: Settings -> HTML - WordPress --
L["WordPress"] = true
L["Output as a WordPress block (Gutenberg editor)."] = true
L["Only use this if you know what you're doing. It requires you to edit the post's code directly. This will also minify the HTML code."] = true
L["Striped style"] = true
L["Fixed width table cells"] = true

-- OPTIONS: Settings -> XML --
L["Root element name"] = true
L["Each record's element name"] = true

-- OPTIONS: Settings -> JSON --

-- OPTIONS: Settings -> YAML --
L["Quotation mark"] = true
L["What type of quotation mark to use when strings need to be put in quotes."] = true
L["Double"] = true
L["Single"] = true
