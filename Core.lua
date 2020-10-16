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
	["csv"] = "CSV",
	["json"] = "JSON",
	["xml"] = "XML",
	["yaml"] = "YAML",
}

local exportFrame = _G[addonName..'Frame']
local openOptionsSound = 88 -- "GAMEDIALOGOPEN"
local closeOptionsSound = 624 -- "GAMEGENERICBUTTONPRESS"

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
			desc = L["WARNING! Large exports may freeze your game for several seconds!\n\nNote: all exports are in UTF-8."],
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
							desc = L["Set the maximum number of letters that the export window can show."],
							get = function() return tostring(addon.db.profile.maxLetters) end,
							set = function(info, value) value = tonumber(value) if value ~= "" then addon.db.profile.maxLetters = value; exportFrame.scroll.text:SetMaxLetters(value) end end,
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
							name = L["Spaces are the default indentation style because tabs are displayed as question marks in the export window. However, copying the tabs work just fine and will be displayed correctly in a text editor."],
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
					name = L["CSV"],
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
				xml = {
					order = 6,
					type = "group",
					name = L["XML"],
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

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New(addonName.."DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateConfigs")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateConfigs")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateConfigs")
	
	self:SetupOptions()
	
	exportFrame.scroll.text:SetMaxLetters(self.db.profile.maxLetters)
	exportFrame.closeButton:SetText(L["Close"])
	exportFrame.closeAndReturnButton:SetText(L["Close & Return"])
	exportFrame.closeAndReturnButton:SetScript("OnClick", function() exportFrame:Hide(); PlaySound(openOptionsSound); LibStub("AceConfigDialog-3.0"):Open(addonName) end)
	
	self:RegisterChatCommand(string.lower(addonName), function() exportFrame:Hide(); PlaySound(openOptionsSound); LibStub("AceConfigDialog-3.0"):Open(addonName) end)
	
	if LDB then
		self.LDBObj = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
			type = "launcher",
			OnClick = function(_, msg)
				if msg == "LeftButton" or msg == "RightButton" then
					if exportFrame:IsShown() then
						exportFrame:Hide()
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
	exportFrame.scroll.text:SetMaxLetters(self.db.profile.maxLetters)
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

	--[[
	Set the text in the export window's EditBox and display it.
	Doing the function call to the export function via a table key, so we can use the value of "fileFormat" to determine which function to use.
	This lets us easily add more export functions. All that is needed is to add the file format to "supportedFileFormats".
	]]--
	exportFrame.scroll.text:SetText(self[fileFormat](self, roster));
	exportFrame.scroll.text:HighlightText()
	exportFrame:Show()
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
				c = string.format('"%s"', c)
			end
			
			if type(c) == "boolean" then
				c = tostring(c)
			end
			
			lines = string.format("%1$s\n\t\t\"%2$s\": %3$s,", lines, columns[k].name, c)
		end
		
		-- Add the block of lines to the output. Trailing is comma removed.
		output = string.format("%1$s\n\t{%2$s\n\t},",output, lines:sub(1,-2))
	end
	
	-- Format the ouput. Trailing \n (newline) is removed.
	output = string.format("[%1$s\n]", output:sub(1,-2))
	
	if indentationStyle == "spaces" then
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
	
	if indentationStyle == "spaces" then
		local tabSub = getTabSub(self.db.profile.spacesIndentationDepth)
		output = output:gsub("\t", tabSub)
	end
	
	return output
end

function addon:yaml(data)
	local columns = self.db.profile.columns
	local output = ""
		
	for _, v in pairs(data) do
		local lines = ""
		for k, c in pairs(v) do
			if (type(c) == "string") then 
				c = string.format('"%s"', c)
			end
			
			if type(c) == "boolean" then
				c = tostring(c)
			end
			
			lines = string.format("%1$s %2$s: %3$s\n", lines, columns[k].name, c)
		end
		
		-- Add the block of lines to the output.
		output = string.format("%1$s-\n%2$s", output, lines)
	end
	
	-- Return output. The trailing \n (newline) is removed.
	return output:sub(1,-2)
end