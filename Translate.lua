---@class Private
local Private = select(2, ...)

---@class Debug
local Debug = Private.Debug

---@class Translate
local Translate = {}

---@alias localecode
---|"deDE": German (Germany)
---|"enGB": English (Great Britain)
---|"enUS": English (America)
---|"esES": Spanish (Spain)
---|"esMX": Spanish (Mexico)
---|"frFR" French (France)
---|"itIT": Italian (Italy)
---|"koKR": Korean (Korea)
---|"ptBR": Portuguese (Brazil)
---|"ruRU": Russian (Russia)
---|"zhCN": Simplified Chinese (China)
---|"zhTW": Traditional Chinese (Taiwan)

local isDefaulLocaleRegistered = false

-- The locale registry.
---@type table<localecode, table>
local registeredLocales = {}

---@type localecode
local gameLocale = GetLocale()
gameLocale = gameLocale == "enGB" and "enUS" or gameLocale

---@type localecode
local currentLocale = gameLocale

---Local function to handle errors.
---@param ... any
local function errorhandler(...)
	local message = format(...)
	Debug:Log(("Translate~5~ERR~%s"):format(message))
end

-- A read-only table where the entries are stored. Requesting unknown entry will just the return key.
-- The metatable will block writing entries to the locale table unless `rawset()` is used.
---@type table<string, string>
local entries = setmetatable({},{
	__index = function(self, key)-- Requesting unknown entry. Return key.
		errorhandler( "Missing entry for '%s'.", tostring(key) )
		return key
	end,
	__newindex = function(self, key, value) -- Block adding new keys. rawset() still works.
		errorhandler( "'%s' was not added. Table is read-only.", tostring(key) )
	end,
	__call = function(self, key)
		return self[key]
	end,
})

---Register the default locale.
---@param locale localecode Name of the locale to register, e.g. "enUS", "deDE", etc.
---@return table<string, boolean|string>? proxy  A write-proxy table for writing the default localization text strings to, or `nil` if the locale is already registered.
function Translate:RegisterDefaultLocale(locale)
	if isDefaulLocaleRegistered then
		errorhandler("Default locale has already been registered.")
		return
	end

	isDefaulLocaleRegistered = true

	currentLocale = locale == gameLocale and locale or currentLocale

	local localeTbl = {}
	registeredLocales[locale] = localeTbl
	local proxy = setmetatable({}, {
		__newindex = function(tbl, key, value)
			if type(key) == "string" and key ~= "" and (value == true or type(value) == "string") then
				if not rawget(entries, key) then
					rawset(entries, key, value == true and key or value)
					rawset(localeTbl, key, value == true and key or value)
				end
			end
		end,
	})

	return proxy
end

---Register non-default locales.
---@param locale localecode Name of the locale to register, e.g. "enUS", "deDE", etc.
---@return table<string, boolean|string>? proxy A write-proxy table for writing translated text strings to, or `nil` if the locale is already registered or if the default locale isn't registered.
function Translate:RegisterLocale(locale)
	if not isDefaulLocaleRegistered then
		errorhandler("Locale (%s) was not registered. Default locale has not been registered yet.", locale)
		return
	end

	if registeredLocales[locale] then
		errorhandler("Locale (%s) has already been registered.", locale)
		return
	end

	currentLocale = locale == gameLocale and locale or currentLocale

	local localeTbl = {}
	registeredLocales[locale] = localeTbl

	local proxy = setmetatable({}, {
		__newindex = function(tbl, key, value)
			if rawget(entries, key) then -- Only write when the key exists in the the default locale's table.
				rawset(localeTbl, key, value == true and key or value)
				if locale == gameLocale then
					-- Tranlate directly
					rawset(entries, key, value == true and key or value)
				end
			end
		end,
	})

	return proxy
end

---Returns localizations for the current locale (or default locale if translations are missing).
---@return table<string, string> entries The locale table for the current language.
function Translate:GetLocale()
	return entries
end

---Check if the locale is registered.
---@return boolean isRegistered True if registered, false if not.
function Translate:IsLocaleRegistered(locale)
	return registeredLocales[locale] and true
end

---Sets active locale.
---@return boolean success False if the locale isn't registered.
function Translate:SetLocale(locale)
	if not registeredLocales[locale] then return false end

	local localeTbl = registeredLocales[locale]

	for key, value in pairs(localeTbl) do
		rawset(entries, key, value )
	end

	currentLocale = locale

	return true
end

---Retrieve registered locales.
---@return table<number, string> list Table/array of registered locales
function Translate:GetRegisteredLocales()
	local list = {}
	for k in pairs(registeredLocales) do
		table.insert(list, k)
	end

	return list
end

---Retrieve the locale that is currently in use.
---@return localecode currentLocale The current locale.
function Translate:GetCurrentLocale()
	return currentLocale
end

-- Add to the addon's private namespace.
Private.Translate = setmetatable(Translate,{
	__index = function(self, key)
		return entries[key]
	end,
	__newindex = function() end,
	__call = function(self, phrase)
		return entries[phrase]
	end,
})
