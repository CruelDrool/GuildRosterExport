---@class Private
local Private = select(2, ...)

---@class Debug
local Debug = Private.Debug

---@class Exports
local Exports = Private.Exports

---@class Json
local Json = {}

local function getTabSub(n)
	local str = ""

	for i=1, n do
		str = str .. " "
	end

	return str
end

function Json:Export(data)
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
		local tabSub = getTabSub(indentationDepth)
		output = output:gsub("\t", tabSub)
	end

	return output
end

Exports:RegisterExport("json", "JSON", Json, "Export")
