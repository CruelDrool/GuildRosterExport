---@class Private
local Private = select(2, ...)
local addonName = ...

---@class Debug
local Debug = Private.Debug

---@class Addon
local Addon = Private.Addon

local L = Private.Translate:GetLocaleEntries()

local LibDataBroker = Private.libs.LibDataBroker
local LibDBIcon = Private.libs.LibDBIcon
local AceConfigDialog = Private.libs.AceConfigDialog
local AceConfigRegistry = Private.libs.AceConfigRegistry
local AceDB = Private.libs.AceDB
local AceDBOptions = Private.libs.AceDBOptions

---@class Settings
local Settings = {}

Private.Settings = Settings

-- Base options table.
local options = {
		name = addonName,
		childGroups = "tree",
		type = "group",
		plugins = {},
}

local defaults = {
	profile = {
		minimapIcon = {
			showInCompartment = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
		},
		fileFormat = "csv";
		removeRealmFromName = true,
		adjustRankIndex = true,
		lastOnlineHours = false,
		autoExport = false,
		indentation = {
			style = "spaces",
			depth = 4,
		},
		csv = {
			header = true,
			delimiter = ',',
			enclosure = '"',
		},
		html = {
			tableHeader = true,
			style = "compacted",
			wp = {
				enabled = false,
				stripedStyle = false,
				fixedWidth = false,
			},
		},
		json = {
			style = "compacted",
		},
		xml = {
			rootElementName = "GuildRoster",
			recordElementName = "Character",
			style = "compacted",
		},
		yaml = {
			quotationMark = "single",
			style = "compacted",
		},
		columns = {
			{enabled = true, name = "name"}, -- 1
			{enabled = true, name = "rankName"}, -- 2
			{enabled = true, name = "rankIndex"}, -- 3
			{enabled = true, name = "level"}, -- 4
			{enabled = true, name = "class"}, -- 5
			{enabled = false, name = "zone"}, -- 6
			{enabled = false, name = "note"}, -- 7
			{enabled = false, name = "officerNote"}, -- 8
			{enabled = false, name = "isOnline"}, -- 9
			{enabled = false, name = "status"}, -- 10
			{enabled = false, name = "classFileName"}, -- 11
			{enabled = false, name = "achievementPoints"}, -- 12
			{enabled = false, name = "achievementRank"}, -- 13
			{enabled = false, name = "isMobile"}, -- 14
			{enabled = false, name = "isSoREligible"}, -- 15
			{enabled = false, name = "repStandingID"}, -- 16
			{enabled = false, name = "GUID"}, -- 17
			{enabled = false, name = "lastOnline"}, -- 18
			{enabled = false, name = "realmName"}, -- 19
		},
		ranks = {
			true, -- 1
			true, -- 2
			true, -- 3
			true, -- 4
			true, -- 5
			true, -- 6
			true, -- 7
			true, -- 8
			true, -- 9
			true, -- 10
		},
		exportFrame = {
			position = {
				"CENTER", -- point
				nil, -- relativeTo
				"CENTER", -- relativePoint
				0, -- xOfs
				0, -- yOfs
			},
			size = {
				700, -- Width
				450, -- Height
			},
			maxLetters = 2000000,
		},
	}
}

function Settings:GetDefaults()
	return defaults
end

---Supported file formats. Used in options table. 
---The lower case name is used for setting the value in addon.db.profile.fileFormat
---The upper case name is displayed in the options menu.
---@return table<string, string> supportedFileFormats
function Settings:GetSupportedFormats()
	local supportedFileFormats = {
		["csv"] = L["CSV"],
		["html"] = L["HTML"],
		["json"] = L["JSON"],
		["xml"] = L["XML"],
		["yaml"] = L["YAML"],
	}

	return supportedFileFormats
end

---@param order number
---@return table
local function GetColumnOptions(order)
	local columnDescriptions = {
		string.format("%s - %s", L["String"], L[ [[Character's name with realm name included (e.g., "Arthas-Silvermoon"). This addon defaults to removing the realm name.]] ]), -- 1
		string.format("%s - %s", L["String"], L["Name of the character's guild rank."]), -- 2
		string.format("%s - %s", L["Number"], L["Index of rank, starting at 0 for Guild Master. This addon defaults to adjusting that to 1."]), -- 3
		string.format("%s - %s", L["Number"], L["Character's level."]), -- 4
		string.format("%s - %s", L["String"], L["Localized class name."]), -- 5
		string.format("%s - %s", L["String"], L["Character's location (last location if offline)."]), -- 6
		string.format("%s - %s", L["String"], L["Character's public note. Empty if you can't view notes."]), -- 7
		string.format("%s - %s", L["String"], L["Character's officer note. Empty if you can't view officer notes."]), -- 8
		string.format("%s - %s", L["Boolean"], L["true: online; false: offline."]), -- 9
		string.format("%s - %s", L["Number"], L["0: none; 1: AFK; 2: busy."]), -- 10
		string.format("%s - %s", L["String"], L["Upper-case, non-localized class name."]), -- 11
		string.format("%s - %s", L["Number"], L["Character's achievement points."]), -- 12
		string.format("%s - %s", L["Number"], L["Where the character ranks in the guild in terms of achievement points."]), -- 13
		string.format("%s - %s", L["Boolean"], L["true: the character is logged in via the mobile app."]), -- 14
		string.format("%s - %s", L["Boolean"], L[ [[true: the character is eligible for "Scroll of Resurrection".]] ]), -- 15
		string.format("%s - %s", L["Number"], L["Standing ID for the character's guild reputation."]), -- 16
		string.format("%s - %s", L["String"], L["Character's Globally Unique Identifier."]), -- 17
		string.format("%s - %s", L["Number"], L["UNIX timestamp. Note that since Blizzard's API doesn't return minutes, this timestamp may be wrong by an hour."]), -- 18
		string.format("%s - %s", L["String"], L["Name of realm."]), -- 19
	}

	local args = {}

	for k, v in ipairs(defaults.profile.columns) do
		args[v.name] = {
			order = k,
			type = "group",
			width = "full",
			name = "",
			guiInline = true,
			args = {
				name = {
					order = 1,
					type = "input",
					name = tostring(k),
					desc = string.format(L[ [[%s Default column name: "%s".]] ], columnDescriptions[k], v.name ),
					get = function() return Addon.db.profile.columns[k].name end,
					set = function(info, value) Addon.db.profile.columns[k].name = value end,
				},
				toggle = {
					order = 2,
					type = "toggle",
					name = "",
					get = function() return Addon.db.profile.columns[k].enabled end,
					set = function(info, value) Addon.db.profile.columns[k].enabled = value end,
				},
			},
		}
	end

	local columns = {
		order = order,
		type = "group",
		name = L["Columns"],
		guiInline = true,
		args = args,
	}

	return columns

end

---@param order number
---@return table
local function GetGlobalOptions(order)
	local global = {
		order = order,
		type = "group",
		name = L["Global"],
		args = {
			title = {
				order = 1,
				width = "full",
				type = "description",
				fontSize = "large",
				name = L["Global"],
			},
			spacer1 = {
				order = 2,
				width = "full",
				type = "description",
				name = "",
			},
			removeRealmName = {
				order = 3,
				type = "toggle",
				width = "full",
				name = L["Remove realm name in column #1"],
				desc = L[ [["Arthas-Silvermoon" will become "Arthas".]] ],
				get = function() return Addon.db.profile.removeRealmFromName end,
				set = function(info, value) Addon.db.profile.removeRealmFromName = value end,
			},
			adjustRankIndex = {
				order = 4,
				type = "toggle",
				width = "full",
				name = L["Adjust rank index in column #3"],
				desc = L["The index normally starts at 0, but this setting adjusts that to 1."] ,
				get = function() return Addon.db.profile.adjustRankIndex end,
				set = function(info, value) Addon.db.profile.adjustRankIndex = value end,
			},
			lastOnlineHours = {
				order = 5,
				type = "toggle",
				width = "full",
				name = L["Use hours since last online in column #18"],
				desc = L["Calculates how many hours have passed since last being online."] ,
				get = function() return Addon.db.profile.lastOnlineHours end,
				set = function(info, value) Addon.db.profile.lastOnlineHours = value end,
			},
			autoExport = {
				order = 6,
				type = "toggle",
				name = L["Automatic export"],
				desc = L["Automatically do an export whenever the guild roster updates and save it in this character's database profile, which is stored within this addon's saved variable. The export frame won't be shown."],
				get = function() return Addon.db.profile.autoExport end,
				set = function(info, value) Addon.db.profile.autoExport = value; Addon.db.profile.autoExportSave = nil end,
			},
			exportFrame = {
				order = 7,
				type = "group",
				guiInline = true,
				name = L["Export frame"],
				args = {
					maxLetters = {
						order = 1,
						type = "input",
						width = "normal",
						name = L["Maximum letters"],
						desc = L["Set the maximum number of letters that the export window can show. Set this to empty or 0 to use Blizzard's default."],
						get = function() return Addon.db.profile.exportFrame.maxLetters > 0 and tostring(Addon.db.profile.exportFrame.maxLetters) or "" end,
						set = function(info, value) value = value == "" and 0 or tonumber(value) or Addon.db.profile.exportFrame.maxLetters if value >= 0 then Addon.db.profile.exportFrame.maxLetters = value end end,
					},
				},
			},
			indentation = {
				order = 8,
				type = "group",
				guiInline = true,
				name = L["Indentation"],
				args = {
					style = {
						order = 1,
						type = "select",
						style = "radio",
						width = "half",
						name = L["Style"],
						desc = L["Select what style to use when exporting HTML, JSON, and XML."],
						values = {["tabs"] = L["Tabs"], ["spaces"] = L["Spaces"]},
						get = function() return Addon.db.profile.indentation.style end,
						set = function(info, value) Addon.db.profile.indentation.style = value end,
					},
					infoText = {
						order = 2,
						type = "description",
						name = L["Spaces are the default indentation style because tabs may be displayed as a strange symbol in the export window. However, copying the tabs works just fine and will be displayed correctly in a text editor."],
					},
					spacer1 = {
						order = 3,
						width = "full",
						type = "description",
						name = "",
					},
					depth = {
						order = 4,
						type = "range",
						min = 0,
						max = 8,
						step = 1,
						width = "normal",
						name = L["Depth"],
						desc = L["Set the depth used when spaces are set as indentation style. A smaller depth shortens the time before the data is displayed."],
						get = function() return Addon.db.profile.indentation.depth end,
						set = function(info, value) Addon.db.profile.indentation.depth = value; end,
						disabled = function() return Addon.db.profile.indentation.style ~= "spaces" end,
					},
				},
			},
		},
	}

	return global
end

---@param order number
---@return table
local function GetCsvOptions(order)
	local csv = {
		order = order,
		type = "group",
		name = L["CSV"],
		-- guiInline = true,
		args = {
			title = {
				order = 1,
				width = "full",
				type = "description",
				fontSize = "large",
				name = L["CSV"],
			},
			spacer1 = {
				order = 2,
				width = "full",
				type = "description",
				name = "",
			},
			header = {
				order = 3,
				type = "toggle",
				width = "full",
				name = L["Header"] ,
				desc = L["Whether or not to have the column names added to top of the CSV output."],
				get = function() return Addon.db.profile.csv.header end,
				set = function(info, value) Addon.db.profile.csv.header = value end,
			},
			enclosure = {
				order = 4,
				type = "input",
				width = "half",
				name = L["Enclosure"],
				desc = L["Text character that is used when enclosing values."],
				get = function() return Addon.db.profile.csv.enclosure end,
				set = function(info, value) if value ~= "" then Addon.db.profile.csv.enclosure = value end end,
			},
			spacer2 = {
				order = 5,
				width = "full",
				type = "description",
				name = "",
			},
			delimiter = {
				order = 6,
				type = "input",
				width = "half",
				name = L["Delimiter"],
				desc = L["Text character that is used when separating values."],
				get = function() return Addon.db.profile.csv.delimiter end,
				set = function(info, value) if value ~= "" then Addon.db.profile.csv.delimiter = value end end,
			},
		},
	}

	return csv
end

---@param order number
---@return table
local function GetHtmlOptions(order)
	local html = {
		order = order,
		type = "group",
		name = L["HTML"],
		-- guiInline = true,
		args = {
			title = {
				order = 1,
				width = "full",
				type = "description",
				fontSize = "large",
				name = L["HTML"],
			},
			spacer1 = {
				order = 2,
				width = "full",
				type = "description",
				name = "",
			},
			tableHeader = {
				order = 3,
				type = "toggle",
				width = "full",
				name = L["Table header"] ,
				desc = L["Whether or not to have the column names added to the table."],
				get = function() return Addon.db.profile.html.tableHeader end,
				set = function(info, value) Addon.db.profile.html.tableHeader = value end,
			},
			style = {
				order = 4,
				type = "select",
				style = "radio",
				width = "half",
				name = L["Style"],
				values = {
					["beautified"] = L["Beautified"],
					["compacted"] = L["Compacted"],
					["minified"] = L["Minified"],
				},
				get = function() return Addon.db.profile.html.style end,
				set = function(info, value) Addon.db.profile.html.style = value end,
			},
			wp = {
				order = 5,
				type = "group",
				name = L["WordPress"],
				guiInline = true,
				args = {
					desc = {
						order = 1,
						type = "description",
						width = "full",
						name = L["Output as a WordPress block (Gutenberg editor)."],
					},
					enabled = {
						order = 2,
						type = "toggle",
						width = "full",
						name = L["Enabled"],
						desc = L["Only use this if you know what you're doing. It requires you to edit the post's code directly. This will also minify the HTML code."],
						get = function() return Addon.db.profile.html.wp.enabled end,
						set = function(info, value) Addon.db.profile.html.wp.enabled = value end,
					},
					stripedStyle = {
						order = 3,
						type = "toggle",
						width = "full",
						name = L["Striped style"],
						get = function() return Addon.db.profile.html.wp.stripedStyle end,
						set = function(info, value) Addon.db.profile.html.wp.stripedStyle = value end,
						-- disabled = function() return not Addon.db.profile.html.wp.enabled end,
					},
					fixedWidth = {
						order = 4,
						type = "toggle",
						width = "full",
						name = L["Fixed-width table cells"],
						get = function() return Addon.db.profile.html.wp.fixedWidth end,
						set = function(info, value) Addon.db.profile.html.wp.fixedWidth = value end,
						-- disabled = function() return not Addon.db.profile.html.wp.enabled end,
					},
				},
			},
		},
	}

	return html
end

---@param order number
---@return table
local function GetJsonOptions(order)
	local json = {
		order = order,
		type = "group",
		name = L["JSON"],
		-- guiInline = true,
		args = {
			title = {
				order = 1,
				width = "full",
				type = "description",
				fontSize = "large",
				name = L["JSON"],
			},
			spacer1 = {
				order = 2,
				width = "full",
				type = "description",
				name = "",
			},
			style = {
				order = 3,
				type = "select",
				style = "radio",
				width = "half",
				name = L["Style"],
				values = {
					["beautified"] = L["Beautified"],
					["compacted"] = L["Compacted"],
					["minified"] = L["Minified"],
				},
				get = function() return Addon.db.profile.json.style end,
				set = function(info, value) Addon.db.profile.json.style = value end,
			},
		},
	}

	return json
end

---@param order number
---@return table
local function GetXmlOptions(order)
	local xml = {
		order = order,
		type = "group",
		name = L["XML"],
		-- guiInline = true,
		args = {
			title = {
				order = 1,
				width = "full",
				type = "description",
				fontSize = "large",
				name = L["XML"],
			},
			spacer1 = {
				order = 2,
				width = "full",
				type = "description",
				name = "",
			},
			delimiter = {
				order = 3,
				type = "input",
				width = "normal",
				name = L["Root element name"],
				get = function() return Addon.db.profile.xml.rootElementName end,
				set = function(info, value) if value ~= "" then Addon.db.profile.xml.rootElementName = value end end,
			},
			spacer2 = {
				order = 4,
				width = "full",
				type = "description",
				name = "",
			},
			enclosure = {
				order = 5,
				type = "input",
				width = "normal",
				name = L["Each record's element name"],
				get = function() return Addon.db.profile.xml.recordElementName end,
				set = function(info, value) if value ~= "" then Addon.db.profile.xml.recordElementName = value end end,
			},
			style = {
				order = 6,
				type = "select",
				style = "radio",
				width = "half",
				name = L["Style"],
				values = {
					["beautified"] = L["Beautified"],
					["compacted"] = L["Compacted"],
					["minified"] = L["Minified"],
				},
				get = function() return Addon.db.profile.xml.style end,
				set = function(info, value) Addon.db.profile.xml.style = value end,
			},
		},
	}

	return xml
end

---@param order number
---@return table
local function GetYamlOptions(order)
	local yaml = {
		order = order,
		type = "group",
		name = L["YAML"],
		-- guiInline = true,
		args = {
			title = {
				order = 1,
				width = "full",
				type = "description",
				fontSize = "large",
				name = L["YAML"],
			},
			spacer1 = {
				order = 2,
				width = "full",
				type = "description",
				name = "",
			},
			quotationMark = {
				order = 3,
				type = "select",
				style = "radio",
				width = "half",
				name = L["Quotation mark"],
				desc = L["What type of quotation mark to use when strings need to be put in quotes."],
				values = {["double"] = L["Double"], ["single"] = L["Single"]},
				get = function() return Addon.db.profile.yaml.quotationMark end,
				set = function(info, value) Addon.db.profile.yaml.quotationMark = value end,
			},
			style = {
				order = 4,
				type = "select",
				style = "radio",
				width = "half",
				name = L["Style"],
				values = {
					["beautified"] = L["Beautified"],
					["compacted"] = L["Compacted"],
					["minified"] = L["Minified"],
				},
				get = function() return Addon.db.profile.yaml.style end,
				set = function(info, value) Addon.db.profile.yaml.style = value end,
			},
		},
	}

	return yaml
end


function Settings:GetOptions()
	local supportedFileFormats = self:GetSupportedFormats()

	options.args = {
		minimapIcon = {
			order = 1,
			type = "toggle",
			width = 1.0225,
			name = L["Minimap icon"],
			desc = L["Show an icon to open the config at the Minimap."],
			get = function() return not Addon.db.profile.minimapIcon.hide end,
			set = function(info, value) Addon.db.profile.minimapIcon.hide = not value; LibDBIcon[value and "Show" or "Hide"](LibDBIcon, addonName) end,
			disabled = function() return not LibDBIcon end,
		},
		fileFormat = {
			order = 2,
			type = "select",
			style = "dropdown",
			width = "half",
			name = "",
			values = supportedFileFormats,
			get = function() return Addon.db.profile.fileFormat end,
			set = function(info, value) Addon.db.profile.fileFormat = value end,
		},
		exportButton = {
			order = 3,
			type = "execute",
			desc = L["WARNING! Large exports may freeze your game for several seconds!"],
			name = L["Export"],
			width = "half",
			func = function() AceConfigDialog:Close(addonName); Addon:ExportData() end,
		},
		settings = {
			order = 4,
			type = "group",
			name = L["Settings"],
			args = {
				columns = GetColumnOptions(1),
				ranks = {
					order = 2,
					type = "group",
					name = L["Ranks"],
					guiInline = true,
					args = {}, -- self:InsertGuildRanksIntoOptions
				},
				global = GetGlobalOptions(3),
				csv = GetCsvOptions(4),
				html = GetHtmlOptions(5),
				json = GetJsonOptions(6),
				xml = GetXmlOptions(7),
				yaml = GetYamlOptions(8),
			},
		},
	}

	return options
end

function Settings:InsertGuildRanksIntoOptions()

	if not options.args then return end

	for k, v in ipairs(defaults.profile.ranks) do
		-- local rankName = GuildControlGetRankName(k)
		local rankName = GuildControlGetRankName(k)

		if rankName == "" then
			rankName = L["Unknown"]
		end

		rankName = string.format("%1$s - %2$s", k, rankName)

		options.args.settings.args.ranks.args["rank"..tostring(k)] = {
			order = k,
			type = "toggle",
			name = rankName,
			get = function() return Addon.db.profile.ranks[k] end,
			set = function(info, value) Addon.db.profile.ranks[k] = value end,
		}
	end
end
