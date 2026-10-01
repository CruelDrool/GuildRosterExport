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

---@class Md
local Md = {
	fileFormat = "md",
	displayName = "MD", -- Untranslated display name.
	defaults = {
		style = "compacted",
		alignment = "none",
	}
}

local L = Translate:GetLocaleEntries()

---@param order number
---@return table
function Md.GetOptions(order)

	local beautifiedDesc = L["%s makes the output look really organized and easy to read but uses a lot of text characters, lines, and space."]:format(Utils.colors.tooltip.highlight:WrapTextInColorCode(L["Beautified"]))
	local compactedDesc = L["%s removes many unnecessary text characters and puts each entry in the guild roster on one line each."]:format(Utils.colors.tooltip.highlight:WrapTextInColorCode(L["Compacted"]))
	local styleDesc = ("%s\n\n%s"):format(beautifiedDesc, compactedDesc)

	local tbl = {
		order = order,
		type = "group",
		name = L["MD"],
		-- guiInline = true,
		args = {
			title = {
				order = 1,
				width = "full",
				type = "description",
				fontSize = "large",
				name = L["MD"],
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
				desc = styleDesc,
				values = {
					["beautified"] = L["Beautified"],
					["compacted"] = L["Compacted"],
				},
				sorting = {"beautified","compacted"},
				get = function() return Private.db.profile.md.style end,
				set = function(info, value) Private.db.profile.md.style = value end,
			},
			alignment = {
				order = 4,
				type = "select",
				style = "radio",
				width = "half",
				name = L["Column alignment"],
				-- desc = "",
				values = {
					["none"] = L["None"],
					["left"] = L["Left"],
					["center"] = L["Center"],
					["right"] = L["Right"],
				},
				sorting = {"none","left", "center", "right"},
				get = function() return Private.db.profile.md.alignment end,
				set = function(info, value) Private.db.profile.md.alignment = value end,
			},
		},
	}

	return tbl
end

local function MakePadding(n, character)
	local str = ""

	for i=1, n do
		str = str .. character
	end

	return str
end

local function AlignText(text, alignment, maxLength, paddingCharacter)
	alignment = alignment or "none"

	local paddingLength = maxLength - strlenutf8(text)
	local paddingLeft = paddingCharacter
	local paddingRight = paddingCharacter

	if alignment == "left" or alignment == "none" then
		paddingRight = MakePadding(paddingLength + 1, paddingCharacter)
	elseif alignment == "center" then
		paddingLength = paddingLength + 2
		local paddingLenLeft = math.floor(paddingLength/2)
		local paddingLenRight = math.floor(paddingLength/2)+paddingLength%2
		paddingLeft = MakePadding(paddingLenLeft, paddingCharacter)
		paddingRight = MakePadding(paddingLenRight, paddingCharacter)
	elseif alignment == "right" then
		paddingLeft = MakePadding(paddingLength + 1, paddingCharacter)
	end

	return paddingLeft, paddingRight
end

local function SanitizeText(text)
	text = text:gsub("([%[%]{}\\_`%|<>*#])", "\\%1")
	text = text:gsub("(%d+)%.(%s+)", "%1\\.%2")
	text = text:gsub("([%+%-]%s+)", "\\%1")
	return text
end

function Md.Export(data)
	local columns = Private.db.profile.columns
	local alignment = Private.db.profile.md.alignment
	local beautify = Private.db.profile.md.style == "beautified"
	local output = ""

	local maxLengthData = {}

	if beautify then
		for k, v in ipairs(columns) do
			if v.enabled then
				maxLengthData[k] = strlenutf8(v.name)
			end
		end

		for _, v in ipairs(data) do
			for k, c in pairs(v) do
				if type(c) == "string" then
					c = SanitizeText(c)
				end

				if strlenutf8(tostring(c)) > maxLengthData[k] then
					maxLengthData[k] = strlenutf8(tostring(c))
				end
			end
		end
	end

	-- Header
	do
		local line1 = ""
		local line2 = ""
		for k, v in ipairs(columns) do
			if v.enabled then

				if beautify then
					local paddingLeft, paddingRight = AlignText(v.name, alignment, maxLengthData[k], " ")
					line1 = string.format("%s%s%s%s|", line1, paddingLeft, v.name, paddingRight)
				else
					line1 = string.format("%s%s|", line1, v.name)
				end

				local leftAligmentMark = (alignment == "left" or alignment == "center") and ":" or (beautify and "-" or "")
				local rightAligmentMark = (alignment == "right" or alignment == "center") and ":" or (beautify and "-" or "")
				line2 = string.format("%s%s%s%s|", line2, leftAligmentMark, beautify and MakePadding(maxLengthData[k], "-") or "-", rightAligmentMark)
			end
		end

		output = string.format("%s%s\n", output, string.format("|%s", beautify and line1 or line1:sub(1,-2)))
		output = string.format("%s%s\n", output, string.format("|%s", beautify and line2 or line2:sub(1,-2)))
	end

	for _, v in ipairs(data) do
		local line = ""
		for k, c in pairs(v) do

			if type(c) == "string" then
				c = SanitizeText(c)
			end

			if type(c) == "boolean" or type(c) == "number" then
				c = tostring(c)
			end

			if beautify then
				local paddingLeft, paddingRight = AlignText(c, alignment, maxLengthData[k], " ")
				line = string.format("%s%s%s%s|", line, paddingLeft, c, paddingRight)
			else
				line = string.format("%s%s|", line, c)
			end
		end

		output = string.format("%s%s\n", output, string.format("|%s", beautify and line or line:sub(1,-2)))
	end

	return output:sub(1,-2)
end

Exports:RegisterExport(Md)
