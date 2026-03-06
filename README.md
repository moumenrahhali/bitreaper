# BitReaper – Windows Secure Disk Eraser

BitReaper is a lightweight Windows batch (`.bat`) utility that securely deletes files and wipes disk space using built-in system commands. It helps prevent recovery of sensitive data by overwriting storage sectors. No installation required — simply run the script to quickly sanitize drives or remove confidential files.

```
 ██████╗ ██╗████████╗██████╗ ███████╗ █████╗ ██████╗ ███████╗
 ██╔══██╗██║╚══██╔══╝██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝
 ██████╔╝██║   ██║   ██████╔╝█████╗  ███████║██████╔╝█████╗
 ██╔══██╗██║   ██║   ██╔══██╗██╔══╝  ██╔══██║██╔══██╗██╔══╝
 ██████╔╝██║   ██║   ██║  ██║███████╗██║  ██║██║  ██║███████╗
 ╚═════╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
```

---

## Features

| Feature | Description |
|---|---|
| 🗑️ Secure file delete | Delete a single file and overwrite its freed sectors |
| 📁 Secure folder delete | Recursively wipe a folder and scrub freed space |
| 💿 Free space wipe | Overwrite all unallocated clusters on any drive |
| ⚡ Quick cleanup | Delete a file and wipe the drive's free space in one step |
| 💀 Full disk wipe | Zero-fill every sector on a disk and remove all partitions, rendering it unusable |
| 📋 Audit log | Every action is timestamped in `logs/bitreaper.log` |
| 🛡️ Safety prompts | Mandatory `YES` confirmation before any destructive action |
| 🎨 Colour output | ANSI colours on Windows 10+ terminals |

---

## Installation

No installation needed. BitReaper is a single self-contained `.bat` file.

1. **Download** or clone this repository:

   ```cmd
   git clone https://github.com/moumenrahhali/BitReaper.git
   cd BitReaper
   ```

2. **Run as Administrator** — right-click `bitreaper.bat` → **Run as administrator**

   Or from an elevated Command Prompt:

   ```cmd
   bitreaper.bat
   ```

> **Administrator privileges are required** so that `cipher /w` can access all unallocated disk clusters.

---

## Usage

Launch the script and select from the interactive menu:

```
  Select an operation:

   1 -  Securely delete a file
   2 -  Securely delete a folder
   3 -  Wipe free disk space
   4 -  Quick secure cleanup (file + free space)
   5 -  Full disk wipe (zero-fill entire disk)
   6 -  Exit
```

For detailed walkthroughs see [docs/usage.md](docs/usage.md) and [examples/example_usage.txt](examples/example_usage.txt).

---

## Commands Used

BitReaper relies exclusively on **native Windows utilities** — no external dependencies:

| Command | Purpose |
|---|---|
| `cipher /w` | Overwrite unallocated clusters (3-pass: zeros, ones, random) |
| `diskpart clean all` | Write zeros to every sector on a disk, removing all partitions |
| `del /f /q` | Force-delete a file without prompting |
| `del /f /s /q` | Recursively force-delete files in a folder |
| `rd /s /q` | Remove a folder tree silently |
| `choice` | Read a single keypress from the menu |
| `set /p` | Read user input (file/folder path, drive letter, disk number) |
| `timeout` | Brief pause between operations |

---

## Safety Warning

> ⚠️ **WARNING — All operations are irreversible.**
>
> BitReaper will permanently destroy data. Before every destructive action the script displays a confirmation prompt and requires you to type **YES** (case-insensitive) to proceed. Any other input cancels the operation and returns you to the menu.
>
> The authors accept **no responsibility** for accidental data loss. Always verify the target path before confirming.

---

## Limitations

- **SSDs:** NAND wear-levelling means `cipher /w` cannot guarantee every physical cell is overwritten. The full disk wipe (`diskpart clean all`) writes zeros sector-by-sector but SSD controllers may still retain data in remapped cells. See [docs/security.md](docs/security.md).
- **NTFS metadata:** Filenames and timestamps may persist in the MFT and change journal (applies to Options 1–4; Option 5 erases the entire disk including all metadata).
- **VSS snapshots:** Volume Shadow Copies are not deleted automatically (applies to Options 1–4; Option 5 removes all partitions and therefore all snapshots).
- **System disk protection:** Option 5 will not wipe the disk containing the Windows system drive.

---

## Repository Structure

```
BitReaper/
├── bitreaper.bat          ← Main script
├── README.md
├── LICENSE                ← MIT
├── .gitignore
├── docs/
│   ├── usage.md           ← Detailed usage guide
│   └── security.md        ← Security notes and limitations
├── logs/
│   └── .gitkeep           ← Log directory (contents ignored by Git)
└── examples/
    └── example_usage.txt  ← Copy-pasteable example sessions
```

---

## License

Released under the [MIT License](LICENSE).

