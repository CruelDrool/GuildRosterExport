local addonName = ...
local chatCommand = addonName:lower()

---@class BackdropFrame: BackdropTemplate
---@class BackdropFrame: Frame

---@class addon: AceEvent-3.0
---@class addon: AceConsole-3.0
---@class addon: AceAddon
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)
local LibDataBroker = LibStub("LibDataBroker-1.1", true)
local LibDBIcon = LibStub("LibDBIcon-1.0", true)
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

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
			minify = false,
			wp = {
				enabled = false,
				stripedStyle = false,
				fixedWidth = false,
			},
		},
		json = {
			minify = false,
		},
		xml = {
			rootElementName = "GuildRoster",
			recordElementName = "Character",
			minify = false,
		},
		yaml = {
			quotationMark = "single",
			minify = false,
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

local columnDescriptions = {
	string.format(L["%1$s - %2$s"], L["String"], L[ [[Character's name with realm name included (e.g., "Arthas-Silvermoon"). This addon defaults to removing the realm name.]] ]), -- 1
	string.format(L["%1$s - %2$s"], L["String"], L["Name of the character's guild rank."]), -- 2
	string.format(L["%1$s - %2$s"], L["Number"], L["Index of rank, starting at 0 for Guild Master. This addon defaults to adjusting that to 1."]), -- 3
	string.format(L["%1$s - %2$s"], L["Number"], L["Character's level."]), -- 4
	string.format(L["%1$s - %2$s"], L["String"], L["Localized class name."]), -- 5
	string.format(L["%1$s - %2$s"], L["String"], L["Character's location (last location if offline)."]), -- 6
	string.format(L["%1$s - %2$s"], L["String"], L["Character's public note. Empty if you can't view notes."]), -- 7
	string.format(L["%1$s - %2$s"], L["String"], L["Character's officer note. Empty if you can't view officer notes."]), -- 8
	string.format(L["%1$s - %2$s"], L["Boolean"], L["true: online; false: offline."]), -- 9
	string.format(L["%1$s - %2$s"], L["Number"], L["0: none; 1: AFK; 2: busy."]), -- 10
	string.format(L["%1$s - %2$s"], L["String"], L["Upper-case, non-localized class name."]), -- 11
	string.format(L["%1$s - %2$s"], L["Number"], L["Character's achievement points."]), -- 12
	string.format(L["%1$s - %2$s"], L["Number"], L["Where the character ranks in the guild in terms of achievement points."]), -- 13
	string.format(L["%1$s - %2$s"], L["Boolean"], L["true: the character is logged in via the mobile app."]), -- 14
	string.format(L["%1$s - %2$s"], L["Boolean"], L[ [[true: the character is eligible for "Scroll of Resurrection".]] ]), -- 15
	string.format(L["%1$s - %2$s"], L["Number"], L["Standing ID for the character's guild reputation."]), -- 16
	string.format(L["%1$s - %2$s"], L["String"], L["Character's Globally Unique Identifier."]), -- 17
	string.format(L["%1$s - %2$s"], L["Number"], L["UNIX timestamp. Note that since Blizzard's API doesn't return minutes, this timestamp may be wrong by an hour."]), -- 18
	string.format(L["%1$s - %2$s"], L["String"], L["Name of realm."]), -- 19
}
--[[
Supported file formats.
Used in options table. 
The lower case name is used for setting the value in addon.db.profile.fileFormat
The upper case name is displayed in the options menu.
--]]
local supportedFileFormats = {
	["csv"] = L["CSV"],
	["html"] = L["HTML"],
	["json"] = L["JSON"],
	["xml"] = L["XML"],
	["yaml"] = L["YAML"],
}

local sounds = {
	openOptions = 88, -- "GAMEDIALOGOPEN"
	closeOptions = 624, -- "GAMEGENERICBUTTONPRESS"
	closeExportFrame = SOUNDKIT.GS_TITLE_OPTION_EXIT
}

local options = {
	name = addonName,
	childGroups = "tree",
	type = "group",
	plugins = {},
	args = {
		minimapIcon = {
			order = 1,
			type = "toggle",
			width = 1.0225,
			name = L["Minimap icon"],
			desc = L["Show an icon to open the config at the Minimap."],
			get = function() return not addon.db.profile.minimapIcon.hide end,
			set = function(info, value) addon.db.profile.minimapIcon.hide = not value; LibDBIcon[value and "Show" or "Hide"](LibDBIcon, addonName) end,
			disabled = function() return not LibDBIcon end,
		},
		fileFormat = {
			order = 2,
			type = "select",
			style = "dropdown",
			width = "half",
			name = "",
			values = supportedFileFormats,
			get = function() return addon.db.profile.fileFormat end,
			set = function(info, value) addon.db.profile.fileFormat = value end,
		},
		exportButton = {
			order = 3,
			type = "execute",
			desc = L["WARNING! Large exports may freeze your game for several seconds!"],
			name = L["Export"],
			width = "half",
			func = function() AceConfigDialog:Close(addonName); addon:ExportData() end,
		},
		settings = {
			order = 4,
			type = "group",
			name = L["Settings"],
			args = {
				columns = {
					order = 1,
					type = "group",
					name = L["Columns"],
					guiInline = true,
					args = {},
				},
				ranks = {
					order = 2,
					type = "group",
					name = L["Ranks"],
					guiInline = true,
					args = {},
				},
				global = {
					order = 3,
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
							get = function() return addon.db.profile.removeRealmFromName end,
							set = function(info, value) addon.db.profile.removeRealmFromName = value end,
						},
						adjustRankIndex = {
							order = 4,
							type = "toggle",
							width = "full",
							name = L["Adjust rank index in column #3"],
							desc = L["The index normally starts at 0, but this setting adjusts that to 1."] ,
							get = function() return addon.db.profile.adjustRankIndex end,
							set = function(info, value) addon.db.profile.adjustRankIndex = value end,
						},
						lastOnlineHours = {
							order = 5,
							type = "toggle",
							width = "full",
							name = L["Use hours since last online in column #18"],
							desc = L["Calculates how many hours have passed since last being online."] ,
							get = function() return addon.db.profile.lastOnlineHours end,
							set = function(info, value) addon.db.profile.lastOnlineHours = value end,
						},
						autoExport = {
							order = 6,
							type = "toggle",
							name = L["Auto export"],
							desc = L["Automatically do an export whenever the guild roster updates and save it in this character's database profile, which is stored within this addon's saved variable. The export frame won't be shown."],
							get = function() return addon.db.profile.autoExport end,
							set = function(info, value) addon.db.profile.autoExport = value; addon.db.profile.autoExportSave = nil end,
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
									get = function() return addon.db.profile.exportFrame.maxLetters > 0 and tostring(addon.db.profile.exportFrame.maxLetters) or "" end,
									set = function(info, value) value = value == "" and 0 or tonumber(value) or addon.db.profile.exportFrame.maxLetters if value >= 0 then addon.db.profile.exportFrame.maxLetters = value end end,
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
									get = function() return addon.db.profile.indentation.style end,
									set = function(info, value) addon.db.profile.indentation.style = value end,
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
									get = function() return addon.db.profile.indentation.depth end,
									set = function(info, value) addon.db.profile.indentation.depth = value; end,
									disabled = function() return addon.db.profile.indentation.style ~= "spaces" end,
								},
							},
						},
					},
				},
				csv = {
					order = 4,
					type = "group",
					name = supportedFileFormats["csv"],
					-- guiInline = true,
					args = {
						title = {
							order = 1,
							width = "full",
							type = "description",
							fontSize = "large",
							name = supportedFileFormats["csv"],
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
							get = function() return addon.db.profile.csv.header end,
							set = function(info, value) addon.db.profile.csv.header = value end,
						},
						enclosure = {
							order = 4,
							type = "input",
							width = "half",
							name = L["Enclosure"],
							desc = L["Character that is used when enclosing values."],
							get = function() return addon.db.profile.csv.enclosure end,
							set = function(info, value) if value ~= "" then addon.db.profile.csv.enclosure = value end end,
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
							desc = L["Character that is used when separating values."],
							get = function() return addon.db.profile.csv.delimiter end,
							set = function(info, value) if value ~= "" then addon.db.profile.csv.delimiter = value end end,
						},
					},
				},
				html = {
					order = 5,
					type = "group",
					name = supportedFileFormats["html"],
					-- guiInline = true,
					args = {
						title = {
							order = 1,
							width = "full",
							type = "description",
							fontSize = "large",
							name = supportedFileFormats["html"],
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
							get = function() return addon.db.profile.html.tableHeader end,
							set = function(info, value) addon.db.profile.html.tableHeader = value end,
						},
						minify = {
							order = 4,
							type = "toggle",
							width = "full",
							name = L["Minify"],
							desc = L["To minify means removing unnecessary characters and putting everything on one single line to save space."],
							get = function() return addon.db.profile.html.minify end,
							set = function(info, value) addon.db.profile.html.minify = value end,
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
									get = function() return addon.db.profile.html.wp.enabled end,
									set = function(info, value) addon.db.profile.html.wp.enabled = value end,
								},
								stripedStyle = {
									order = 3,
									type = "toggle",
									width = "full",
									name = L["Striped style"],
									get = function() return addon.db.profile.html.wp.stripedStyle end,
									set = function(info, value) addon.db.profile.html.wp.stripedStyle = value end,
									-- disabled = function() return not addon.db.profile.html.wp.enabled end,
								},
								fixedWidth = {
									order = 4,
									type = "toggle",
									width = "full",
									name = L["Fixed-width table cells"],
									get = function() return addon.db.profile.html.wp.fixedWidth end,
									set = function(info, value) addon.db.profile.html.wp.fixedWidth = value end,
									-- disabled = function() return not addon.db.profile.html.wp.enabled end,
								},
							},
						},
					},
				},
				json = {
					order = 6,
					type = "group",
					name = supportedFileFormats["json"],
					-- guiInline = true,
					args = {
						title = {
							order = 1,
							width = "full",
							type = "description",
							fontSize = "large",
							name = supportedFileFormats["json"],
						},
						spacer1 = {
							order = 2,
							width = "full",
							type = "description",
							name = "",
						},
						minify = {
							order = 3,
							type = "toggle",
							width = "full",
							name = L["Minify"],
							desc = L["To minify means removing unnecessary characters and putting everything on one single line to save space."],
							get = function() return addon.db.profile.json.minify end,
							set = function(info, value) addon.db.profile.json.minify = value end,
						}
					},
				},
				xml = {
					order = 7,
					type = "group",
					name = supportedFileFormats["xml"],
					-- guiInline = true,
					args = {
						title = {
							order = 1,
							width = "full",
							type = "description",
							fontSize = "large",
							name = supportedFileFormats["xml"],
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
							get = function() return addon.db.profile.xml.rootElementName end,
							set = function(info, value) if value ~= "" then addon.db.profile.xml.rootElementName = value end end,
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
							get = function() return addon.db.profile.xml.recordElementName end,
							set = function(info, value) if value ~= "" then addon.db.profile.xml.recordElementName = value end end,
						},
						minify = {
							order = 6,
							type = "toggle",
							width = "full",
							name = L["Minify"],
							desc = L["To minify means removing unnecessary characters and putting everything on one single line to save space."],
							get = function() return addon.db.profile.xml.minify end,
							set = function(info, value) addon.db.profile.xml.minify = value end,
						}
					},
				},
				yaml = {
					order = 8,
					type = "group",
					name = supportedFileFormats["yaml"],
					-- guiInline = true,
					args = {
						title = {
							order = 1,
							width = "full",
							type = "description",
							fontSize = "large",
							name = supportedFileFormats["yaml"],
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
							get = function() return addon.db.profile.yaml.quotationMark end,
							set = function(info, value) addon.db.profile.yaml.quotationMark = value end,
						},
						minify = {
							order = 4,
							type = "toggle",
							width = "full",
							name = L["Minify"],
							desc = L["To minify means removing unnecessary characters and putting everything on one single line to save space."],
							get = function() return addon.db.profile.yaml.minify end,
							set = function(info, value) addon.db.profile.yaml.minify = value end,
						}
					},
				},
			},
		},
	},
}

for k, v in ipairs(defaults.profile.columns) do
	options.args.settings.args.columns.args[v.name] = {
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
				desc = string.format(L[ [[%1$s Default column name: "%2$s".]] ], columnDescriptions[k], v.name ),
				get = function() return addon.db.profile.columns[k].name end,
				set = function(info, value) addon.db.profile.columns[k].name = value end,
			},
			toggle = {
				order = 2,
				type = "toggle",
				name = "",
				get = function() return addon.db.profile.columns[k].enabled end,
				set = function(info, value) addon.db.profile.columns[k].enabled = value end,
			},
		},
	}
end

local function insertGuildRanksIntoOptions()
	for k, v in ipairs(defaults.profile.ranks) do
		local rankName = GuildControlGetRankName(k)

		if rankName == "" then
			rankName = L["Unknown"]
		end

		rankName = string.format("%1$s - %2$s", k, rankName)

		options.args.settings.args.ranks.args["rank"..tostring(k)] = {
			order = k,
			type = "toggle",
			name = rankName,
			get = function() return addon.db.profile.ranks[k] end,
			set = function(info, value) addon.db.profile.ranks[k] = value end,
		}
	end
end

local function CreateExportFrame()
	-- Main Frame

	---@class BackdropFrame
	local f = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	f:Hide()
	f:ClearAllPoints()
	f:SetPoint(unpack(addon.db.profile.exportFrame.position))
	f:SetSize(unpack(addon.db.profile.exportFrame.size))
	f:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileEdge = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 5, right = 5, top = 5, bottom = 5 },
	})
	f:SetBackdropColor(0,0,0,0.75)
	f:SetMovable(true)
	f:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			self:StartMoving()
		end
	end)
	f:SetScript("OnMouseUp", function(self, button)
		self:StopMovingOrSizing()
		addon.db.profile.exportFrame.position = {self:GetPoint()}
	end)

	-- Buttons
	local closeButton = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
	closeButton:SetPoint("BOTTOM", f, "BOTTOM", -75, 7.5)
	closeButton:SetScript("OnClick", function(self, button) f.text:SetText(""); f:Hide(); PlaySound(sounds.closeExportFrame) end)
	closeButton:SetText(L["Close"])

	local closeAndReturnButton = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
	closeAndReturnButton:SetPoint("BOTTOM", f, "BOTTOM", 75, 7.5)
	closeAndReturnButton:SetScript("OnClick", function(self, button) f.text:SetText(""); addon:ToggleOptions() end)
	closeAndReturnButton:SetText(L["Close & Return"])

	-- Scroll frame
	local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
	sf:SetPoint("TOP", 0, -19.5)
	sf:SetPoint("LEFT", 18.5, 0)
	sf:SetPoint("RIGHT", -42, 0)
	sf:SetPoint("BOTTOM", closeButton, "TOP", 0, 2.5)

	-- Edit box
	local eb = CreateFrame("EditBox", nil, sf)
	eb:SetSize(sf:GetSize())
	eb:SetMultiLine(true)
	eb:SetAutoFocus(true)
	eb:SetFontObject("ChatFontNormal")
	eb:SetScript("OnEscapePressed", function() f.text:SetText(""); f:Hide() end)
	sf:SetScrollChild(eb)
	f.text = eb

	-- Resizing
	f:SetResizable(true)

	-- :SetMinResize removed in patch 10.0.0.
	if f.SetResizeBounds then
		f:SetResizeBounds(340, 110)
	else
		-- Backwards compatibility with any client not using the new method yet.
		---@diagnostic disable-next-line: undefined-field
		f:SetMinResize(340, 110)
	end

	local rb = CreateFrame("Button", nil, f)
	rb:SetPoint("BOTTOMRIGHT", -4, 4)
	rb:SetSize(16, 16)

	rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

	rb:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			f:StartSizing("BOTTOMRIGHT")
			self:GetHighlightTexture():Hide() -- more noticeable
		end
	end)

	rb:SetScript("OnMouseUp", function(self, button)
		f:StopMovingOrSizing()
		self:GetHighlightTexture():Show()
		eb:SetWidth(sf:GetWidth())
		addon.db.profile.exportFrame.size = {f:GetSize()}
	end)

	return f
end

function addon:OnInitialize()
	self.db = AceDB:New(addonName.."DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateConfigs")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateConfigs")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateConfigs")

	self:ConvertOldConfig()

	self:SetupOptions()

	self.exportFrame = CreateExportFrame()

	self:RegisterChatCommand(chatCommand, "ChatCommand")

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")

	if LibDataBroker then
		local LDBObj = LibDataBroker:NewDataObject(addonName, {
			type = "launcher",
			icon = "Interface\\AddOns\\"..addonName.."\\icon",
			OnClick = function(_, mouseButton)
				if mouseButton == "LeftButton" or mouseButton == "RightButton" then
					self:ToggleOptions()
				end
			end,
			OnTooltipShow = function(tooltip)
				if not (tooltip and tooltip.AddLine) then return end
				tooltip:AddDoubleLine(addonName, C_AddOns.GetAddOnMetadata(addonName, "Version"))
				tooltip:AddLine(string.format(L["%sClick%s to toggle options."], "|cffffff00", "|r"))
				tooltip:AddLine(string.format(L["Or use /%s"], chatCommand))
			end,
		})

		if LibDBIcon then
			LibDBIcon:Register(addonName, LDBObj, self.db.profile.minimapIcon)
		end
	end
end

function addon:PLAYER_ENTERING_WORLD()
	if self.db.profile.autoExport then
		-- Request updated guild roster data from the server. This will trigger "GUILD_ROSTER_UPDATE". 
		C_GuildInfo.GuildRoster()
	end
end

function addon:GUILD_ROSTER_UPDATE()
	if self.db.profile.autoExport then
		self:ExportData(nil, true)
	end
end

function addon:ConvertOldConfig()
	self.db.profile.exportFrame.maxLetters = self.db.profile.maxLetters or self.db.profile.exportFrame.maxLetters
	self.db.profile.maxLetters = nil

	self.db.profile.indentation.style = self.db.profile.indentationStyle or self.db.profile.indentation.style
	self.db.profile.indentation.depth = self.db.profile.spacesIndentationDepth or self.db.profile.indentation.depth
	self.db.profile.indentationStyle = nil
	self.db.profile.spacesIndentationDepth = nil

	self.db.profile.csv.delimiter = self.db.profile.csvDelimiter or self.db.profile.csv.delimiter
	self.db.profile.csv.enclosure = self.db.profile.csvEnclosure or self.db.profile.csv.enclosure
	self.db.profile.csvDelimiter = nil
	self.db.profile.csvEnclosure = nil

	self.db.profile.json.minify = self.db.profile.jsonMinify or self.db.profile.json.minify
	self.db.profile.jsonMinify = nil

	self.db.profile.xml.rootElementName = self.db.profile.xmlRootElementName or self.db.profile.xml.rootElementName
	self.db.profile.xml.recordElementName = self.db.profile.xmlRecordElementName or self.db.profile.xml.recordElementName
	self.db.profile.xml.minify =  self.db.profile.xmlMinify or self.db.profile.xml.minify
	self.db.profile.xmlRootElementName = nil
	self.db.profile.xmlRecordElementName = nil
	self.db.profile.xmlMinify = nil

	self.db.profile.yaml.minify = self.db.profile.yamlMinify or self.db.profile.yaml.minify
	self.db.profile.yaml.quotationMark = self.db.profile.yamlQuotationMark or self.db.profile.yaml.quotationMark
	self.db.profile.yamlMinify = nil
	self.db.profile.yamlQuotationMark = nil
end

function addon:UpdateConfigs()
	self:ConvertOldConfig()

	-- Reset the auto export save. Don't want that when changing profile.
	self.db.profile.autoExportSave = nil

	if LibDataBroker and LibDBIcon then
		LibDBIcon:Refresh(addonName, self.db.profile.minimapIcon)
	end

	AceConfigRegistry:NotifyChange(addonName)

	self.exportFrame:ClearAllPoints()
	self.exportFrame:SetPoint(unpack(self.db.profile.exportFrame.position))
	self.exportFrame:SetSize(unpack(self.db.profile.exportFrame.size))
end

function addon:SetupOptions()
	options.plugins.profiles = { profiles = AceDBOptions:GetOptionsTable(self.db) }
	AceConfigRegistry:RegisterOptionsTable(addonName, options)
	-- AceConfigDialog:AddToBlizOptions(addonName, addonName)
end

function addon:ToggleOptions()
	if self.exportFrame:IsShown() then
		self.exportFrame:Hide()
	end
	if AceConfigDialog.OpenFrames[addonName] then
		PlaySound(sounds.closeOptions)
		AceConfigDialog:Close(addonName)
	else
		insertGuildRanksIntoOptions()
		PlaySound(sounds.openOptions)
		AceConfigDialog:Open(addonName)
	end
end

function addon:SystemMessageInPrimary(msg)
	local color = ChatTypeInfo["SYSTEM"]
	DEFAULT_CHAT_FRAME:AddMessage(msg, color.r, color.g, color.b)
end

function addon:ChatCommand(args)
	local arg1, arg2 = self:GetArgs(args, 2)

	arg1 = arg1 and arg1:lower()
	arg2 = arg2 and arg2:lower()

	if arg1 == "help" then
		self:SystemMessageInPrimary(string.format("/%s - %s.", chatCommand, L["Toggle options"]))
		self:SystemMessageInPrimary(string.format("/%s help - %s.",  chatCommand, L["Print this help"]))
		self:SystemMessageInPrimary(string.format("/%s export [%s] - %s.",  chatCommand, L["file format"],  L["Do an export"]))
		self:SystemMessageInPrimary(L["Supported file formats:"])

		local tmp = {}

		for k in pairs(supportedFileFormats) do
			table.insert(tmp, k)
		end

		table.sort(tmp)

		for _,fileFormat in ipairs(tmp) do
			self:SystemMessageInPrimary(string.format(" - %s", fileFormat))
		end
	elseif arg1 == "export" then
		AceConfigDialog:Close(addonName);
		if supportedFileFormats[arg2] then
			self:ExportData(arg2)
		else
			self:ExportData()
		end
	else
		self:ToggleOptions()
	end
end

function addon:ExportData(fileFormat, saveToDB)
	fileFormat = fileFormat or self.db.profile.fileFormat
	local ranks = self.db.profile.ranks
	local columns = self.db.profile.columns
	local removeRealmFromName = self.db.profile.removeRealmFromName
	local adjustRankIndex = self.db.profile.adjustRankIndex
	local lastOnlineHours = self.db.profile.lastOnlineHours
	local roster = {}
	local serverTimeInfo = date("*t",GetServerTime())
	local currentTime = time({day=serverTimeInfo.day, month=serverTimeInfo.month, year=serverTimeInfo.year, hour=serverTimeInfo.hour})

	for i=1, GetNumGuildMembers() do
		local row = { GetGuildRosterInfo(i) }

		if #row > 0 then
			local lastOnline = currentTime
			local yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i)

			if hoursOffline then
				local dateInfo = date("*t",currentTime-(hoursOffline * 3600 + daysOffline * 86400))
				local year = dateInfo.year - yearsOffline
				local month = dateInfo.month - monthsOffline
				local day = dateInfo.day

				if month <= 0 then
					year = year - 1
					month = month + 12
				end

				lastOnline = time({day=day,month=month,year=year,hour=dateInfo.hour})
			end

			lastOnline = lastOnlineHours and ((currentTime-lastOnline)/3600) or lastOnline

			table.insert(row, lastOnline)

			local realmName = (row[1] and type(row[1]) == "string") and row[1]:match("-([^-]+)") or ""

			table.insert(row, realmName)

			local rankIndex = row[3] + 1
			if ranks[rankIndex] then
				for k, v in pairs(row) do
					if not columns[k].enabled then
						row[k] = nil
					else
						if k == 1 then
							if removeRealmFromName then
								row[k] = row[k]:gsub("-.+","")
							else
								-- Cross realm names have, for some reason, their realm name repeated. Very weird. This fixes that.
								row[k] = row[k]:gsub("^([^-]+)-([^-]+)-.+", "%1-%2")
							end
						end

						if adjustRankIndex and k == 3 then
							row[k] = rankIndex
						end
					end
				end
				table.insert(roster, row)
			end
		end
	end

	--[[
	Doing the function call to the export function via a table key, so we can use the value of "fileFormat" to determine which function to use.
	This lets us easily add more export functions. All that is needed is to add the file format to "supportedFileFormats".
	]]--
	if saveToDB then
		self.db.profile.autoExportSave = self[fileFormat](self, roster)
	else
		self.exportFrame.text:SetMaxLetters(self.db.profile.exportFrame.maxLetters)
		self.exportFrame.text:SetText("") -- Clear the edit box else SetMaxLetters is ignored if the edit box has been filled once before
		-- Set the text in the export window's EditBox and display it.
		self.exportFrame.text:SetText(self[fileFormat](self, roster))
		self.exportFrame.text:HighlightText()
		self.exportFrame:Show()
	end
end

local function getTabSub(n)
	local str = ""

	for i=1, n do
		str = str .. " "
	end

	return str
end

function addon:csv(data)
	local enclosure = self.db.profile.csv.enclosure
	local delimiter = self.db.profile.csv.delimiter
	local header = self.db.profile.csv.header
	local columns = self.db.profile.columns
	local output = ""

	if header then
		local headerData = {}
		for _, v in ipairs(columns) do
			if v.enabled then
				table.insert(headerData, v.name)
			end
		end

		data[0] = headerData
	end

	for i=header and 0 or 1, #data do
		local line = ""
		for _, c in pairs(data[i]) do
			if (type(c) == "string") then
				c =  c:gsub(enclosure, enclosure..enclosure)
			end

			if type(c) == "boolean" then
				c = tostring(c)
			end

			line = string.format("%1$s%2$s%4$s%2$s%3$s", line, enclosure, delimiter, c)
		end

		-- Add the line to the output. The last delimiter character is removed.
		output = string.format("%1$s%2$s\n", output, line:sub(1,-2))
	end

	return output:sub(1,-2)
end

function addon:html(data)
	local columns = self.db.profile.columns
	local indentationStyle = self.db.profile.indentation.style
	local indentationDepth = self.db.profile.indentation.depth
	local header = self.db.profile.html.tableHeader
	local minify = self.db.profile.html.minify
	local wp = self.db.profile.html.wp.enabled
	local wpStripedStyle = self.db.profile.html.wp.stripedStyle
	local wpFixedWidth = self.db.profile.html.wp.fixedWidth
	local thead = ""
	local tbody = ""
	local output = ""

	if header then
		for _, v in ipairs(columns) do
			if v.enabled then
				thead = string.format("%s\t\t\t<th>%s</th>\n", thead, v.name)
			end
		end
		thead = string.format("\t<thead>\n\t\t<tr>\n%s\t\t</tr>\n\t</thead>\n",thead)
	end

	for _, v in pairs(data) do
		local cells = ""

		for _, c in pairs(v) do
			if type(c) == "string" then
				c =  c:gsub("&", '&amp;')
				c =  c:gsub("<", '&lt;')
				c =  c:gsub(">", '&gt;')
			end

			if type(c) == "boolean" then
				c = tostring(c)
			end

			cells = string.format("%s\t\t\t<td>%s</td>\n", cells, c)
		end

		-- Add the block of cells to the body as a row.
		tbody = string.format("%s\n\t\t<tr>\n%s\t\t</tr>", tbody, cells)
	end

	output = string.format('<table%s>\n%s\t<tbody>%s\n\t</tbody>\n</table>', (wp and wpFixedWidth) and  ' class="has-fixed-layout"' or "", thead, tbody)

	if minify or wp then
		output = output:gsub("\t", "")
		output = output:gsub("\n", "")
	elseif indentationStyle == "spaces" then
		local tabSub = getTabSub(indentationDepth)
		output = output:gsub("\t", tabSub)
	end

	if wp then
		local attributes = ""

		if wpStripedStyle or wpFixedWidth then
			local tmp = {}

			table.insert(tmp, wpFixedWidth and '"hasFixedLayout":true' or nil)
			table.insert(tmp, wpStripedStyle and '"className":"is-style-stripes"' or nil)

			attributes = string.format(" {%s}", table.concat(tmp, ","))
		end

		output = string.format('<!-- wp:table%s -->\n<figure class="wp-block-table%s">%s</figure>\n<!-- /wp:table -->', attributes, wpStripedStyle and " is-style-stripes" or "", output)
	end

	return output
end

function addon:json(data)
	local columns = self.db.profile.columns
	local indentationStyle = self.db.profile.indentation.style
	local indentationDepth = self.db.profile.indentation.depth
	local minify = self.db.profile.json.minify
	local output = ""

	for _, v in pairs(data) do
		local lines = ""

		for k, c in pairs(v) do
			if (type(c) == "string") then
				c =  c:gsub('\\', '\\\\')
				c =  c:gsub('"', '\\"')
				c = string.format('"%s"',c)
			end

			if type(c) == "boolean" then
				c = tostring(c)
			end

			if minify then
				lines = string.format("%1$s\"%2$s\":%3$s,", lines, columns[k].name, c)
			else
				lines = string.format("%1$s\n\t\t\"%2$s\": %3$s,", lines, columns[k].name, c)
			end
		end

		-- Add the block of lines to the output. Trailing comma is removed.
		output = string.format("%1$s\n\t{%2$s\n\t},",output, lines:sub(1,-2))
	end

	-- Format the ouput. Trailing \n (newline) is removed.
	output = string.format("[%1$s\n]", output:sub(1,-2))

	if minify then
		output = output:gsub("\t", "")
		output = output:gsub("\n", "")
	elseif indentationStyle == "spaces" then
		local tabSub = getTabSub(indentationDepth)
		output = output:gsub("\t", tabSub)
	end

	return output
end

function addon:xml(data)
	local columns = self.db.profile.columns
	local indentationStyle = self.db.profile.indentation.style
	local indentationDepth = self.db.profile.indentation.depth
	local rootElementName = self.db.profile.xml.rootElementName
	local recordElementName = self.db.profile.xml.recordElementName
	local minify = self.db.profile.xml.minify
	local output = ""

	for _, v in pairs(data) do
		local lines = ""

		for k, c in pairs(v) do
			if type(c) == "string" then
				c =  c:gsub("&", '&amp;')
				c =  c:gsub("<", '&lt;')
				c =  c:gsub(">", '&gt;')
			end

			if type(c) == "boolean" then
				c = tostring(c)
			end

			lines = string.format("%1$s\t\t<%2$s>%3$s</%2$s>\n", lines, columns[k].name, c)
		end

		-- Add the block of lines to the output.
		output = string.format("%1$s\n\t<%2$s>\n%3$s\t</%2$s>", output, recordElementName, lines)
	end

	output = string.format("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<%1$s>%2$s\n</%1$s>", rootElementName, output)

	if minify then
		output = output:gsub("\t", "")
		output = output:gsub("\n", "")
	elseif indentationStyle == "spaces" then
		local tabSub = getTabSub(indentationDepth)
		output = output:gsub("\t", tabSub)
	end

	return output
end

function addon:yaml(data)
	local columns = self.db.profile.columns
	local quotationMark = self.db.profile.yaml.quotationMark
	local minify = self.db.profile.yaml.minify
	local output = ""
	local specialCharacters = {
		--[[
		The position where these characters are found determines whether or not the string should be put in quotes.
		The whole purpose of this is to reduce the number of quotation marks used in the final output. It would be easier to just put every single string in quotes...

		This list is based upon the YAML specifications and various YAML parsers/validators.
		]]--

		["^$"] = "first", -- Empty string. Put those in quotes too.
		["^%s"] = "first", -- Space character at the at the start. This is to preserve the entire string since we're not trimming them. Mostly for notes set in the roster.
		["%s$"] = "any", -- Space character at the end.

		["-"] = "first", -- Block sequence entry indicator.
		--["^-$"] = "first", -- A single hyphen only.
		--["-%s"] = "first", -- A single hyphen character at the start becomes a problem if it's followed by a space character. If something else follows, even another hyphen, everything is fine.

		["?"] = minify and "any" or "first", -- Mapping key indicator. When minifying, yamllint.com craps out on any question marks that aren't inside quotes. The other validators/parsers do not.

		[":"] = "any", -- Mapping value indicator.
		-- [":"] = minify and "any" or nil, -- Yamllint.com craps out on any colon not inside quotes when minifying.
		-- ["^:"] = minify and nil or "first", -- Usually a colon at the start isn't a problem (as long it's not followed by a space). However, yamllint.com replaces the colon with the text "!ruby/symbol", though...
		-- [":$"] = minify and nil or "any", -- Colon character at the end.
		-- ["%S+%s*:%s+"] = minify and nil or "any", -- Non-space characters (usually words) followed by zero, or more, space character(s) and then a colon followed by 1, or more, space character(s).

		[","] =  "any", -- End flow collection entry indicator.
		["%["] ="any", -- Start flow sequence indicator.
		["%]"] = "any", -- End flow sequence indicator.
		["{"] = "any", -- Start flow mapping indicator.
		["}"] = "any", -- End flow mapping indicator.
		["#"] = "any", -- Comment indicator.
		["&"] = "first", -- Anchor node indicator.
		["*"] = "first", -- Alias node indicator.
		["!"] = "first", -- Tag node indicator.
		["|"] = "first", -- "Literal" block scalar indicator.
		[">"] = "first", -- "Folded" block scalar indicator.
		["%%"] = "first", -- Directive line indicator.
		["@"] = "first", -- Reserved for future use.
		["`"] = "first", -- Reserved for future use.
		["'"] = "first", -- Single-quoted flow scalar.
		['"'] = "first", -- Double-quoted flow scalar.
		["^true$"] = "first", -- Boolean.
		["^false$"] = "first", -- Boolean.
		["^yes$"] = "first", -- Boolean. Equal to "true". YAML 1.1
		["^no$"] = "first", -- Boolean. Equal to "false". YAML 1.1
		["^y$"] = "first", -- Boolean. Equal to "true". YAML 1.1
		["^n$"] = "first", -- Boolean. Equal to "false". YAML 1.1
		["^on$"] = "first", -- Boolean. Equal to "true". YAML 1.1
		["^off$"] = "first", -- Boolean. Equal to "false". YAML 1.1
	}

	local findSpecialCharacters = function(str)
		local found = false

		for k,v in pairs(specialCharacters) do
			local pos = str:lower():find(k)
			if pos and ((pos == 1 and v == "first") or (pos >= 1 and v == "any")) then
				found = true;
				break
			end
		end

		return found
	end

	for _, v in pairs(data) do
		local lines = ""

		for k, c in pairs(v) do
			if type(c) == "string" and findSpecialCharacters(c) then
				if quotationMark == "double" then
					c =  c:gsub('\\', '\\\\')
					c =  c:gsub('"', '\\"')
					c = string.format('"%s"', c)
				else
					c = c:gsub("'", "''")
					c = string.format("'%s'", c)
				end
			end

			if type(c) == "boolean" then
				c = tostring(c)
			end

			if minify then
				lines = string.format("%1$s%2$s: %3$s,", lines, columns[k].name, c)
			else
				lines = string.format("%1$s %2$s: %3$s\n", lines, columns[k].name, c)
			end

		end

		-- Add the block of lines to the output.
		if minify then
			output = string.format("%1$s{%2$s},", output, lines:sub(1,-2))
		else
			output = string.format("%1$s-\n%2$s", output, lines)
		end
	end

	-- The trailing \n (newline) or comma is removed.
	output = output:sub(1,-2)

	if minify then
		output = string.format("[%s]", output)
	end

	return output
end
