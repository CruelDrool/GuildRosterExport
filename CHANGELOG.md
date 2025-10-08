# GuildRosterExport

## [x.y.z] - xxxx-xx-xx
[View full changelog](https://github.com/CruelDrool/GuildRosterExport/blob/master/CHANGELOG-FULL.md) | [View code](https://github.com/CruelDrool/GuildRosterExport/tree/x.y.z) | [View commits](https://github.com/CruelDrool/GuildRosterExport/compare/1.2.7...x.y.z) | [Previous releases](https://github.com/CruelDrool/GuildRosterExport/releases)

### Added
- Option "Style" for formats HTML, JSON, XML, and YAML. They can now be outputted in 3 styles. 
	- **Beautified** makes the output look really organized and easy to read but uses a lot of text characters, lines, and space. 
	- **Compacted** removes many unnecessary text characters and puts each entry in the guild roster on one line each.
	- **Minified** removes unnecessary text characters and puts everything on one single line to save the most amount of space.
- Own custom way of handling translations. Supports swapping localization.
- Ability to change the addon's localization.
- A test/preview roster for characters without a guild.
- Support for debug logging using [DebugLog](https://www.curseforge.com/wow/addons/debuglog) by [expelliarm5s](https://www.curseforge.com/members/expelliarm5s).
- Support for all locales. Localization enabled on CurseForge.
- Some guard rails around the auto-export events.
	- Limit triggering `C_GuildInfo.GuildRoster()` to only at login or when reloading UI.
	- Check that there are enough rows returned from `GetGuildRosterInfo()`.

### Changed
- Re-arranged the codebase enough to justify a bump in major version.
- Minimap icon's tooltip coloring has been updated.
- Bumped Retail interface version to 11.2.5.
- Bumped MoP Classic interface version to 5.5.1.
- Global option "Auto export" changed display name to "Automatic export". Tooltip explanation updated to add that this option requires being in a guild to work.
- "Close & Return" button changed to just "Return".
- Updated enUS localization.

### Removed
- Option "Minify" from HTML, JSON, XML, and YAML.
- AceLocale-3.0 library.
