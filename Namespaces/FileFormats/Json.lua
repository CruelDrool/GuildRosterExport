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

---@class Json
local Json = {
	fileFormat = "json",
	displayName = "JSON", -- Untranslated display name.
	defaults = {
		style = "compacted",
	}
}

local L = Translate:GetLocaleEntries()



---@param order number
---@return table
function Json.GetOptions(order)

	local beautifiedDesc = L["%s makes the output look really organized and easy to read but uses a lot of text characters, lines, and space."]:format(Utils.colors.tooltip.highlight:WrapTextInColorCode(L["Beautified"]))
	local compactedDesc = L["%s removes many unnecessary text characters and puts each entry in the guild roster on one line each."]:format(Utils.colors.tooltip.highlight:WrapTextInColorCode(L["Minified"]))
	local minifiedDesc = L["%s removes unnecessary text characters and puts everything on one single line to save the most amount of space."]:format(Utils.colors.tooltip.highlight:WrapTextInColorCode(L["Compacted"]))
	local styleDesc = ("%s\n\n%s\n\n%s"):format(beautifiedDesc, compactedDesc, minifiedDesc)

	local tbl = {
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
				desc = styleDesc,
				values = {
					["beautified"] = L["Beautified"],
					["compacted"] = L["Compacted"],
					["minified"] = L["Minified"],
				},
				get = function() return Private.db.profile.json.style end,
				set = function(info, value) Private.db.profile.json.style = value end,
			},
		},
	}

	return tbl
end

function Json.Export(data)
	local columns = Private.db.profile.columns
	local indentationStyle = Private.db.profile.indentation.style
	local indentationDepth = Private.db.profile.indentation.depth
	local beautify = Private.db.profile.json.style == "beautified"
	local compact = Private.db.profile.json.style == "compacted"
	local minify = Private.db.profile.json.style == "minified"
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
		local tabSub = Utils.GetTabSub(indentationDepth)
		output = output:gsub("\t", tabSub)
	end

	return output
end

Exports:RegisterExport(Json)
