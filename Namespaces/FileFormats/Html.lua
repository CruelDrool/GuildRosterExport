---@class Private
local Private = select(2, ...)

---@class Debug
local Debug = Private.Debug

---@class Exports
local Exports = Private.Exports

---@class Html
local Html = {}

local function getTabSub(n)
	local str = ""

	for i=1, n do
		str = str .. " "
	end

	return str
end

function Html:Export(data)
	local columns = Private.db.profile.columns
	local indentationStyle = Private.db.profile.indentation.style
	local indentationDepth = Private.db.profile.indentation.depth
	local header = Private.db.profile.html.tableHeader
	local beautify = Private.db.profile.html.style == "beautified"
	local compact = Private.db.profile.html.style == "compacted"
	local minify = Private.db.profile.html.style == "minified"
	local wp = Private.db.profile.html.wp.enabled
	local wpStripedStyle = Private.db.profile.html.wp.stripedStyle
	local wpFixedWidth = Private.db.profile.html.wp.fixedWidth
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

Exports:RegisterExport("html", "HTML", Html, "Export")
