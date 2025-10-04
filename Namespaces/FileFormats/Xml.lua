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

---@class Xml
local Xml = {
	fileFormat = "xml",
	displayName = "XML", -- Untranslated display name.
	defaults = {
		rootElementName = "GuildRoster",
		recordElementName = "Character",
		style = "compacted",
	},
}

local L = Translate:GetLocaleEntries()

---@param order number
---@return table
function Xml.GetOptions(order)
	local tbl = {
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
				get = function() return Private.db.profile.xml.rootElementName end,
				set = function(info, value) if value ~= "" then Private.db.profile.xml.rootElementName = value end end,
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
				get = function() return Private.db.profile.xml.recordElementName end,
				set = function(info, value) if value ~= "" then Private.db.profile.xml.recordElementName = value end end,
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
				get = function() return Private.db.profile.xml.style end,
				set = function(info, value) Private.db.profile.xml.style = value end,
			},
		},
	}

	return tbl
end

function Xml.Export(data)
	local columns = Private.db.profile.columns
	local indentationStyle = Private.db.profile.indentation.style
	local indentationDepth = Private.db.profile.indentation.depth
	local rootElementName = Private.db.profile.xml.rootElementName
	local recordElementName = Private.db.profile.xml.recordElementName
	local beautify = Private.db.profile.xml.style == "beautified"
	local compact = Private.db.profile.xml.style == "compacted"
	local minify = Private.db.profile.xml.style == "minified"
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
		local tabSub = Utils.GetTabSub(indentationDepth)
		output = output:gsub("\t", tabSub)
	end

	return output
end

Exports:RegisterExport(Xml)
