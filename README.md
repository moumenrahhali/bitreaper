# BitReaper – Enterprise Windows Secure Disk Eraser

BitReaper is a Windows batch (`.bat`) utility that securely deletes files and wipes disk space using built-in system commands. It helps prevent recovery of sensitive data by overwriting storage sectors. No installation required — run as Administrator for immediate data sanitisation.

```
 ██████╗ ██╗████████╗██████╗ ███████╗ █████╗ ██████╗ ███████╗██████╗ 
 ██╔══██╗██║╚══██╔══╝██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔══██╗
 ██████╔╝██║   ██║   ██████╔╝█████╗  ███████║██████╔╝█████╗  ██████╔╝
 ██╔══██╗██║   ██║   ██╔══██╗██╔══╝  ██╔══██║██╔═══╝ ██╔══╝  ██╔══██╗
 ██████╔╝██║   ██║   ██║  ██║███████╗██║  ██║██║     ███████╗██║  ██║
 ╚═════╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝
```

---

## Features

| Feature | Description |
|---|---|
| 🛂 Admin privilege check | Refuses to start without elevated rights; no silent partial-failure |
| 🗑️ Secure file delete | Zero-fill file content, then delete and overwrite freed sectors |
| 📁 Secure folder delete | Per-file zero-fill, then recursively wipe the folder and scrub freed space |
| 💿 Free space wipe | Lists available drives; overwrites all unallocated clusters on any drive (DoD 3-pass via `cipher /w`) |
| ⚡ Quick cleanup | Zero-fill a file, delete it, and wipe the drive's free space in one step |
| 💀 Full disk wipe | Zero-fill every sector on a disk and remove all partitions |
| 👻 VSS shadow deletion | Lists available drives; deletes all Volume Shadow Copies (Previous Versions) for a drive |
| 📋 Structured audit log | Every action is timestamped with session ID, username, and hostname |
| 🔄 Log rotation | Log file auto-rotates to `.log.1/.2/.3` when it exceeds 1 MB |
| 👁️ Log viewer | View the current audit log from within the tool |
| 📤 Log export | Copy the audit log to any path via `/export-log` |
| 📊 Session summary | Exit screen shows operations completed, session ID, and log path |
| 🤖 CLI / silent mode | Scriptable command-line arguments for automation and scheduled tasks |
| 🛡️ Safety prompts | Mandatory `YES` confirmation; full disk wipe has double confirmation |
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

> **Administrator privileges are required.** BitReaper checks for elevation at startup and exits with a clear error if not running as Administrator.

---

## Interactive Usage

Launch the script and select from the menu:

```
  Session: 4f3a9c01   User: Alice   Host: WORKSTATION01
  ================================================================

   Select an operation:

   1 -  Securely delete a file
   2 -  Securely delete a folder
   3 -  Wipe free disk space
   4 -  Quick secure cleanup (file + free space)
   5 -  Full disk wipe (zero-fill entire disk)
   6 -  Delete Volume Shadow Copies (VSS)
   7 -  View audit log
   8 -  Exit
```

For detailed walkthroughs see [docs/usage.md](docs/usage.md) and [examples/example_usage.txt](examples/example_usage.txt).

---

## Command-Line / Silent Mode

BitReaper v2.1 supports command-line arguments for scripted and automated use:

```cmd
bitreaper.bat /delete-file    <path>         [/confirmed]
bitreaper.bat /delete-folder  <path>         [/confirmed]
bitreaper.bat /wipe-drive     <letter>       [/confirmed]
bitreaper.bat /quick-cleanup  <path>         [/confirmed]
bitreaper.bat /full-disk      <disk-number>  [/confirmed]
bitreaper.bat /delete-vss     <letter>       [/confirmed]
bitreaper.bat /view-log
bitreaper.bat /export-log     <destination>
bitreaper.bat /help
```

The `/confirmed` flag skips the interactive `YES` prompt — intended for scripted and scheduled-task use. All operations still require Administrator privileges.

**Examples:**

```cmd
:: Delete a file without prompting (scripted)
bitreaper.bat /delete-file "C:\Temp\secret.txt" /confirmed

:: Wipe free space on D: without prompting
bitreaper.bat /wipe-drive D /confirmed

:: Delete VSS snapshots on C: before wiping free space
bitreaper.bat /delete-vss C /confirmed
bitreaper.bat /wipe-drive C /confirmed

:: Full disk wipe from a script (requires /confirmed)
bitreaper.bat /full-disk 2 /confirmed

:: Export the audit log to a network share
bitreaper.bat /export-log "\\server\compliance\bitreaper-audit.log"
```

---

## Audit Log

All operations are recorded in `logs/bitreaper.log` inside the script directory.

**v2.1 log format includes session ID, username, and hostname:**

```
[2025-06-01 09:12:05] SESSION="4f3a9c01" USER="Alice" ACTION="SESSION_START" TARGET="User=Alice Host=WORKSTATION01"
[2025-06-01 09:12:18] SESSION="4f3a9c01" USER="Alice" ACTION="SECURE_DELETE_FILE" TARGET="C:\Users\Alice\secret.docx"
[2025-06-01 09:15:44] SESSION="4f3a9c01" USER="Alice" ACTION="WIPE_FREE_SPACE" TARGET="C:"
[2025-06-01 09:15:50] SESSION="4f3a9c01" USER="Alice" ACTION="SESSION_END" TARGET="Actions=2"
```

**Log rotation:** When `bitreaper.log` exceeds **1 MB**, it is automatically renamed to `bitreaper.log.1` (up to `.log.3` archived copies) and a fresh log file is started.

The `logs/` folder is tracked by Git (via `.gitkeep`) but log file contents are excluded by `.gitignore`.

---

## Commands Used

BitReaper relies exclusively on **native Windows utilities** — no external dependencies:

| Command | Purpose |
|---|---|
| `net session` | Verify Administrator privileges at startup |
| `cipher /w` | Overwrite unallocated clusters (3-pass: zeros, ones, random) |
| `diskpart clean all` | Write zeros to every sector on a disk, removing all partitions |
| `vssadmin delete shadows` | Delete all Volume Shadow Copies for a drive |
| `del /f /q` | Force-delete a file without prompting |
| `del /f /s /q` | Recursively force-delete files in a folder |
| `rd /s /q` | Remove a folder tree silently |
| `powershell` | Zero-fill file contents before deletion (pre-wipe step) |
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
- **VSS snapshots:** Volume Shadow Copies are not deleted automatically by Options 1–4. Use **Option 6** to remove them before wiping free space. Option 5 removes all partitions and therefore all snapshots.
- **System disk protection:** Option 5 will not wipe the disk containing the Windows system drive.

---

## Repository Structure

```
BitReaper/
├── bitreaper.bat          ← Main script (v2.1)
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


