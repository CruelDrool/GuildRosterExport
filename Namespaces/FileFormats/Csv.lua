---@class Private
local Private = select(2, ...)

---@class Debug
local Debug = Private.Debug

---@class Translate
local Translate = Private.Translate

---@class Exports
local Exports = Private.Exports

---@class Csv
local Csv = {
	fileFormat = "csv",
	displayName = "CSV", -- Untranslated display name.
	defaults = {
		header = true,
		delimiter = ',',
		enclosure = '"',
	}
}

local L = Translate:GetLocaleEntries()

---@param order number
---@return table
function Csv.GetOptions(order)
	local tbl = {
		order = order,
		type = "group",
		name = L["CSV"],
		-- guiInline = true,
		args = {
			title = {
				order = 1,
				width = "full",
				type = "description",
				fontSize = "large",
				name = L["CSV"],
			},
			spacer1 = {
				order = 2,
				width = "full",
				type = "description",
				name = "",
			},
			header = {
				order = 3,
				type = "toggle",
				width = "full",
				name = L["Header"] ,
				desc = L["Whether or not to have the column names added to top of the CSV output."],
				get = function() return Private.db.profile.csv.header end,
				set = function(info, value) Private.db.profile.csv.header = value end,
			},
			enclosure = {
				order = 4,
				type = "input",
				width = "half",
				name = L["Enclosure"],
				desc = L["Text character that is used when enclosing values."],
				get = function() return Private.db.profile.csv.enclosure end,
				set = function(info, value) if value ~= "" then Private.db.profile.csv.enclosure = value end end,
			},
			spacer2 = {
				order = 5,
				width = "full",
				type = "description",
				name = "",
			},
			delimiter = {
				order = 6,
				type = "input",
				width = "half",
				name = L["Delimiter"],
				desc = L["Text character that is used when separating values."],
				get = function() return Private.db.profile.csv.delimiter end,
				set = function(info, value) if value ~= "" then Private.db.profile.csv.delimiter = value end end,
			},
		},
	}

	return tbl
end

function Csv.Export(data)
	local enclosure = Private.db.profile.csv.enclosure
	local delimiter = Private.db.profile.csv.delimiter
	local header = Private.db.profile.csv.header
	local columns = Private.db.profile.columns
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

Exports:RegisterExport(Csv)
