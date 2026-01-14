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

---@class Html
local Html = {
	fileFormat = "html",
	displayName = "HTML", -- Untranslated display name.
	defaults = {
		tableHeader = true,
		style = "compacted",
		wp = {
			enabled = false,
			stripedStyle = false,
			fixedWidth = false,
		},
	}
}

local L = Translate:GetLocaleEntries()

---@param order number
---@return table
function Html.GetOptions(order)

	local beautifiedDesc = L["%s makes the output look really organized and easy to read but uses a lot of text characters, lines, and space."]:format(Utils.colors.tooltip.highlight:WrapTextInColorCode(L["Beautified"]))
	local compactedDesc = L["%s removes many unnecessary text characters and puts each entry in the guild roster on one line each."]:format(Utils.colors.tooltip.highlight:WrapTextInColorCode(L["Compacted"]))
	local minifiedDesc = L["%s removes unnecessary text characters and puts everything on one single line to save the most amount of space."]:format(Utils.colors.tooltip.highlight:WrapTextInColorCode(L["Minified"]))
	local styleDesc = ("%s\n\n%s\n\n%s"):format(beautifiedDesc, compactedDesc, minifiedDesc)

	local tbl = {
		order = order,
		type = "group",
		name = L["HTML"],
		-- guiInline = true,
		args = {
			title = {
				order = 1,
				width = "full",
				type = "description",
				fontSize = "large",
				name = L["HTML"],
			},
			spacer1 = {
				order = 2,
				width = "full",
				type = "description",
				name = "",
			},
			tableHeader = {
				order = 3,
				type = "toggle",
				width = "full",
				name = L["Table header"] ,
				desc = L["Whether or not to have the column names added to the table."],
				get = function() return Private.db.profile.html.tableHeader end,
				set = function(info, value) Private.db.profile.html.tableHeader = value end,
			},
			style = {
				order = 4,
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
				get = function() return Private.db.profile.html.style end,
				set = function(info, value) Private.db.profile.html.style = value end,
			},
			wp = {
				order = 5,
				type = "group",
				name = L["WordPress"],
				guiInline = true,
				args = {
					desc = {
						order = 1,
						type = "description",
						width = "full",
						name = L["Output as a WordPress block (Gutenberg editor)."],
					},
					enabled = {
						order = 2,
						type = "toggle",
						width = "full",
						name = L["Enabled"],
						desc = L["Only use this if you know what you're doing. It requires you to edit the post's code directly. This will also minify the HTML code."],
						get = function() return Private.db.profile.html.wp.enabled end,
						set = function(info, value) Private.db.profile.html.wp.enabled = value end,
					},
					stripedStyle = {
						order = 3,
						type = "toggle",
						width = "full",
						name = L["Striped style"],
						get = function() return Private.db.profile.html.wp.stripedStyle end,
						set = function(info, value) Private.db.profile.html.wp.stripedStyle = value end,
						-- disabled = function() return not Private.db.profile.html.wp.enabled end,
					},
					fixedWidth = {
						order = 4,
						type = "toggle",
						width = "full",
						name = L["Fixed-width table cells"],
						get = function() return Private.db.profile.html.wp.fixedWidth end,
						set = function(info, value) Private.db.profile.html.wp.fixedWidth = value end,
						-- disabled = function() return not Private.db.profile.html.wp.enabled end,
					},
				},
			},
		},
	}

	return tbl
end

function Html.Export(data)
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
		local tabSub = Utils.GetTabSub(indentationDepth)
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

Exports:RegisterExport(Html)
