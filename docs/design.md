Mod loader
* Creates a single manifest in the game directory of what each file's hash is, what mods have been loaded, and in what order
* Manifest reflects the state of the game directory with all mods loaded
* Creates a single backup of the game's original files alongside the manifest
* Option to reset the game directory from the backup
* Detects if the game files differ from the manifest and reports that as an unregistered mod
* Option to save unregistered changes as a new mod or restore the files
* Ignores save files and disallows modification to them via mod file
* Mod file format is a zip file containing a manifest.json with the following format and GUID-named content files along with a FORMAT file which contains the format revision:
  * Id is human-readable to serve double purpose of ensuring unique-ness and helping users discover which mods they need to install as dependencies (using GUIDs would not be easy to lookup)
  * Versions are semantic to support minor fixes without breaking dependencies
  * Different types of changes can be applied and are stored with data separate from type for easier construction in a factory class
  * Original checksums are provided to verify a file is what is required before applying a patch and possibly breaking it
  * Patch files use VCDIFF: https://www.nuget.org/packages/VCDiff
  * Checksums are computed using xxHash: https://www.nuget.org/packages/System.IO.Hashing/
  * Version parsing uses semver: https://www.nuget.org/packages/Semver

{
  "formatVersion": "1.0.0", // Semantic version of the manifest format
  "id": "",        // Unique human-readable ID of the mod, independent of version - [a-zA-Z0-9-]
  "version": 0,    // The semantic version of the mod
  "metadata": {    // Mod metadata (author, description, etc)
    "website": "", // URL of the mod
    "author": {    // The mod author information
      "name": "" // Name of the author
    },
  },
  "dependencies": { // List of mods this mod requires to work
    {
      "id": "",                 // id of required mod
      "minimumVersion": "1.0.0" // The minimum required version of the mod (inclusive)
      "maximumVersion": "2.0.0" // The maximum supported version of the mod (exclusive)
    }
  },
  "changes": [ // List of ordered actions to perform when installing/uninstalling the mod
    {
      "type": "PATCH", // Type of action, in this case apply patch to existing file using VCDIFF
      "arguments": {   // Arguments to action
        "path": "DATA/foo.zzz", // Path to original game file, checked when installing to ensure it is within the game directory and not a protected file (save, loader folder, etc)
        "originalChecksum": "", // Expected xxHash checksum of the file before applying the patch to ensure pre-requisites are met
        "modifiedChecksum": "", // Expected xxHash checksum after patch is applied to ensure it applied correctly
        "content": "00000000-0000-0000-0000-000000000000", // Path to GUID-named VCDIFF file in mod zip archive
      }
    },
    {
      "type": "ADD", // Type of action, in this case create new file
      "arguments": { // Arguments to action
        "path": "DATA/bar.zzz", // Path to the game file to create, checked when installing to ensure it is within the game directory and does not add a protected file (save, loader folder, etc)
        "checksum": "", // xxHash checksum of the added file
        "content": "00000000-0000-0000-0000-000000000000", // Path to GUID-named file in mod zip archive to create
      }
    },
  ]
}

The following format is used for the game directory manifest:

{
  "formatVersion": "1.0.0", // Semantic version of the manifest format
  "installedMods": [        // Installed mods in order of installation
    {
      "id": "",
      "version": "",
    }
  ],
  "files": [                // The expected checksum of every file in the game directory with the above mods applied (excluding saves and mod folder)
    {
      "path": "DATA/foo.xxx", // Path to the file
      "checksum": ""          // xxHash checksum
    }
  ]
}

The following is the structure of the directory Rivermod adds to the game's directory:

.rivermod/
  install.json // Game install manifest
  backup/      // Backup of unmodified game files
    ...        // Game files

The following is the structure of Rivermod's appdata folder:

<app-data>/
  saves/              // Save database
    <save guid>/      // Save slot backup
      save.json       // Metadata for the save file
      MAP00.SAV       // Map save
      RIVER000.SAV    // Level save
  mods/               // Imported mods (not necessarily installed)
    <mod id>/         // Mod id folder
      <mod version>/  // Uncompressed mod folder
        manifest.json // Mod manifest
        ...           // Other mod files

Level editor
* 

Map editor
* 


Save game editor
* 
