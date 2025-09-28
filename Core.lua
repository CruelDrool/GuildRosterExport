---@class Private
local Private = select(2, ...)

---@class Debug
local Debug = Private.Debug

---@class Settings
local Settings = Private.Settings

local addonName = ...
local chatCommand = addonName:lower()
local GUILD_ROSTER_NUM_ROWS = 17

---@class BackdropFrame: Frame
---@class BackdropFrame: BackdropTemplate

---@class Addon
local addon = Private.Addon
local L = Private.Translate:GetLocaleEntries()
local LibDataBroker = Private.libs.LibDataBroker
local LibDBIcon = Private.libs.LibDBIcon
local AceConfigDialog = Private.libs.AceConfigDialog
local AceConfigRegistry = Private.libs.AceConfigRegistry
local AceDB = Private.libs.AceDB
local AceDBOptions = Private.libs.AceDBOptions

local sounds = {
	openOptions = 88, -- "GAMEDIALOGOPEN"
	closeOptions = 624, -- "GAMEGENERICBUTTONPRESS"
	closeExportFrame = SOUNDKIT.GS_TITLE_OPTION_EXIT
}

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
	closeButton:SetText(CLOSE)

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
	local defaults = Settings:GetDefaults()
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

function addon:PLAYER_ENTERING_WORLD(event, isInitialLogin, isReloadingUi)
	if self.db.profile.autoExport and (isInitialLogin or isReloadingUi) and IsInGuild() then
		-- Request updated guild roster data from the server. This will trigger "GUILD_ROSTER_UPDATE".
		C_GuildInfo.GuildRoster()
	end
end

function addon:GUILD_ROSTER_UPDATE(event)
	-- This event only triggers when in a guild. But why trust anyone!?
	if self.db.profile.autoExport and IsInGuild() and #{GetGuildRosterInfo(1)} >= GUILD_ROSTER_NUM_ROWS then
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

	self.db.profile.html.style = self.db.profile.html.minify and "minified" or self.db.profile.html.style
	self.db.profile.html.minify = nil

	self.db.profile.json.style = self.db.profile.json.minify and "minified" or self.db.profile.json.style
	self.db.profile.json.minify = nil

	self.db.profile.xml.style = self.db.profile.xml.minify and "minified" or self.db.profile.xml.style
	self.db.profile.xml.minify = nil

	self.db.profile.yaml.style = self.db.profile.yaml.minify and "minified" or self.db.profile.yaml.style
	self.db.profile.yaml.minify = nil
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
	local options = Settings:GetOptions()
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
		Settings:InsertGuildRanksIntoOptions()
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

	local supportedFileFormats = Settings:GetSupportedFormats()

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

local function CalculateLastOnline(currentTime, yearsOffline, monthsOffline, daysOffline, hoursOffline)
	local dateInfo = date("*t",currentTime-(hoursOffline * 3600 + daysOffline * 86400))
	local year = dateInfo.year - yearsOffline
	local month = dateInfo.month - monthsOffline
	local day = dateInfo.day

	if month <= 0 then
		year = year - 1
		month = month + 12
	end

	return time({day=day,month=month,year=year,hour=dateInfo.hour})
end

local function GetTestRoster(self, currentTime)

	local realmName = "SomeRealm"
	local lastOnlineHours = self.db.profile.lastOnlineHours

	local zoneIDs = {
		2112,
		2214,
		2215,
		2248,
		2255,
		2339,
		2346,
		2369,
	}

	local GenerateLocation = function()
		return C_Map.GetMapInfo(zoneIDs[random(#zoneIDs)]).name
	end

	local GeneratelastOnline = function()
		local lastOnline = CalculateLastOnline(currentTime, 0, math.random(0,2), math.random(0,28), math.random(0,23))
		return lastOnlineHours and ((currentTime-lastOnline)/3600) or lastOnline
	end

	local tbl = {
		{"Coldbarr-" .. realmName,"Initiate",4,80,GetClassInfo(8),GenerateLocation(),"","",false,0,"MAGE",6710,13,false,false,4,"Player-9999-3129C53",GeneratelastOnline(),realmName},
		{"Borre-" .. realmName,"Member",3,80,GetClassInfo(7),GenerateLocation(),"","",false,0,"SHAMAN",24520,4,false,false,5,"Player-9999-EFB134A",GeneratelastOnline(),realmName},
		{"Dedli-" .. realmName,"Member",3,80,GetClassInfo(4),GenerateLocation(),"","",false,0,"ROGUE",12800,11,false,false,6,"Player-9999-6AB86C5",GeneratelastOnline(),realmName},
		{"Kilhe-" .. realmName,"Member",3,80,GetClassInfo(10),GenerateLocation(),"","",false,0,"MONK",22705,5,false,false,6,"Player-9999-A97F5C2",GeneratelastOnline(),realmName},
		{"Ongel-" .. realmName,"Member",3,80,GetClassInfo(2),GenerateLocation(),"","",false,0,"PALADIN",18430,8,false,false,7,"Player-9999-AE48979",GeneratelastOnline(),realmName},
		{"Sylis-" .. realmName,"Member",3,80,GetClassInfo(11),GenerateLocation(),"","",false,0,"DRUID",19390,6,false,false,8,"Player-9999-3794CAB",GeneratelastOnline(),realmName},
		{"Falka-" .. realmName,"Veteran",2,80,GetClassInfo(5),GenerateLocation(),"","",false,0,"PRIEST",17435,9,false,false,8,"Player-9999-BF7C323",GeneratelastOnline(),realmName},
		{"Nikoru-" .. realmName,"Veteran",2,80,GetClassInfo(6),GenerateLocation(),"","",false,0,"DEATHKNIGHT",19260,7,false,false,8,"Player-9999-7156B04",GeneratelastOnline(),realmName},
		{"Pawind-" .. realmName,"Veteran",2,80,GetClassInfo(3),GenerateLocation(),"","",false,0,"HUNTER",8100,12,false,false,8,"Player-9999-E10B3D9",GeneratelastOnline(),realmName},
		{"Dexxer-" .. realmName,"Officer",1,80,GetClassInfo(9),GenerateLocation(),"","",false,0,"WARLOCK",16570,10,false,false,8,"Player-9999-ED50CED",GeneratelastOnline(),realmName},
		{"Fraddi-" .. realmName,"Officer",1,80,GetClassInfo(12),GenerateLocation(),"","",false,0,"DEMONHUNTER",35745,1,false,false,8,"Player-9999-4B38DB8",GeneratelastOnline(),realmName},
		{"Wiley-" .. realmName,"Officer",1,80,GetClassInfo(13),GenerateLocation(),"","",false,0,"EVOKER",26270,3,false,false,8,"Player-9999-F7F79D4",GeneratelastOnline(),realmName},
		{"Leewar-" .. realmName,"Guild Master",0,80,GetClassInfo(1),GenerateLocation(),"","",false,0,"WARRIOR",27150,2,false,false,8,"Player-9999-DA07A3A",GeneratelastOnline(),realmName},
	}

	return tbl
end

function addon:ExportData(fileFormat, saveToDB)
	fileFormat = fileFormat or self.db.profile.fileFormat
	local ranks = self.db.profile.ranks
	local columns = self.db.profile.columns
	local removeRealmFromName = self.db.profile.removeRealmFromName
	local adjustRankIndex = self.db.profile.adjustRankIndex
	local lastOnlineHours = self.db.profile.lastOnlineHours
	local rawRoster = {}
	local filteredRoster = {}
	local serverTimeInfo = date("*t",GetServerTime())
	local currentTime = time({day=serverTimeInfo.day, month=serverTimeInfo.month, year=serverTimeInfo.year, hour=serverTimeInfo.hour})

	if IsInGuild() then

		local numRows = #{ GetGuildRosterInfo(1) } -- Always at least 1 person in a guild, and that's the exporter themself.

		if numRows > GUILD_ROSTER_NUM_ROWS then
			Debug:Log("Export~6~ERR~More columns than expected. Number of columns: %s.", tostring(numRows))
		elseif numRows < GUILD_ROSTER_NUM_ROWS then
			Debug:Log("Export~6~ERR~Fewer columns than expected. Number of columns: %s.", tostring(numRows))
		else
			for i=1, GetNumGuildMembers() do
				local row = { GetGuildRosterInfo(i) }
				local lastOnline = currentTime
				local yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i)

				if hoursOffline then
					lastOnline = CalculateLastOnline(currentTime, yearsOffline, monthsOffline, daysOffline, hoursOffline)
				end

				lastOnline = lastOnlineHours and ((currentTime-lastOnline)/3600) or lastOnline

				table.insert(row, lastOnline)

				local realmName = row[1]:match("-([^-]+)")

				table.insert(row, realmName)

				table.insert(rawRoster, row)
			end
		end
	else
		rawRoster = GetTestRoster(self, currentTime)
	end

	if #rawRoster > 0 then
		for _, row in ipairs(rawRoster) do
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
				table.insert(filteredRoster, row)
			end
		end
	end

	--[[
	Doing the function call to the export function via a table key, so we can use the value of "fileFormat" to determine which function to use.
	This lets us easily add more export functions. All that is needed is to add the file format to "supportedFileFormats".
	]]--

	if #filteredRoster > 0 then
		local output = self[fileFormat](self, filteredRoster)
		if saveToDB then
				self.db.profile.autoExportSave = output
		else
			self.exportFrame.text:SetMaxLetters(self.db.profile.exportFrame.maxLetters)
			self.exportFrame.text:SetText("") -- Clear the edit box else SetMaxLetters is ignored if the edit box has been filled once before
			-- Set the text in the export window's EditBox and display it.
			self.exportFrame.text:SetText(output)
			self.exportFrame.text:HighlightText()
			self.exportFrame:Show()
		end
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
	local beautify = self.db.profile.html.style == "beautified"
	local compact = self.db.profile.html.style == "compacted"
	local minify = self.db.profile.html.style == "minified"
	local wp = self.db.profile.html.wp.enabled
	local wpStripedStyle = self.db.profile.html.wp.stripedStyle
	local wpFixedWidth = self.db.profile.html.wp.fixedWidth
	local thead = ""
	local tbody = ""
	local output = ""

	if header then
		for _, v in ipairs(columns) do
			if v.enabled then
				if compact then
					thead = string.format("%s<th>%s</th>", thead, v.name)
				else
					thead = string.format("%s\t\t\t<th>%s</th>\n", thead, v.name)
				end
			end
		end

		if compact then
			thead = string.format("<thead>\n<tr>%s</tr></thead>",thead)
		else
			thead = string.format("\t<thead>\n\t\t<tr>\n%s\t\t</tr>\n\t</thead>\n",thead)
		end
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
			if compact then
				cells = string.format("%s<td>%s</td>", cells, c)
			else
				cells = string.format("%s\t\t\t<td>%s</td>\n", cells, c)
			end
		end

		-- Add the block of cells to the body as a row.
		if compact then
			tbody = string.format("%s<tr>%s</tr>\n", tbody, cells)
		else
			tbody = string.format("%s\n\t\t<tr>\n%s\t\t</tr>", tbody, cells)
		end
	end

	if compact then
		output = string.format('<table%s>%s<tbody>\n%s</tbody></table>', (wp and wpFixedWidth) and  ' class="has-fixed-layout"' or "", thead, tbody)
	else
		output = string.format('<table%s>\n%s\t<tbody>%s\n\t</tbody>\n</table>', (wp and wpFixedWidth) and  ' class="has-fixed-layout"' or "", thead, tbody)
	end

	if minify or wp then
		output = output:gsub("\t", "")
		output = output:gsub("\n", "")
	elseif beautify and indentationStyle == "spaces" then
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
	local beautify = self.db.profile.json.style == "beautified"
	local compact = self.db.profile.json.style == "compacted"
	local minify = self.db.profile.json.style == "minified"
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

			if compact or minify then
				lines = string.format("%1$s\"%2$s\":%3$s,", lines, columns[k].name, c)
			else
				lines = string.format("%1$s\n\t\t\"%2$s\": %3$s,", lines, columns[k].name, c)
			end
		end

		-- Add the block of lines to the output. Trailing comma is removed.
		if compact then
			output = string.format("%1$s{%2$s},\n",output, lines:sub(1,-2))
		else
			output = string.format("%1$s\n\t{%2$s\n\t},",output, lines:sub(1,-2))
		end
	end

	-- Format the ouput.
	if compact then
		-- Trailing \n (newline) and commma is removed.
		output = string.format("[%s]", output:sub(1,-3))
	else
		-- Trailing \n (newline) is removed.
		output = string.format("[%s\n]", output:sub(1,-2))
	end

	if minify then
		output = output:gsub("\t", "")
		output = output:gsub("\n", "")
	elseif beautify and indentationStyle == "spaces" then
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
	local beautify = self.db.profile.xml.style == "beautified"
	local compact = self.db.profile.xml.style == "compacted"
	local minify = self.db.profile.xml.style == "minified"
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

			if compact then
				lines = string.format("%1$s<%2$s>%3$s</%2$s>", lines, columns[k].name, c)
			else
				lines = string.format("%1$s\t\t<%2$s>%3$s</%2$s>\n", lines, columns[k].name, c)
			end
		end

		-- Add the block of lines to the output.
		if compact then
			output = string.format("%1$s\n<%2$s>%3$s</%2$s>", output, recordElementName, lines)
		else
			output = string.format("%1$s\n\t<%2$s>\n%3$s\t</%2$s>", output, recordElementName, lines)
		end
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
	local beautify = self.db.profile.yaml.style == "beautified"
	local compact = self.db.profile.yaml.style == "compacted"
	local minify = self.db.profile.yaml.style == "minified"
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

		["?"] = (compact or minify) and "any" or "first", -- Mapping key indicator. When minifying, yamllint.com craps out on any question marks that aren't inside quotes. The other validators/parsers do not.

		[":"] = "any", -- Mapping value indicator.
		-- [":"] = (compact or minify) and "any" or nil, -- Yamllint.com craps out on any colon not inside quotes when minifying.
		-- ["^:"] = (compact or minify) and nil or "first", -- Usually a colon at the start isn't a problem (as long it's not followed by a space). However, yamllint.com replaces the colon with the text "!ruby/symbol", though...
		-- [":$"] = (compact or minify) and nil or "any", -- Colon character at the end.
		-- ["%S+%s*:%s+"] = (compact or minify) and nil or "any", -- Non-space characters (usually words) followed by zero, or more, space character(s) and then a colon followed by 1, or more, space character(s).

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

			if compact or minify then
				lines = string.format("%1$s%2$s: %3$s,", lines, columns[k].name, c)
			else
				lines = string.format("%1$s %2$s: %3$s\n", lines, columns[k].name, c)
			end

		end

		-- Add the block of lines to the output.
		if compact then
			output = string.format("%1$s{%2$s},\n", output, lines:sub(1,-2))
		elseif minify then
			output = string.format("%1$s{%2$s},", output, lines:sub(1,-2))
		else
			output = string.format("%1$s-\n%2$s", output, lines)
		end
	end

	if compact then
		-- The trailing \n (newline) and comma is removed.
		output = output:sub(1,-3)
	else
		-- The trailing \n (newline) or comma is removed.
		output = output:sub(1,-2)
	end

	if compact or minify then
		output = string.format("[%s]", output)
	end

	return output
end
