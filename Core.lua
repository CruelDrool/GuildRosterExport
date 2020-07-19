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
					values = {["csv"] = "CSV", ["json"] = "JSON"},
					get = function(info, value) if value == addon.db.profile.exportType then return true end end,
					set = function(info, value) addon.db.profile.exportType = value end,
				},
				csv = {
					order = 2,
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
				columns = {
					order = 3,
					type = "group",
					name = L["Columns"],
					guiInline = true,
					args = {},
				},
				misc = {
					order = 4,
					type = "group",
					name = L["Miscellaneous"],
					guiInline = true,
					args = {
						removeRealmName = {
							order = 1,
							type = "toggle",
							name = L["Remove realm name from player names (column #1)"],
							width = "full",
							-- desc = L[""],
							get = function() return addon.db.profile.removeRealmFromName end,
							set = function(info, value) addon.db.profile.removeRealmFromName = value end,
						},
						adjustRankIndex = {
							order = 2,
							type = "toggle",
							name = string.format(L["Adjust %s"], "rankIndex"),
							desc = string.format(L["%s normally starts at 0, but this setting adjust that to 1."], "rankIndex"),
							get = function() return addon.db.profile.adjustRankIndex end,
							set = function(info, value) addon.db.profile.adjustRankIndex = value end,
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
				desc = string.format(L["%s Default column name: \"%s\"."], columnDescriptions[k], v.name ),
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
					if exportFrame:IsShown() then
						exportFrame:Hide()
					else
						if LibStub("AceConfigDialog-3.0").OpenFrames[addonName] then
							PlaySound(624) -- "GAMEGENERICBUTTONPRESS"
							LibStub("AceConfigDialog-3.0"):Close(addonName)
						end
						self:ExportData()
					end
				end
			end,
			icon = "Interface\\MINIMAP\\Minimap_skull_elite",
			OnTooltipShow = function(tooltip)
				if not tooltip or not tooltip.AddLine then return end
				tooltip:AddLine(addonName)
				tooltip:AddLine(L["|cffffff00Right-click|r to open the options menu"])
				tooltip:AddLine(L["|cffffff00Left-click|r to export data based upon your settings"])
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
end

function addon:SetupOptions()
	self.options.plugins.profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) }
	self.options.name = addonName
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(addonName, self.options)
	-- LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)
end

function addon:ExportData()
	local exportType = self.db.profile.exportType
	local enclosure = self.db.profile.enclosure
	local delimiter = self.db.profile.delimiter
	local output = ''
	
	if exportType == "json" then
		output = "["
	end
	
	for i=1, GetNumGuildMembers() do
		local row = { GetGuildRosterInfo(i) }
		local line = ''
		for k, v in ipairs(row) do
			if self.db.profile.columns[k].enabled then
				if self.db.profile.removeRealmFromName and k == 1 then
					v = v:gsub("-.+","")
				end
				
				if self.db.profile.adjustRankIndex and k == 3 then
					v = v + 1
				end
				
				if exportType == "csv" then
					line = line .. enclosure .. v .. enclosure .. delimiter
				elseif exportType == "json" then
					line = line .. string.format("\"%s\": ", self.db.profile.columns[k].name)
					if (type(v) == "string") then 
						line = line .. string.format('"%s",', v)
					else
						line = line .. string.format('%s,', v)
					end
				end
			end
		end
		
		if exportType == "csv" then
			output = output .. "\n" .. line:sub(1,-2)
		elseif exportType == "json" then
			output = output .. "\n{" .. line:sub(1,-2) .. "},"
		end
		
	end
	
	if exportType == "csv" then
		local header = ''
		for k, v in ipairs(self.db.profile.columns) do
			if v.enabled then
				header = header .. enclosure .. v.name .. enclosure .. delimiter
			end
		end
		output = header:sub(1,-2) .. output
	elseif exportType == "json" then
		output = output:sub(1,-2) .. "\n]"
	end
	
	
	
	exportFrame.scroll.text:SetText(output);
	exportFrame.scroll.text:HighlightText()
	exportFrame:Show()
end