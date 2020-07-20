local addonName = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)
-- _G[addonName] = addon -- uncomment for debugging purposes

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

local defaults = {
	profile = {
		minimapIcon = {},
		delimiter = ',',
		enclosure = '"',
		exportType = "csv";
		removeRealmFromName = true,
		adjustRankIndex = true,
		maxLetters = 2000000,
		tabSize = 4,
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

local exportFrame = _G[addonName..'Frame']

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
			-- disabled = function() return not LDBIcon end,
			disabled = function() return not LDBTitan end,
		},
		settings = {
			order = 2,
			type = "group",
			name = L["Settings"],
			args = {
				exportType = {
					order = 1,
					type = "multiselect",
					name = L["Export type"],
					values = {["csv"] = "CSV", ["json"] = "JSON", ["xml"] = "XML", ["yaml"] = "YAML"},
					get = function(info, value) if value == addon.db.profile.exportType then return true end end,
					set = function(info, value) addon.db.profile.exportType = value end,
				},
				misc = {
					order = 2,
					type = "group",
					name = L["General export settings"],
					guiInline = true,
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
						tabSize = {
							order = 5,
							type = "range",
							min = 0,
							max = 4,
							step = 1,
							width = "normal",
							name = L["Tab size"],
							desc = L["Set the tab size in number of spaces. Used when exporting JSON, XML and YAML. Shorter tab size shortens the time before the data is displayed. Note: YAML-exports ignores a value of 0, and will default to 1."],
							get = function() return addon.db.profile.tabSize end,
							set = function(info, value) addon.db.profile.tabSize = value; end,
						},
					},
				},
				csv = {
					order = 3,
					type = "group",
					name = L["CSV export settings"],
					guiInline = true,
					args = {
						delimiter = {
							order = 1,
							type = "input",
							width = "half",
							name = L["Delimiter"],
							get = function() return addon.db.profile.delimiter end,
							set = function(info, value) if value ~= "" then addon.db.profile.delimiter = value end end,
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
							get = function() return addon.db.profile.enclosure end,
							set = function(info, value) if value ~= "" then addon.db.profile.enclosure = value end end,
						},
					},
				},
				xml = {
					order = 4,
					type = "group",
					name = L["XML export settings"],
					guiInline = true,
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
				columns = {
					order = 5,
					type = "group",
					name = L["Columns"],
					guiInline = true,
					args = {},
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

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New(addonName.."DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateConfigs")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateConfigs")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateConfigs")
		
	self:SetupOptions()
	
	exportFrame.scroll.text:SetMaxLetters(self.db.profile.maxLetters)
	exportFrame.button:SetText(L["Close"])
	
	if LDB then
		self.LDBObj = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
			type = "launcher",
			OnClick = function(_, msg)
				if msg == "RightButton" then
					if LibStub("AceConfigDialog-3.0").OpenFrames[addonName] then
						PlaySound(624) -- "GAMEGENERICBUTTONPRESS"
						LibStub("AceConfigDialog-3.0"):Close(addonName)
					else
						if exportFrame:IsShown() then
							exportFrame:Hide()
						end
						PlaySound(88) -- "GAMEDIALOGOPEN"
						LibStub("AceConfigDialog-3.0"):Open(addonName)
					end
				elseif msg == "LeftButton" then
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
					
					if LibStub("AceConfigDialog-3.0").OpenFrames[addonName] then
						PlaySound(624) -- "GAMEGENERICBUTTONPRESS"
						LibStub("AceConfigDialog-3.0"):Close(addonName)
					end
					
					if exportFrame:IsShown() then
						exportFrame:Hide()
					elseif IsShiftKeyDown() then
						exportFrame:Show()
					else
						self:ExportData()
					end
				end
			end,
			icon = "Interface\\MINIMAP\\Minimap_skull_elite",
			OnTooltipShow = function(tooltip)
				if not tooltip or not tooltip.AddLine then return end
				tooltip:AddLine(addonName)
				tooltip:AddLine(L["|cffffff00Right-click|r to toggle the options menu"])
				tooltip:AddLine(L["|cffffff00Left-click|r to export data based upon your settings"])
				tooltip:AddLine(L["|cffffff00Shift-Left-click|r to only open the export window"])
			end,
		})

		if LDBIcon then
			LDBIcon:Register(addonName, self.LDBObj, self.db.profile.minimapIcon)
		end
			
	end
end

function addon:UpdateConfigs()
	if LDB and LDBIcon then
		LDBIcon:Refresh(addonName, addon.db.profile.minimapIcon)
	end
	LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
	exportFrame.scroll.text:SetMaxLetters(addon.db.profile.maxLetters)
end

function addon:SetupOptions()
	self.options.plugins.profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) }
	self.options.name = addonName
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(addonName, self.options)
	-- LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)
end

local function export_csv(data)
	local header = {}
	for k, v in pairs(addon.db.profile.columns) do
		if v.enabled then
			table.insert(header, v.name)
		end
	end

	data[0] = header

	local enclosure = addon.db.profile.enclosure
	local delimiter = addon.db.profile.delimiter
	local output = ""

	for i=0, #data do
		local line = ""
		for _, c in pairs(data[i]) do
		
			if type(c) == "boolean" then
				c = tostring(c)
			end
			
			line = string.format("%1$s%2$s%4$s%2$s%3$s", line, enclosure, delimiter, c)
		end
		output = string.format("%1$s%2$s\n", output, line:sub(1,-2))
	end

	return output:sub(1,-2)
end

local function export_json(data)
	local output = ""

	for _, v in pairs(data) do
		local line = ''
		for k, c in pairs(v) do
			if (type(c) == "string") then 
				c = string.format('"%s"', c)
			end
			
			if type(c) == "boolean" then
				c = tostring(c)
			end
			
			line = string.format("%1$s\n\t\t\"%2$s\": %3$s,", line, addon.db.profile.columns[k].name, c)
		end
		output = string.format("%1$s\n\t{%2$s\n\t},",output, line:sub(1,-2))
	end
	output = string.format("[%1$s\n]", output:sub(1,-2))
	return output:gsub("\t", addon.tab)
end

local function export_xml(data)
	local xmlRootElementName = addon.db.profile.xmlRootElementName
	local xmlRecordElementName = addon.db.profile.xmlRecordElementName
	local output = string.format("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<%s>", xmlRootElementName)
	
	for _, v in pairs(data) do
		local line = string.format("\n\t<%s>\n", xmlRecordElementName)
		for k, c in pairs(v) do
			local elementName = addon.db.profile.columns[k].name
			local startTag = string.format("<%s>", elementName)
			local endTag = string.format("</%s>", elementName)
			
			if type(c) == "boolean" then
				c = tostring(c)
			end
			
			line = string.format("%1$s\t\t%2$s%3$s%4$s\n", line, startTag, c, endTag)
		end
		output = string.format("%1$s%2$s\t</%3$s>", output, line, xmlRecordElementName)
	end
	output = string.format("%1$s\n</%2$s>", output, xmlRootElementName)
	
	return output:gsub("\t", addon.tab)
end

local function export_yaml(data)
	local output = ""
	
	for _, v in pairs(data) do
		local block = "-\n"
		for k, c in pairs(v) do
			if (type(c) == "string") then 
				c = string.format('"%s"', c)
			end
			
			if type(c) == "boolean" then
				c = tostring(c)
			end
			
			block = string.format("%1$s\t%2$s: %3$s\n", block, addon.db.profile.columns[k].name, c)
		end
		output = string.format("%1$s%2$s\n", output, block:sub(1,-2))
	end

	return output:sub(1,-2):gsub("\t", addon.tab:len() > 0 and addon.tab or " ")
end

local export_functions ={
	["csv"] = export_csv,
	["json"] = export_json,
	["xml"] = export_xml,
	["yaml"] = export_yaml,
}

function addon:ExportData()

	self.tab = ""

	for i=1, self.db.profile.tabSize do
		self.tab = self.tab .. " "
	end
	
	local roster = {}

	for i=1, GetNumGuildMembers() do
		local row = { GetGuildRosterInfo(i) }
		for k, v in pairs(row) do
			if not self.db.profile.columns[k].enabled then
				row[k] = nil
			end

			if self.db.profile.columns[k].enabled then
				if self.db.profile.removeRealmFromName and k == 1 then
					row[k] = row[k]:gsub("-.+","")
				end
				
				if self.db.profile.adjustRankIndex and k == 3 then
					row[k] = row[k]+1
				end
			end
		end
		table.insert(roster, row)		
	end

	exportFrame.scroll.text:SetText(export_functions[self.db.profile.exportType](roster));
	exportFrame.scroll.text:HighlightText()
	exportFrame:Show()
end