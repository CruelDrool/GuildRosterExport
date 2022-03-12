local addonName = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)
-- _G[addonName] = addon -- uncomment for debugging purposes

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

local defaults = {
	profile = {
		minimapIcon = {},
		fileFormat = "csv";
		removeRealmFromName = true,
		adjustRankIndex = true,
		maxLetters = 2000000,
		indentationStyle = "spaces",
		spacesIndentationDepth = 4,
		csvDelimiter = ',',
		csvEnclosure = '"',
		xmlRootElementName = "GuildRoster",
		xmlRecordElementName = "Character",
		xmlMinify = false,
		jsonMinify = false,
		yamlMinify = false,
		columns = {
			[1] = {enabled = true, name = "name"},
			[2] = {enabled = true, name = "rankName"},
			[3] = {enabled = true, name = "rankIndex"},
			[4] = {enabled = true, name = "level"},
			[5] = {enabled = true, name = "class"},
			[6] = {enabled = false, name = "zone"},
			[7] = {enabled = false, name = "note"},
			[8] = {enabled = false, name = "officerNote"},
			[9] = {enabled = false, name = "isOnline"},
			[10] = {enabled = false, name = "status"},
			[11] = {enabled = false, name = "classFileName"},
			[12] = {enabled = false, name = "achievementPoints"},
			[13] = {enabled = false, name = "achievementRank"},
			[14] = {enabled = false, name = "isMobile"},
			[15] = {enabled = false, name = "isSoREligible"},
			[16] = {enabled = false, name = "repStandingID"},
			[17] = {enabled = false, name = "GUID"},
		},
		ranks = {
			[1] = true,
			[2] = true,
			[3] = true,
			[4] = true,
			[5] = true,
			[6] = true,
			[7] = true,
			[8] = true,
			[9] = true,
			[10] = true,
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
		},
	}
}

local columnDescriptions = {
	[1] = L["String - Name of character with realm (e.g. \"Arthas-Silvermoon\"). This addon defaults to removing the realm name."],
	[2] = L["String - Name of character's guild rank."],
	[3] = L["Number - Index of rank, starting at 0 for Guild Master. This addon defaults to adjusting that to 1."],
	[4] = L["Number - Character's level."],
	[5] = L["String - Localised class name."],
	[6] = L["String - Character's location (last location if offline)."],
	[7] = L["String - Character's public note. Empty if you can't view notes."],
	[8] = L["String - Character's officer note. Empty if you can't view officer notes."],
	[9] = L["Boolean - true: online; false: offline."],
	[10] = L["Number - 0: none; 1: AFK; 2: Busy."],
	[11] = L["String - Upper-case, localisation-independent class name."],
	[12] = L["Number - Character's achievement points."],
	[13] = L["Number - Where the character ranks in guild in terms of achievement points."],
	[14] = L["Boolean - true: player logged in via mobile app."],
	[15] = L["Boolean - Scroll of Resurrection eligible."],
	[16] = L["Number - Standing ID for character's guild reputation"],
	[17] = L["String - Character's Globally Unique Identifier."],
}
--[[
Supported file formats.
Used in options table. 
The lower case name is used for setting the value in addon.db.profile.fileFormat
The upper case name is displayed in the options menu.
--]]
local supportedFileFormats = {
	["csv"] = L["CSV"],
	["json"] = L["JSON"],
	["xml"] = L["XML"],
	["yaml"] = L["YAML"],
}

local openOptionsSound = 88 -- "GAMEDIALOGOPEN"
local closeOptionsSound = 624 -- "GAMEGENERICBUTTONPRESS"
local closeExportFrame = SOUNDKIT.GS_TITLE_OPTION_EXIT

addon.options = {
	childGroups = "tree",
	type = "group",
	plugins = {},
	args = {
		minimapIcon = {
			order = 1,
			type = "toggle",
			name = L["Minimap Icon"],
			desc = L["Show a Icon to open the config at the Minimap"],
			get = function() return not addon.db.profile.minimapIcon.hide end,
			set = function(info, value) addon.db.profile.minimapIcon.hide = not value; LDBIcon[value and "Show" or "Hide"](LDBIcon, addonName) end,
			disabled = function() return not LDBIcon end,
			-- disabled = function() return not LDBTitan end,
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
			func = function() LibStub("AceConfigDialog-3.0"):Close(addonName); addon:ExportData() end,
		},
		settings = {
			order = 2,
			type = "group",
			name = L["Settings"],
			args = {

				columns = {
					order = 2,
					type = "group",
					name = L["Columns"],
					guiInline = true,
					args = {},
				},
				ranks = {
					order = 3,
					type = "group",
					name = L["Ranks"],
					guiInline = true,
					args = {},
				},
				global = {
					order = 4,
					type = "group",
					name = L["Global"],
					-- guiInline = true,
					args = {
						removeRealmName = {
							order = 1,
							type = "toggle",
							name = L["Remove realm name"],
							width = "full",
							desc = L["With this setting enabled, the realm name will be removed from character names in column #1."],
							get = function() return addon.db.profile.removeRealmFromName end,
							set = function(info, value) addon.db.profile.removeRealmFromName = value end,
						},
						adjustRankIndex = {
							order = 2,
							type = "toggle",
							width = "full",
							name = string.format(L["Adjust %s"], "rankIndex"),
							desc = string.format(L["%s normally starts at 0, but this setting adjust that to 1."], "rankIndex"),
							get = function() return addon.db.profile.adjustRankIndex end,
							set = function(info, value) addon.db.profile.adjustRankIndex = value end,
						},
						maxLetters = {
							order = 3,
							type = "input",
							width = "normal",
							name = L["Maximum letters"],
							desc = L["Set the maximum number of letters that the export window can show. Set to empty or 0 to use Blizzard's default."],
							get = function() return addon.db.profile.maxLetters > 0 and tostring(addon.db.profile.maxLetters) or "" end,
							set = function(info, value) value = value == "" and 0 or tonumber(value) or addon.db.profile.maxLetters if value >= 0 then addon.db.profile.maxLetters = value end end,
						},
						spacer1 = {
							order = 4,
							width = "full",
							type = "description",
							name = "",
						},
						indentationStyle = {
							order = 5,
							type = "select",
							style = "dropdown",
							name = L["Indentation style"],
							desc = L["Set indentation style. Used when exporting JSON and XML."],
							values = {["tabs"] = L["Tabs"], ["spaces"] = L["Spaces"]},
							get = function() return addon.db.profile.indentationStyle end,
							set = function(info, value) addon.db.profile.indentationStyle = value end,
						},
						spacer2 = {
							order = 6,
							width = "full",
							type = "description",
							name = "",
						},
						indentationInfoText = {
							order = 7,
							type = "description",
							name = L["Spaces are the default indentation style because tabs may be displayed as a strange symbol in the export window. However, copying the tabs work just fine and will be displayed correctly in a text editor."],
						},
						spacesIndentationDepth = {
							order = 8,
							type = "range",
							min = 0,
							max = 8,
							step = 1,
							width = "normal",
							name = L["Indentation depth (spaces)"],
							desc = L["Set the depth used when spaces are set as indentation style. Smaller depth shortens the time before the data is displayed."],
							get = function() return addon.db.profile.spacesIndentationDepth end,
							set = function(info, value) addon.db.profile.spacesIndentationDepth = value; end,
						},
					},
				},
				csv = {
					order = 5,
					type = "group",
					name = supportedFileFormats["csv"],
					-- guiInline = true,
					args = {
						delimiter = {
							order = 1,
							type = "input",
							width = "half",
							name = L["Delimiter"],
							get = function() return addon.db.profile.csvDelimiter end,
							set = function(info, value) if value ~= "" then addon.db.profile.csvDelimiter = value end end,
						},
						spacer1 = {
							order = 2,
							width = "full",
							type = "description",
							name = "",
						},
						enclosure = {
							order = 3,
							type = "input",
							width = "half",
							name = L["Enclosure"],
							get = function() return addon.db.profile.csvEnclosure end,
							set = function(info, value) if value ~= "" then addon.db.profile.csvEnclosure = value end end,
						},
					},
				},
				json = {
					order = 6,
					type = "group",
					name = supportedFileFormats["json"],
					-- guiInline = true,
					args = {
						minify = {
							order = 1,
							type = "toggle",
							width = "full",
							name = L["Minify"],
							desc = "",
							get = function() return addon.db.profile.jsonMinify end,
							set = function(info, value) addon.db.profile.jsonMinify = value end,
						}
					},
				},
				xml = {
					order = 7,
					type = "group",
					name = supportedFileFormats["xml"],
					-- guiInline = true,
					args = {
						delimiter = {
							order = 1,
							type = "input",
							width = "normal",
							name = L["Root element name"],
							get = function() return addon.db.profile.xmlRootElementName end,
							set = function(info, value) if value ~= "" then addon.db.profile.xmlRootElementName = value end end,
						},
						spacer1 = {
							order = 2,
							width = "full",
							type = "description",
							name = "",
						},
						enclosure = {
							order = 3,
							type = "input",
							width = "normal",
							name = L["Each record's element name"],
							get = function() return addon.db.profile.xmlRecordElementName end,
							set = function(info, value) if value ~= "" then addon.db.profile.xmlRecordElementName = value end end,
						},
						minify = {
							order = 4,
							type = "toggle",
							width = "full",
							name = L["Minify"],
							desc = "",
							get = function() return addon.db.profile.xmlMinify end,
							set = function(info, value) addon.db.profile.xmlMinify = value end,
						}
					},
				},
				yaml = {
					order = 8,
					type = "group",
					name = supportedFileFormats["yaml"],
					-- guiInline = true,
					args = {
						minify = {
							order = 1,
							type = "toggle",
							width = "full",
							name = L["Minify"],
							desc = "",
							get = function() return addon.db.profile.yamlMinify end,
							set = function(info, value) addon.db.profile.yamlMinify = value end,
						}
					},
				},
			},
		},
	},
}

for k, v in ipairs(defaults.profile.columns) do
	addon.options.args.settings.args.columns.args[v.name] = {
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
				desc = string.format(L["%1$s Default column name: \"%2$s\"."], columnDescriptions[k], v.name ),
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

		addon.options.args.settings.args.ranks.args["rank"..tostring(k)] = {
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
	closeButton:SetScript("OnClick", function(self, button) f:Hide(); PlaySound(closeExportFrame) end)
	closeButton:SetText(L["Close"])

	local closeAndReturnButton = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
	closeAndReturnButton:SetPoint("BOTTOM", f, "BOTTOM", 75, 7.5)
	closeAndReturnButton:SetScript("OnClick", function(self, button) f:Hide(); PlaySound(openOptionsSound); LibStub("AceConfigDialog-3.0"):Open(addonName) end)
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
	eb:SetScript("OnEscapePressed", function() f:Hide() end)
	sf:SetScrollChild(eb)
	f.text = eb

	-- Resizing
	f:SetResizable(true)
	f:SetMinResize(340, 110)
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
	self.db = LibStub("AceDB-3.0"):New(addonName.."DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateConfigs")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateConfigs")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateConfigs")

	self:SetupOptions()

	self.exportFrame = CreateExportFrame()

	self:RegisterChatCommand(string.lower(addonName), function() self.exportFrame:Hide(); PlaySound(openOptionsSound); LibStub("AceConfigDialog-3.0"):Open(addonName) end)

	if LDB then
		self.LDBObj = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
			type = "launcher",
			OnClick = function(_, msg)
				if msg == "LeftButton" or msg == "RightButton" then
					if self.exportFrame:IsShown() then
						self.exportFrame:Hide()
					end
					if LibStub("AceConfigDialog-3.0").OpenFrames[addonName] then
						PlaySound(closeOptionsSound)
						LibStub("AceConfigDialog-3.0"):Close(addonName)
					else
						insertGuildRanksIntoOptions()
						PlaySound(openOptionsSound)
						LibStub("AceConfigDialog-3.0"):Open(addonName)
					end
				end
			end,
			icon = "Interface\\AddOns\\"..addonName.."\\icon",
			OnTooltipShow = function(tooltip)
				if not tooltip or not tooltip.AddLine then return end
				tooltip:AddDoubleLine(addonName, GetAddOnMetadata(addonName, "Version"))
				tooltip:AddLine(string.format(L["|cffffff00Click|r to toggle the export interface.\nOr use /%s"], string.lower(addonName)))
			end,
		})

		if LDBIcon then
			LDBIcon:Register(addonName, self.LDBObj, self.db.profile.minimapIcon)
		end

	end
end

function addon:UpdateConfigs()
	if LDB and LDBIcon then
		LDBIcon:Refresh(addonName, self.db.profile.minimapIcon)
	end
	LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
	self.exportFrame:ClearAllPoints()
	self.exportFrame:SetPoint(unpack(self.db.profile.exportFrame.position))
	self.exportFrame:SetSize(unpack(self.db.profile.exportFrame.size))
end

function addon:SetupOptions()
	self.options.plugins.profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) }
	self.options.name = addonName
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(addonName, self.options)
	-- LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)
end

function addon:ExportData()
	local fileFormat = self.db.profile.fileFormat
	local ranks = self.db.profile.ranks
	local columns = self.db.profile.columns
	local removeRealmFromName = self.db.profile.removeRealmFromName
	local adjustRankIndex = self.db.profile.adjustRankIndex
	local roster = {}

	for i=1, GetNumGuildMembers() do
		local row = { GetGuildRosterInfo(i) }
		local rankIndex = row[3] + 1
		if ranks[rankIndex] then
			for k, v in pairs(row) do
				if not columns[k].enabled then
					row[k] = nil
				else
					if removeRealmFromName and k == 1 then
						row[k] = row[k]:gsub("-.+","")
					end

					if adjustRankIndex and k == 3 then
						row[k] = rankIndex
					end
				end
			end
			table.insert(roster, row)
		end
	end

	self.exportFrame.text:SetMaxLetters(self.db.profile.maxLetters)
	self.exportFrame.text:SetText("") -- Clear the edit box else SetMaxLetters is ignored if the edit box has been filled once before
	--[[
	Set the text in the export window's EditBox and display it.
	Doing the function call to the export function via a table key, so we can use the value of "fileFormat" to determine which function to use.
	This lets us easily add more export functions. All that is needed is to add the file format to "supportedFileFormats".
	]]--
	self.exportFrame.text:SetText(self[fileFormat](self, roster))
	self.exportFrame.text:HighlightText()
	self.exportFrame:Show()
end

local function getTabSub(n)
	local str = ""

	for i=1, n do
		str = str .. " "
	end

	return str
end

function addon:csv(data)
	local enclosure = self.db.profile.csvEnclosure
	local delimiter = self.db.profile.csvDelimiter
	local columns = self.db.profile.columns
	local output = ""
	local header = {}

	for k, v in pairs(columns) do
		if v.enabled then
			table.insert(header, v.name)
		end
	end

	data[0] = header

	for i=0, #data do
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

function addon:json(data)
	local columns = self.db.profile.columns
	local indentationStyle = self.db.profile.indentationStyle
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

			if addon.db.profile.jsonMinify then
				lines = string.format("%1$s\"%2$s\":%3$s,", lines, columns[k].name, c)
			else
				lines = string.format("%1$s\n\t\t\"%2$s\": %3$s,", lines, columns[k].name, c)
			end
		end

		-- Add the block of lines to the output. Trailing is comma removed.
		output = string.format("%1$s\n\t{%2$s\n\t},",output, lines:sub(1,-2))
	end

	-- Format the ouput. Trailing \n (newline) is removed.
	output = string.format("[%1$s\n]", output:sub(1,-2))

	if addon.db.profile.jsonMinify then
		output = output:gsub("\t", "")
		output = output:gsub("\n", "")
	elseif indentationStyle == "spaces" then
		local tabSub = getTabSub(self.db.profile.spacesIndentationDepth)
		output = output:gsub("\t", tabSub)
	end
	
	return output
end

function addon:xml(data)
	local xmlRootElementName = self.db.profile.xmlRootElementName
	local xmlRecordElementName = self.db.profile.xmlRecordElementName
	local columns = self.db.profile.columns
	local indentationStyle = self.db.profile.indentationStyle
	local output = ""

	for _, v in pairs(data) do
		local lines = ""
		for k, c in pairs(v) do			
			if type(c) == "boolean" then
				c = tostring(c)
			end

			lines = string.format("%1$s\t\t<%2$s>%3$s</%2$s>\n", lines, columns[k].name, c)
		end

		-- Add the block of lines to the output.
		output = string.format("%1$s\n\t<%2$s>\n%3$s\t</%2$s>", output, xmlRecordElementName, lines)
	end

	output = string.format("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<%1$s>%2$s\n</%1$s>", xmlRootElementName, output)

	if addon.db.profile.xmlMinify then
		output = output:gsub("\t", "")
		output = output:gsub("\n", "")
	elseif indentationStyle == "spaces" then
		local tabSub = getTabSub(self.db.profile.spacesIndentationDepth)
		output = output:gsub("\t", tabSub)
	end

	return output
end

local function findYamlSpecialCharacters(str)
	local characters = {
		["{"] = addon.db.profile.yamlMinify and "any" or "first",
		["}"] = addon.db.profile.yamlMinify and "any" or "first",
		["%["] = addon.db.profile.yamlMinify and "any" or "first",
		["%]"] = addon.db.profile.yamlMinify and "any" or "first",
		["&"] = "first",
		["*"] = "first",
		["?"] = addon.db.profile.yamlMinify and "any" or "first",
		["|"] = "first",
		["<"] = "any",
		[">"] = "any",
		["!"] = "first",
		["%%"] = "first",
		["@"] = "first",
		["%w:"] = addon.db.profile.yamlMinify and nil or "any",
		[":"] = addon.db.profile.yamlMinify and "any" or nil,
		["`"] = "first",
		[","] =  addon.db.profile.yamlMinify and "any" or "first",
		["'"] = "first",
		["#"] = "first",
		['"'] = "first",
	}
	local found = false
	for k,v in pairs(characters) do
		local pos = str:find(k)
		if pos and ((pos == 1 and v == "first") or (pos >= 1 and v == "any")) then
			found = true;
			break
		end
	end
	return found
end

function addon:yaml(data)
	local columns = self.db.profile.columns
	local output = ""

	for _, v in pairs(data) do
		local lines = ""
		for k, c in pairs(v) do
			if type(c) == "string" and (c == "" or findYamlSpecialCharacters(c)) then
				c =  c:gsub('\\', '\\\\')
				c =  c:gsub('"', '\\"')
				c = string.format('"%s"', c)
			end

			if type(c) == "boolean" then
				c = tostring(c)
			end
			if addon.db.profile.yamlMinify then
				lines = string.format("%1$s%2$s: %3$s,", lines, columns[k].name, c)
			else
				lines = string.format("%1$s %2$s: %3$s\n", lines, columns[k].name, c)
			end

		end

		-- Add the block of lines to the output.
		if addon.db.profile.yamlMinify then
			output = string.format("%1$s{%2$s},", output, lines:sub(1,-2))
		else
			output = string.format("%1$s-\n%2$s", output, lines)
		end
	end

	-- The trailing \n (newline) or comma is removed.
	output = output:sub(1,-2)

	if addon.db.profile.yamlMinify then
		return string.format("[%s]", output)
	else
		return output
	end
end
