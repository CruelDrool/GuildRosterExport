---@class Private
local Private = select(2, ...)

---@class Debug
local Debug = Private.Debug

---@class Utils
local Utils = Private.Utils

---@class Translate
local Translate = Private.Translate

---@class Exports
local Exports = Private.Exports

---@class Settings
local Settings = Private.Settings

---@class ExportFrame
local ExportFrame = Private.ExportFrame

local addonName = ...
local chatCommand = addonName:lower()
local GUILD_ROSTER_NUM_ROWS = 17

---@class BackdropFrame: Frame
---@class BackdropFrame: BackdropTemplate

---@class Core: AceAddon
---@class Core: AceConsole-3.0
---@class Core: AceEvent-3.0
local Core = Utils.libs.AceAddon:NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
Private.Core = Core

local L = Translate:GetLocaleEntries()
local LibDataBroker = Utils.libs.LibDataBroker
local LibDBIcon = Utils.libs.LibDBIcon
local AceConfigDialog = Utils.libs.AceConfigDialog
local AceConfigRegistry = Utils.libs.AceConfigRegistry
local AceDB = Utils.libs.AceDB
local AceDBOptions = Utils.libs.AceDBOptions

function Core:OnInitialize()
	local defaults = Settings:GetDefaults()

	Private.db = AceDB:New(addonName.."DB", defaults)
	Private.db.RegisterCallback(self, "OnProfileChanged", "UpdateConfigs")
	Private.db.RegisterCallback(self, "OnProfileCopied", "UpdateConfigs")
	Private.db.RegisterCallback(self, "OnProfileReset", "UpdateConfigs")


	Settings:ConvertOldConfig()
	ExportFrame:LoadPosition()

	self:SetupOptions()

	self:RegisterChatCommand(chatCommand, "ChatCommand")

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")

	if LibDataBroker then
		local LDBObj = LibDataBroker:NewDataObject(addonName, {
			type = "launcher",
			icon = ([[Interface\AddOns\%s\icon]]):format(addonName),
			OnClick = function(_, mouseButton)
				if mouseButton == "LeftButton" or mouseButton == "RightButton" then
					self:ToggleOptions()
				end
			end,
			OnTooltipShow = function(tooltip)
				if not (tooltip and tooltip.AddLine) then return end
				tooltip:AddDoubleLine(addonName, C_AddOns.GetAddOnMetadata(addonName, "Version"))
				tooltip:AddLine(" ")
				tooltip:AddLine( L["%sClick%s to toggle options."]:format(Utils.colors.tooltip.mouseaction:GenerateHexColorMarkup(), "|r"), Utils.colors.tooltip.default:GetRGB() )
				tooltip:AddLine( L["Or use the chat command %s"]:format(Utils.colors.tooltip.highlight:WrapTextInColorCode( ("/%s"):format(chatCommand) )), Utils.colors.tooltip.default:GetRGB() )
			end,
		})

		if LibDBIcon then
			LibDBIcon:Register(addonName, LDBObj, Private.db.profile.minimapIcon)
		end
	end
end

function Core:PLAYER_ENTERING_WORLD(event, isInitialLogin, isReloadingUi)
	if Private.db.profile.autoExport and (isInitialLogin or isReloadingUi) and IsInGuild() then
		-- Request updated guild roster data from the server. This will trigger "GUILD_ROSTER_UPDATE".
		C_GuildInfo.GuildRoster()
	end
end

function Core:GUILD_ROSTER_UPDATE(event)
	-- This event only triggers when in a guild. But why trust anyone!?
	if Private.db.profile.autoExport and IsInGuild() and #{GetGuildRosterInfo(1)} >= GUILD_ROSTER_NUM_ROWS then
		self:ExportData(nil, true)
	end
end

function Core:UpdateConfigs()
	Settings:ConvertOldConfig()

	-- Reset the auto export save. Don't want that when changing profile.
	Private.db.profile.autoExportSave = nil

	if LibDataBroker and LibDBIcon then
		LibDBIcon:Refresh(addonName, Private.db.profile.minimapIcon)
	end

	AceConfigRegistry:NotifyChange(addonName)

	ExportFrame:LoadPosition()
end

function Core:SetupOptions()
	local options = Settings:GetOptions()
	options.plugins.profiles = { profiles = AceDBOptions:GetOptionsTable(Private.db) }
	AceConfigRegistry:RegisterOptionsTable(addonName, options)
	-- AceConfigDialog:AddToBlizOptions(addonName, addonName)
end

function Core:ToggleOptions()
	if ExportFrame:IsShown() then
		ExportFrame:Hide()
	end
	if AceConfigDialog.OpenFrames[addonName] then
		PlaySound(Utils.sounds.closeOptions)
		AceConfigDialog:Close(addonName)
	else
		Settings:InsertGuildRanksIntoOptions()
		PlaySound(Utils.sounds.openOptions)
		AceConfigDialog:Open(addonName)
	end
end

function Core:SystemMessageInPrimary(msg)
	local color = ChatTypeInfo["SYSTEM"]
	DEFAULT_CHAT_FRAME:AddMessage(msg, color.r, color.g, color.b)
end

function Core:ChatCommand(args)
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
	local lastOnlineHours = Private.db.profile.lastOnlineHours

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

function Core:ExportData(fileFormat, saveToDB)
	fileFormat = fileFormat or Private.db.profile.fileFormat
	local ranks = Private.db.profile.ranks
	local columns = Private.db.profile.columns
	local removeRealmFromName = Private.db.profile.removeRealmFromName
	local adjustRankIndex = Private.db.profile.adjustRankIndex
	local lastOnlineHours = Private.db.profile.lastOnlineHours
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

	if #filteredRoster > 0 then
		local output = Exports:DoExport(fileFormat, filteredRoster)
		if saveToDB then
			Private.db.profile.autoExportSave = output
		else
			ExportFrame:SetTextAndShow(output)
		end
	end
end
