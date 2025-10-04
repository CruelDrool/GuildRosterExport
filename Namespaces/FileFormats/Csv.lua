---@class Private
local Private = select(2, ...)

---@class Debug
local Debug = Private.Debug

---@class Exports
local Exports = Private.Exports

---@class Csv
local Csv = {}

function Csv:Export(data)
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


Exports:RegisterExport("csv", "CSV", Csv, "Export")
