# Lightroom Directory Tree Publisher

A plug-in for **Lightroom Classic** that publishes photos to a local directory while preserving the original folder structure from your catalog.

## Features

- **Preserves Directory Structure**: Photos are published to the destination folder maintaining the same folder hierarchy as in your Lightroom catalog
- **Incremental Publishing**: Only new or modified photos are processed during publish operations
- **Smart Path Handling**: Works with both Windows backslash (`\`) and Unix forward slash (`/`) paths
- **Delete Support**: Removing photos from a published collection moves them to the system trash
- **Browse Dialogs**: Easy folder selection with native browse dialogs for source and destination directories

## Installation

1. Download a zip file from [GitHub Releases](https://github.com/CameronEllum/lightroom-directory-tree-publisher/releases) and extract it
2. Copy the **DirectoryTreePublisher.lrplugin** folder to one of these locations:
   - **Windows**: `C:\Program Files\Adobe\Adobe Lightroom Classic\`
   - **macOS**: `/Applications/Adobe Lightroom Classic/`
   - Or add the plugin from **File → Plug-in Manager** in Lightroom
3. Set up this plug-in as a Publish Service in  **File → Publish Services → Set Up...**

## Usage

1. In the Publish Services panel, click **Set Up...** on DirectoryTreePublisher
2. Configure the **Source root folder** (the common parent of your catalog photos)
3. Configure the **Destination folder** (where published photos will be saved)
4. Create a published collection and drag photos into it
5. Click **Publish** to export photos maintaining the folder structure

![Configuration Screenshot](./doc/Screenshot%202023-12-17%20151616.png)

### Example

If your photos are organized as:
```
D:/Photos/2023/January/photo1.jpg
D:/Photos/2023/February/photo2.jpg
```

With source root `D:/Photos` and destination `E:/Backup`, they will be published as:
```
E:/Backup/2023/January/photo1.jpg
E:/Backup/2023/February/photo2.jpg
```

## Running Tests

This plugin includes unit tests for the utility functions. To run the tests:

### Prerequisites

- [Lua](https://www.lua.org/download.html) interpreter installed (version 5.1 or later)

### Running Tests

```bash
cd DirectoryTreePublisher.lrplugin/tests
lua test_utils.lua
```

Expected output:
```
=== Testing longestCommonRoot ===

[PASS] nil input returns empty string
[PASS] empty array returns empty string
... (more tests)

=== Test Summary ===
Passed: 13
Failed: 0
Total:  13

All tests passed!
```

## Troubleshooting

### Finding the Log File

The plugin writes logs to help diagnose issues. Log files are located at:

- **Windows**: `%USERPROFILE%\Documents\LrClassicLogs\DirectoryTreePublisher.log`
  - Example: `C:\Users\YourName\Documents\LrClassicLogs\DirectoryTreePublisher.log`
- **macOS**: `~/Documents/LrClassicLogs/DirectoryTreePublisher.log`

### Common Issues

| Issue | Solution |
|-------|----------|
| **Photos not appearing in destination** | Verify the source root folder is a parent of all photos being published |
| **"Copy failed" in logs** | Check that the destination folder exists and you have write permissions |
| **Plugin not appearing in Lightroom** | Ensure the `.lrplugin` folder is in the correct location or add it via Plug-in Manager |
| **Wrong folder structure in destination** | The source root should be the common ancestor of all photos you want to publish |

### Enabling Verbose Logging

To enable more detailed logging, edit `Logger.lua` and change:
```lua
Logger.level = 0  -- Set to 0 for ALL, 1 for TRACE, 2 for INFO, etc.
```

## Development

This plugin is built against Lightroom SDK 12.0. The SDK is not included in this repository but can be downloaded from Adobe.

## Credits

- Image-folder icon by popcornarts from [Flaticon](https://www.flaticon.com/free-icons/image-folder): https://www.flaticon.com/free-icon/image_11538226

## License

See [LICENSE](LICENSE) file for details.

---

**Use at your own risk.** Always maintain backups of your photos.
