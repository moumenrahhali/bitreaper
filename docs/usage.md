# BitReaper – Usage Guide

## Prerequisites

- Windows 10, Windows 11, or Windows Server 2016+
- **Run as Administrator** — BitReaper checks for elevated privileges at startup and will refuse to run without them

---

## Running the Script

1. Download or clone this repository.
2. Right-click `bitreaper.bat` → **Run as administrator**.
3. The interactive menu will appear.

Alternatively, open an elevated Command Prompt and execute:

```cmd
cd /d C:\path\to\BitReaper
bitreaper.bat
```

---

## Interactive Menu

```
 ██████╗ ██╗████████╗██████╗ ███████╗ █████╗ ██████╗ ███████╗
 ...

 BitReaper v2.0  |  Enterprise Secure Windows Data Eraser
 ================================================================
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

The header shows a **session ID** (unique to the current run), the logged-in **username**, and the **hostname** — all of which appear in every audit log entry.

---

## Option 1 — Securely Delete a File

**What it does:**

1. Prompts for the full file path.
2. Verifies the file exists and is not a directory.
3. Displays the file size before prompting for confirmation.
4. Warns if the target is on a network path (cipher /w effectiveness is not guaranteed on remote drives).
5. Deletes the file with `del /f /q`.
6. Runs `cipher /w` on the parent directory to overwrite freed sectors (3-pass: zeros, ones, random).

**Example session:**

```
Enter full path to the file: C:\Users\Alice\Documents\secret.docx

Target: C:\Users\Alice\Documents\secret.docx
Size  : 45312 bytes
Type YES to continue: YES

[+] Deleting file...
[+] Overwriting free sectors in: C:\Users\Alice\Documents\
[✓] File securely deleted: C:\Users\Alice\Documents\secret.docx
```

---

## Option 2 — Securely Delete a Folder

**What it does:**

1. Prompts for the full folder path.
2. Verifies the path is a directory (not a file) and is not a drive root.
3. Recursively deletes all files with `del /f /s /q`.
4. Removes the folder tree with `rd /s /q`.
5. Runs `cipher /w` on the parent directory to scrub freed sectors.

**Example session:**

```
Enter full path to the folder: C:\Temp\SensitiveProject

Target: C:\Temp\SensitiveProject
Type YES to continue: YES

[+] Recursively deleting files in: C:\Temp\SensitiveProject
[+] Removing folder tree...
[+] Overwriting free sectors in: C:\Temp\
[✓] Folder securely deleted: C:\Temp\SensitiveProject
```

---

## Option 3 — Wipe Free Disk Space

**What it does:**

1. Prompts for a drive letter.
2. Validates the drive exists.
3. Runs `cipher /w:<drive>:\` to overwrite all unallocated clusters with three passes (zeros, ones, random data) — consistent with DoD 5220.22-M (E).

**Example session:**

```
Enter drive letter (letter only, no colon): C

Target drive: C:
Type YES to continue: YES

[+] Overwriting free sectors on C: ...
    (This may take several minutes on large drives...)
[✓] Free space wiped on drive C:
```

> **Note:** On a large drive this operation can take 30+ minutes. The script suppresses verbose `cipher` output to keep the display clean.

---

## Option 4 — Quick Secure Cleanup

Combines Option 1 (delete a file) and Option 3 (wipe free space on the same drive) in a single workflow. The file size is displayed before the confirmation prompt.

---

## Option 5 — Full Disk Wipe (Zero-Fill Entire Disk)

**What it does:**

1. Lists all physical disks attached to the machine.
2. Identifies and protects the system disk (the disk containing Windows).
3. Prompts for the disk number to wipe.
4. Requires a double confirmation: type `YES`, then re-enter the disk number.
5. Runs `diskpart clean all` on the selected disk — this writes zeros to **every sector**, removes all partitions, and leaves the disk completely blank and unusable.

**Commands used:**

- `diskpart` with `select disk <N>` and `clean all`

**After completion:**

- The disk will have no partitions, no filesystem, and no data.
- It will appear as "Not Initialized" in Windows Disk Management.
- To reuse the disk, you must initialise it (MBR or GPT) and create new partitions.

**Example session:**

```
[ Full Disk Wipe — Zero-Fill Entire Disk ]

  Available disks:
  ─────────────────────────────────────────────────────────────

  Disk 0    Online       238 GB  0 B
  Disk 1    Online       931 GB  0 B

  ─────────────────────────────────────────────────────────────
  ⚠  Disk 0 contains your system drive (C:) and is PROTECTED.

  Enter the disk number to wipe (e.g. 1): 1

  Target: Disk 1

  ╔══════════════════════════════════════════════════════════════╗
  ║                  ⚠  FINAL WARNING  ⚠                       ║
  ...
  ╚══════════════════════════════════════════════════════════════╝

  Type YES to continue: YES

  Re-enter the disk number to confirm: 1

[+] Starting full disk wipe on Disk 1...
    Writing zeros to every sector. This may take a VERY long time
    depending on disk size (hours for large HDDs).

[✓] Full disk wipe completed on Disk 1.
    All sectors zeroed. All partitions removed.
    The disk is now blank and unusable until re-initialised.
```

> **Note:** `diskpart clean all` writes zeros to every sector. On a 1 TB HDD this can take 2–4 hours. On an SSD it will be faster but wear-levelling limitations still apply (see [security.md](security.md)).

---

## Option 6 — Delete Volume Shadow Copies (VSS)

**What it does:**

Deletes all Volume Shadow Copies (Windows "Previous Versions") for a specified drive using `vssadmin delete shadows /for=<drive>: /all /quiet`.

**Why this matters:**

Even after deleting files and wiping free space, Windows may retain previous versions of files via VSS snapshots. These snapshots can be used to restore deleted data. Option 6 removes them so that data cannot be recovered through the "Previous Versions" feature.

**Recommended workflow for maximum security:**

```
1. Delete files/folders (Option 1 or 2)
2. Delete VSS shadows for that drive (Option 6)
3. Wipe free space (Option 3)
```

**Example session:**

```
Enter drive letter (letter only, no colon): C

Target drive: C:
Type YES to continue: YES

[+] Deleting all Volume Shadow Copies on C: ...
[✓] All shadow copies deleted on C:
```

> **Note:** If no VSS snapshots exist on the drive, the operation completes without error. This is normal behaviour.

---

## Option 7 — View Audit Log

Displays the contents of the current `logs/bitreaper.log` file directly in the terminal. If rotated archive files exist (`.log.1`, `.log.2`, `.log.3`), their paths are listed at the bottom.

This option is also available from the command line:

```cmd
bitreaper.bat /view-log
```

---

## Command-Line / Silent Mode

BitReaper v2.0 supports non-interactive execution via command-line arguments, suitable for:

- Scheduled tasks (Windows Task Scheduler)
- Scripted deployment and decommissioning workflows
- IT automation pipelines

### Syntax

```cmd
bitreaper.bat /delete-file    <path>         [/confirmed]
bitreaper.bat /delete-folder  <path>         [/confirmed]
bitreaper.bat /wipe-drive     <letter>       [/confirmed]
bitreaper.bat /quick-cleanup  <path>         [/confirmed]
bitreaper.bat /full-disk      <disk-number>  [/confirmed]
bitreaper.bat /delete-vss     <letter>       [/confirmed]
bitreaper.bat /view-log
bitreaper.bat /help
```

### `/confirmed` flag

Without `/confirmed`, operations that would be destructive will fail with an error in CLI mode. Adding `/confirmed` skips the interactive `YES` prompt.

> ⚠️ **Caution:** `/confirmed` bypasses the safety gate. Use it only in controlled, scripted environments where the target has already been verified.

### Exit codes

| Code | Meaning |
|---|---|
| `0` | Operation completed successfully |
| `1` | Operation failed or was refused (invalid path, not admin, missing `/confirmed`, etc.) |

### Examples

```cmd
:: Securely delete a file (no prompt)
bitreaper.bat /delete-file "C:\Temp\dump.bin" /confirmed

:: Wipe free space on D: (no prompt)
bitreaper.bat /wipe-drive D /confirmed

:: VSS cleanup + free-space wipe on C: (scripted pipeline)
bitreaper.bat /delete-vss C /confirmed
bitreaper.bat /wipe-drive C /confirmed

:: Full disk wipe on Disk 2 (requires /confirmed)
bitreaper.bat /full-disk 2 /confirmed

:: View the audit log
bitreaper.bat /view-log
```

---

## Logging

All operations are recorded in `logs/bitreaper.log` inside the script directory.

**Log format (v2.0):**

```
[2025-06-01 09:12:05] SESSION="4f3a9c01" USER="Alice" ACTION="SESSION_START" TARGET="User=Alice Host=WORKSTATION01"
[2025-06-01 09:12:18] SESSION="4f3a9c01" USER="Alice" ACTION="SECURE_DELETE_FILE" TARGET="C:\Users\Alice\secret.docx"
[2025-06-01 09:15:44] SESSION="4f3a9c01" USER="Alice" ACTION="WIPE_FREE_SPACE" TARGET="C:"
[2025-06-01 09:15:50] SESSION="4f3a9c01" USER="Alice" ACTION="SESSION_END" TARGET="N/A"
```

Each entry includes:
- **Timestamp** — local date/time from the OS
- **SESSION** — 8-digit ID unique to the current run (for correlating multi-step operations)
- **USER** — Windows username running the script
- **ACTION** — what was performed (see table below)
- **TARGET** — the affected file, folder, drive, or disk

**Log rotation:** When `bitreaper.log` exceeds **1 MB**, it is automatically renamed to `bitreaper.log.1` before a fresh file is started. Up to three rotated archives are kept (`.log.1`, `.log.2`, `.log.3`).

### Action codes

| ACTION | Meaning |
|---|---|
| `SESSION_START` | Script launched |
| `SESSION_END` | Script exited via the Exit menu option |
| `SECURE_DELETE_FILE` | File successfully deleted and free space overwritten |
| `SECURE_DELETE_FILE_FAILED` | `del` could not remove the file |
| `SECURE_DELETE_FILE_ERROR` | Validation error (not found, is a directory, no path) |
| `SECURE_DELETE_FOLDER` | Folder successfully deleted and free space overwritten |
| `SECURE_DELETE_FOLDER_PARTIAL` | Folder removed but some locked files may remain |
| `SECURE_DELETE_FOLDER_ERROR` | Validation error |
| `WIPE_FREE_SPACE` | `cipher /w` completed for the drive |
| `WIPE_FREE_SPACE_ERROR` | Validation error (invalid letter, drive not found) |
| `QUICK_CLEANUP` | File deleted and drive free space wiped |
| `QUICK_CLEANUP_FAILED` | `del` could not remove the file |
| `QUICK_CLEANUP_ERROR` | Validation error |
| `FULL_DISK_WIPE_START` | `diskpart clean all` started |
| `FULL_DISK_WIPE_COMPLETE` | `diskpart clean all` completed successfully |
| `FULL_DISK_WIPE_FAILED` | `diskpart` returned a non-zero exit code |
| `FULL_DISK_WIPE_REFUSED` | Attempted to wipe the system disk |
| `FULL_DISK_WIPE_ERROR` | Validation error |
| `DELETE_VSS` | All VSS shadows deleted for the drive |
| `DELETE_VSS_NONE_OR_FAILED` | No shadows found or `vssadmin` returned non-zero |
| `DELETE_VSS_ERROR` | Validation error |

---

## See Also

- [Security notes](security.md) — how `cipher /w` works, SSD limitations, and recommendations.
- [Example usage](../examples/example_usage.txt) — copy-pasteable command sequences.

