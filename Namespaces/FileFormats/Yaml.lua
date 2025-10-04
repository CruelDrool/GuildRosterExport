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

---@class Yaml
local Yaml = {
	fileFormat = "yaml",
	displayName = "YAML", -- Untranslated display name.
	defaults = {
		quotationMark = "single",
		style = "compacted",
	},
}

local L = Translate:GetLocaleEntries()

---@param order number
---@return table
function Yaml.GetOptions(order)
	local tbl = {
		order = order,
		type = "group",
		name = L["YAML"],
		-- guiInline = true,
		args = {
			title = {
				order = 1,
				width = "full",
				type = "description",
				fontSize = "large",
				name = L["YAML"],
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
				get = function() return Private.db.profile.yaml.quotationMark end,
				set = function(info, value) Private.db.profile.yaml.quotationMark = value end,
			},
			style = {
				order = 4,
				type = "select",
				style = "radio",
				width = "half",
				name = L["Style"],
				values = {
					["beautified"] = L["Beautified"],
					["compacted"] = L["Compacted"],
					["minified"] = L["Minified"],
				},
				get = function() return Private.db.profile.yaml.style end,
				set = function(info, value) Private.db.profile.yaml.style = value end,
			},
		},
	}

	return tbl
end

function Yaml.Export(data)
	local columns = Private.db.profile.columns
	local quotationMark = Private.db.profile.yaml.quotationMark
	local beautify = Private.db.profile.yaml.style == "beautified"
	local compact = Private.db.profile.yaml.style == "compacted"
	local minify = Private.db.profile.yaml.style == "minified"
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

Exports:RegisterExport(Yaml)
