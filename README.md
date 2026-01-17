# Description

A small addon that focuses on exporting the in-game guild roster to various formats. Just open up the options by clicking the minimap button, select your format and do an export!

## Features

- Export all 17 columns of the guild roster, plus 2 additional ones that are specific to this addon.
- Extensive settings for how the export will be done.
- Select which columns to export.
- Custom column names.
- Able to sort the roster. Select 2 columns to sort by, and which sort order to use (ascending or descending).
- Select which guild ranks to export.
- Choose which type of indentation to use: tabs or spaces.
- Supports [minification](https://en.wikipedia.org/wiki/Minification_(programming)) for select formats.
- Automatic export to the saved variables file, for external extraction. (requires logging out/reload UI to be saved).
- Each format have their own settings.

### Supported formats
- CSV (default)
- HTML*
- JSON*
- XML*
- YAML*

\* [Minification](https://en.wikipedia.org/wiki/Minification_(programming)) available.

### Slash commands
- `/guildrosterexport` - Toggle options.
- `/guildrosterexport help` - Print help.
- `/guildrosterexport export [file format]` - Do an export. The export frame will open.

### Columns
- name*
- rankName*
- rankIndex*
- level*
- class*
- zone
- note
- officerNote
- isOnline
- status
- classFileName
- achievementPoints
- achievementRank
- isMobile
- isSoREligible
- repStandingID
- GUID
- lastOnline**
- realmName**

\* Selected by default.\
\*\* Additional columns that are specific to this addon.
