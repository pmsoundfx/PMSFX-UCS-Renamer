# PMSFX UCS Renamer

Professional macOS tool for batch renaming sound effects files with Universal Category System (UCS) metadata.

## Features

- Right-click integration in Finder
- Smart number padding (auto-adjusts: 001, 0001, 00001)
- Remembers author and library settings
- 82 categories, 750+ subcategories
- Space handling options
- Duplicate protection

## Installation

Full installation guide and download: https://www.pmsfx.com/l/renamer

## Requirements

- macOS 11 Big Sur or newer
- Python 3 (install via `xcode-select --install`)

## Quick Start

1. Install Python 3 if needed
2. Create folder: `~/PMSFX_Renamer`
3. Place `ucs_categories.json` in that folder
4. Set up Automator Quick Action with the AppleScript code
5. Right-click audio files in Finder → Quick Actions → Rename with PMSFX UCS

## Output Format
```
CatID_SoundName###_Author_Library.wav
```

Example: `AMBForst_ThunderCrack001_PMSFX_MtnStorms.wav`

## License

Free for personal and commercial use.

Created by Phil Michalski @ PMSFX
