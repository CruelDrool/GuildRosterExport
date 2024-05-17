local addonName = ...
-- English localization file for enUS and enGB.
local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale(addonName, "enUS", true)

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
L["Show an icon to open the config at the Minimap."] = true
L["Export"] = true
L["WARNING! Large exports may freeze your game for several seconds!"] = true
L["Settings"] = true
L["Minify"] = true
L["To minify means removing unnecessary characters and putting everything on one single line to save space."] = true
L["Enabled"] = true
L["Boolean"] = true
L["Number"] = true
L["String"] = true

-- OPTIONS: Settings - Columns --
L["Columns"] = true
L[ [[%1$s Default column name: "%2$s".]] ] = true -- %1$s is column description, %2$s is column name.

-- OPTIONS: Settings - Column descriptions --
L["%1$s - %2$s"] = true -- %1$s is the type of value (boolean, number, string), %2$s is the description.
L[ [[Character's name with realm name included (e.g., "Arthas-Silvermoon"). This addon defaults to removing the realm name.]] ] = true -- 1
L["Name of the character's guild rank."] = true -- 2
L["Index of rank, starting at 0 for Guild Master. This addon defaults to adjusting that to 1."] = true -- 3
L["Character's level."] = true -- 4
L["Localized class name."] = true -- 5
L["Character's location (last location if offline)."] = true -- 6
L["Character's public note. Empty if you can't view notes."] = true -- 7
L["Character's officer note. Empty if you can't view officer notes."] = true -- 8
L["true: online; false: offline."] = true -- 9
L["0: none; 1: AFK; 2: busy."] = true -- 10
L["Upper-case, non-localized class name."] = true -- 11
L["Character's achievement points."] = true -- 12
L["Where the character ranks in the guild in terms of achievement points."] = true -- 13
L["true: the character is logged in via the mobile app."] = true -- 14
L[ [[true: the character is eligible for "Scroll of Resurrection".]] ] = true -- 15
L["Standing ID for the character's guild reputation."] = true -- 16
L["Character's Globally Unique Identifier."] = true -- 17
L["UNIX timestamp. Note that since Blizzard's API doesn't return minutes, this timestamp may be wrong by an hour."] = true -- 18

-- OPTIONS: Settings - Ranks --
L["Ranks"] = true
L["Unknown"] = true

-- OPTIONS: Settings -> Global --
L["Global"] = true
L["Remove realm name in column #1"] = true
L[ [["Arthas-Silvermoon" will become "Arthas".]] ] = true
L["Adjust rank index in column #3"] = true
L["The index normally starts at 0, but this setting adjusts that to 1."] = true
L["Use hours since last online in column #18"] = true
L["Calculates how many hours have passed since last being online."] = true
L["Auto export"] = true
L["Automatically do an export whenever the guild roster updates and save it in this character's database profile, which is stored within this addon's saved variable. The export frame won't be shown."] = true

-- OPTIONS: Settings -> Global - Export frame --
L["Export frame"] = true
L["Maximum letters"] = true
L["Set the maximum number of letters that the export window can show. Set this to empty or 0 to use Blizzard's default."] = true

-- OPTIONS: Settings -> Global - Indentation --
L["Indentation"] = true
L["Style"] = true
L["Select what style to use when exporting HTML, JSON, and XML."] = true
L["Spaces"] = true
L["Tabs"] = true
L["Depth"] = true
L["Set the depth used when spaces are set as indentation style. A smaller depth shortens the time before the data is displayed."] = true
L["Spaces are the default indentation style because tabs may be displayed as a strange symbol in the export window. However, copying the tabs works just fine and will be displayed correctly in a text editor."] = true

-- OPTIONS: Settings -> CSV --
L["Header"] = true
L["Whether or not to have the column names added to top of the CSV output."] = true
L["Enclosure"] = true
L["Character that is used when enclosing values."] = true
L["Delimiter"] = true
L["Character that is used when separating values."] = true

-- OPTIONS: Settings -> HTML --
L["Table header"] = true
L["Whether or not to have the column names added to the table."] = true

-- OPTIONS: Settings -> HTML - WordPress --
L["WordPress"] = true
L["Output as a WordPress block (Gutenberg editor)."] = true
L["Only use this if you know what you're doing. It requires you to edit the post's code directly. This will also minify the HTML code."] = true
L["Striped style"] = true
L["Fixed-width table cells"] = true

-- OPTIONS: Settings -> XML --
L["Root element name"] = true
L["Each record's element name"] = true

-- OPTIONS: Settings -> JSON --

-- OPTIONS: Settings -> YAML --
L["Quotation mark"] = true
L["What type of quotation mark to use when strings need to be put in quotes."] = true
L["Double"] = true
L["Single"] = true
