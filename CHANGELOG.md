# GuildRosterExport

## [2.2.0] - 2026-11-05
[View full changelog](https://github.com/CruelDrool/GuildRosterExport/blob/master/CHANGELOG-FULL.md) | [View code](https://github.com/CruelDrool/GuildRosterExport/tree/2.2.0) | [View commits](https://github.com/CruelDrool/GuildRosterExport/compare/2.1.5...2.2.0) | [Previous releases](https://github.com/CruelDrool/GuildRosterExport/releases)

### Fixed
- Sorting settings: dropdown values for "Primary column" and "Secondary column" will now update after column names have been changed.
- Localizations will now be sorted after their translated names.

### Added
- Support for WoW Forever.
- Export to a Markdown (MD) table.
	- Select style and column alignment.
- Support for fonts through [LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3-0).
	- Options for fonts added. Select name, size, [flags](https://warcraft.wiki.gg/wiki/API_types/TBFFlags), and color.
	- The font "Roboto Mono Regular" has been added but is only available for western languages and Russian.
	- Preview fonts using [AceGUI-3.0-SharedMediaWidgets](https://www.curseforge.com/wow/addons/ace-gui-3-0-shared-media-widgets)
- New option: "Load fonts from LibSharedMedia when logging in or reloading UI". This prevents blank entries in the dropdown for fonts.

### Changed
- Updated library LibDBIcon-1.0 to version 12.1.2 (r167)
- Updated test rosters.
- Updated enUS localization.
