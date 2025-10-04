---@class Private
local Private = select(2, ...)

---@class Debug
local Debug = Private.Debug

---@class Exports
local Exports = Private.Exports

---@class Xml
local Xml = {}

local function getTabSub(n)
	local str = ""

	for i=1, n do
		str = str .. " "
	end

	return str
end

function Xml:Export(data)
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
		local tabSub = getTabSub(indentationDepth)
		output = output:gsub("\t", tabSub)
	end

	return output
end

Exports:RegisterExport("xml", "XML", Xml, "Export")
