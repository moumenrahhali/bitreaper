# BitReaper – Usage Guide

## Prerequisites

- Windows 10, Windows 11, or Windows Server 2016+
- **Run as Administrator** — required for `cipher /w` to overwrite all free sectors

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
 ██╔══██╗██║╚══██╔══╝██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝
 ██████╔╝██║   ██║   ██████╔╝█████╗  ███████║██████╔╝█████╗
 ██╔══██╗██║   ██║   ██╔══██╗██╔══╝  ██╔══██║██╔══██╗██╔══╝
 ██████╔╝██║   ██║   ██║  ██║███████╗██║  ██║██║  ██║███████╗
 ╚═════╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝

 BitReaper v1.0  |  Secure Windows Data Eraser
 ================================================================

  Select an operation:

   1 -  Securely delete a file
   2 -  Securely delete a folder
   3 -  Wipe free disk space
   4 -  Quick secure cleanup (file + free space)
   5 -  Exit
```

---

## Option 1 — Securely Delete a File

**What it does:**

1. Prompts for the full file path.
2. Verifies the file exists.
3. Deletes the file with `del /f /q`.
4. Runs `cipher /w` on the parent directory to overwrite freed sectors.

**Example session:**

```
Enter full path to the file: C:\Users\Alice\Documents\secret.docx

Target: C:\Users\Alice\Documents\secret.docx
Type YES to continue: YES

[+] Deleting file...
[+] Overwriting free sectors in: C:\Users\Alice\Documents\
[✓] File securely deleted: C:\Users\Alice\Documents\secret.docx
```

---

## Option 2 — Securely Delete a Folder

**What it does:**

1. Prompts for the full folder path.
2. Recursively deletes all files with `del /f /s /q`.
3. Removes the folder tree with `rd /s /q`.
4. Runs `cipher /w` on the parent directory to scrub freed sectors.

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
2. Runs `cipher /w:<drive>:\` to overwrite all unallocated clusters with three passes (zeros, ones, random data).

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

Combines Option 1 (delete a file) and Option 3 (wipe free space on the same drive) in a single workflow.

---

## Logging

All operations are recorded in `logs/bitreaper.log` inside the script directory:

```
[2024-05-20 14:33:01] ACTION="SECURE_DELETE_FILE" TARGET="C:\Users\Alice\secret.docx"
[2024-05-20 14:38:44] ACTION="WIPE_FREE_SPACE"    TARGET="C:"
[2024-05-20 14:39:02] ACTION="EXIT"               TARGET="N/A"
```

The `logs/` folder is tracked by Git (via `.gitkeep`) but log file contents are excluded by `.gitignore`.

---

## Screenshots

> _Screenshots will be added in a future release._

---

## See Also

- [Security notes](security.md) — how `cipher /w` works and its limitations.
- [Example usage](../examples/example_usage.txt) — copy-pasteable command sequences.
