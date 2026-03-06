@echo off
setlocal EnableDelayedExpansion

:: ============================================================
::  BitReaper v1.1 - Secure Windows Data Eraser
::  Uses only native Windows commands (cipher, del, rd, diskpart, etc.)
::  Compatible with Windows 10, Windows 11, Windows Server
:: ============================================================

:: Initialise log directory and log file path
if not exist "logs" mkdir logs
set "LOGFILE=%~dp0logs\bitreaper.log"

:: Enable ANSI colour support (Windows 10+)
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

:: Colour codes (ANSI escape sequences)
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "CYAN=[96m"
set "WHITE=[97m"
set "BOLD=[1m"
set "RESET=[0m"

goto :main

:: ============================================================
::  HELPER: Write a timestamped entry to the log file
::  Usage: call :log_entry "ACTION" "TARGET"
:: ============================================================
:log_entry
    set "LOG_ACTION=%~1"
    set "LOG_TARGET=%~2"
    for /f "tokens=1-2 delims= " %%a in ('wmic os get localdatetime /value ^| find "="') do set "DT=%%b"
    set "TIMESTAMP=!DT:~0,4!-!DT:~4,2!-!DT:~6,2! !DT:~8,2!:!DT:~10,2!:!DT:~12,2!"
    echo [!TIMESTAMP!] ACTION="!LOG_ACTION!" TARGET="!LOG_TARGET!" >> "!LOGFILE!"
    goto :eof

:: ============================================================
::  HELPER: Print the ASCII banner
:: ============================================================
:print_banner
    cls
    echo %CYAN%
    echo  ██████╗ ██╗████████╗██████╗ ███████╗ █████╗ ██████╗ ███████╗
    echo  ██╔══██╗██║╚══██╔══╝██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝
    echo  ██████╔╝██║   ██║   ██████╔╝█████╗  ███████║██████╔╝█████╗
    echo  ██╔══██╗██║   ██║   ██╔══██╗██╔══╝  ██╔══██║██╔══██╗██╔══╝
    echo  ██████╔╝██║   ██║   ██║  ██║███████╗██║  ██║██║  ██║███████╗
    echo  ╚═════╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
    echo %RESET%
    echo  %BOLD%%WHITE%BitReaper v1.1  ^|  Secure Windows Data Eraser%RESET%
    echo  %CYAN%================================================================%RESET%
    goto :eof

:: ============================================================
::  HELPER: Safety confirmation prompt
::  Sets CONFIRMED=1 if the user types YES, else CONFIRMED=0
:: ============================================================
:safety_confirm
    echo.
    echo  %RED%╔══════════════════════════════════════════════════════════╗%RESET%
    echo  %RED%║                      ⚠  WARNING  ⚠                      ║%RESET%
    echo  %RED%║  This operation will PERMANENTLY DESTROY data.           ║%RESET%
    echo  %RED%║  This action CANNOT be undone.                           ║%RESET%
    echo  %RED%╚══════════════════════════════════════════════════════════╝%RESET%
    echo.
    set "CONFIRMED=0"
    set /p "CONFIRM=  Type YES to continue (anything else cancels): "
    if /i "!CONFIRM!"=="YES" set "CONFIRMED=1"
    goto :eof

:: ============================================================
::  MAIN MENU
:: ============================================================
:main
    call :print_banner
    echo.
    echo  %BOLD%%WHITE%  Select an operation:%RESET%
    echo.
    echo   %CYAN%1%RESET% -  Securely delete a file
    echo   %CYAN%2%RESET% -  Securely delete a folder
    echo   %CYAN%3%RESET% -  Wipe free disk space
    echo   %CYAN%4%RESET% -  Quick secure cleanup (file + free space)
    echo   %CYAN%5%RESET% -  Full disk wipe (zero-fill entire disk)
    echo   %CYAN%6%RESET% -  Exit
    echo.
    echo  %CYAN%================================================================%RESET%
    echo.
    choice /c 123456 /n /m "  Enter choice [1-6]: "
    set "MENU_CHOICE=!errorlevel!"

    if "!MENU_CHOICE!"=="1" goto :delete_file
    if "!MENU_CHOICE!"=="2" goto :delete_folder
    if "!MENU_CHOICE!"=="3" goto :wipe_space
    if "!MENU_CHOICE!"=="4" goto :quick_cleanup
    if "!MENU_CHOICE!"=="5" goto :full_disk_wipe
    if "!MENU_CHOICE!"=="6" goto :exit_tool

    goto :main

:: ============================================================
::  OPTION 1 - Secure File Delete
:: ============================================================
:delete_file
    call :print_banner
    echo.
    echo  %BOLD%%WHITE%[ Secure File Delete ]%RESET%
    echo.
    set /p "FILE_PATH=  Enter full path to the file: "

    :: Strip surrounding quotes if user included them
    set "FILE_PATH=!FILE_PATH:"=!"

    if "!FILE_PATH!"=="" (
        echo  %RED%[!] No path entered. Returning to menu.%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    if not exist "!FILE_PATH!" (
        echo.
        echo  %RED%[!] File not found: !FILE_PATH!%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    :: Ensure the path is a file, not a directory
    if exist "!FILE_PATH!\*" (
        echo.
        echo  %RED%[!] That path is a directory. Use option 2 to delete folders.%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    echo.
    echo  %YELLOW%  Target: !FILE_PATH!%RESET%
    call :safety_confirm
    if "!CONFIRMED!"=="0" (
        echo  %YELLOW%[!] Operation cancelled.%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    echo.
    :: Capture the parent directory before deletion for the cipher /w pass
    for %%F in ("!FILE_PATH!") do set "FILE_DIR=%%~dpF"

    echo  %GREEN%[+] Deleting file...%RESET%
    del /f /q "!FILE_PATH!" >nul 2>&1
    if exist "!FILE_PATH!" (
        echo  %RED%[!] Failed to delete: !FILE_PATH!%RESET%
        call :log_entry "SECURE_DELETE_FILE_FAILED" "!FILE_PATH!"
        timeout /t 3 /nobreak >nul
        goto :main
    )

    echo  %GREEN%[+] Overwriting free sectors in: !FILE_DIR!%RESET%
    echo  %YELLOW%    (This may take a while on large drives...)%RESET%
    cipher /w:"!FILE_DIR!" >nul 2>&1

    echo.
    echo  %GREEN%[✓] File securely deleted: !FILE_PATH!%RESET%
    call :log_entry "SECURE_DELETE_FILE" "!FILE_PATH!"
    echo.
    pause
    goto :main

:: ============================================================
::  OPTION 2 - Secure Folder Delete
:: ============================================================
:delete_folder
    call :print_banner
    echo.
    echo  %BOLD%%WHITE%[ Secure Folder Delete ]%RESET%
    echo.
    set /p "FOLDER_PATH=  Enter full path to the folder: "

    :: Strip surrounding quotes
    set "FOLDER_PATH=!FOLDER_PATH:"=!"

    if "!FOLDER_PATH!"=="" (
        echo  %RED%[!] No path entered. Returning to menu.%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    if not exist "!FOLDER_PATH!" (
        echo.
        echo  %RED%[!] Folder not found: !FOLDER_PATH!%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    :: Ensure path is actually a directory
    if not exist "!FOLDER_PATH!\*" (
        echo.
        echo  %RED%[!] That path is a file. Use option 1 to delete files.%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    :: Safety: prevent wiping drive root
    set "CLEANED=!FOLDER_PATH:~-1!"
    if "!CLEANED!"=="\" (
        echo.
        echo  %RED%[!] Refusing to wipe a drive root path for safety.%RESET%
        timeout /t 3 /nobreak >nul
        goto :main
    )

    echo.
    echo  %YELLOW%  Target: !FOLDER_PATH!%RESET%
    call :safety_confirm
    if "!CONFIRMED!"=="0" (
        echo  %YELLOW%[!] Operation cancelled.%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    echo.
    echo  %GREEN%[+] Recursively deleting files in: !FOLDER_PATH!%RESET%
    del /f /s /q "!FOLDER_PATH!\*" >nul 2>&1

    echo  %GREEN%[+] Removing folder tree...%RESET%
    rd /s /q "!FOLDER_PATH!" >nul 2>&1

    :: Determine parent directory for free-space wipe
    for %%D in ("!FOLDER_PATH!") do set "PARENT_DIR=%%~dpD"

    echo  %GREEN%[+] Overwriting free sectors in: !PARENT_DIR!%RESET%
    echo  %YELLOW%    (This may take a while on large drives...)%RESET%
    cipher /w:"!PARENT_DIR!" >nul 2>&1

    if exist "!FOLDER_PATH!" (
        echo  %RED%[!] Folder could not be fully removed. Some files may be in use.%RESET%
        call :log_entry "SECURE_DELETE_FOLDER_PARTIAL" "!FOLDER_PATH!"
    ) else (
        echo.
        echo  %GREEN%[✓] Folder securely deleted: !FOLDER_PATH!%RESET%
        call :log_entry "SECURE_DELETE_FOLDER" "!FOLDER_PATH!"
    )
    echo.
    pause
    goto :main

:: ============================================================
::  OPTION 3 - Wipe Free Disk Space
:: ============================================================
:wipe_space
    call :print_banner
    echo.
    echo  %BOLD%%WHITE%[ Wipe Free Disk Space ]%RESET%
    echo.
    echo  %WHITE%  Enter the drive letter you want to wipe free space on.%RESET%
    echo  %WHITE%  Example: C%RESET%
    echo.
    set /p "DRIVE_LETTER=  Drive letter (letter only, no colon): "

    :: Strip colon or backslash if user included them
    set "DRIVE_LETTER=!DRIVE_LETTER::=!"
    set "DRIVE_LETTER=!DRIVE_LETTER:\=!"

    :: Validate single letter A-Z
    echo !DRIVE_LETTER! | findstr /r "^[A-Za-z]$" >nul 2>&1
    if errorlevel 1 (
        echo.
        echo  %RED%[!] Invalid drive letter: !DRIVE_LETTER!%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    :: Check the drive actually exists
    if not exist "!DRIVE_LETTER!:\" (
        echo.
        echo  %RED%[!] Drive !DRIVE_LETTER!: does not exist or is not accessible.%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    echo.
    echo  %YELLOW%  Target drive: !DRIVE_LETTER!:%RESET%
    call :safety_confirm
    if "!CONFIRMED!"=="0" (
        echo  %YELLOW%[!] Operation cancelled.%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    echo.
    echo  %GREEN%[+] Overwriting free sectors on !DRIVE_LETTER!: ...%RESET%
    echo  %YELLOW%    (This may take several minutes on large drives...)%RESET%
    cipher /w:!DRIVE_LETTER!:\ >nul 2>&1

    echo.
    echo  %GREEN%[✓] Free space wiped on drive !DRIVE_LETTER!:%RESET%
    call :log_entry "WIPE_FREE_SPACE" "!DRIVE_LETTER!:"
    echo.
    pause
    goto :main

:: ============================================================
::  OPTION 4 - Quick Secure Cleanup (file + free space)
:: ============================================================
:quick_cleanup
    call :print_banner
    echo.
    echo  %BOLD%%WHITE%[ Quick Secure Cleanup ]%RESET%
    echo.
    echo  %WHITE%  This will securely delete a file AND wipe free space on its drive.%RESET%
    echo.
    set /p "FILE_PATH=  Enter full path to the file: "

    :: Strip surrounding quotes
    set "FILE_PATH=!FILE_PATH:"=!"

    if "!FILE_PATH!"=="" (
        echo  %RED%[!] No path entered. Returning to menu.%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    if not exist "!FILE_PATH!" (
        echo.
        echo  %RED%[!] File not found: !FILE_PATH!%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    if exist "!FILE_PATH!\*" (
        echo.
        echo  %RED%[!] That path is a directory. Use option 2 to delete folders.%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    :: Capture drive and directory before deletion
    for %%F in ("!FILE_PATH!") do (
        set "FILE_DIR=%%~dpF"
        set "DRIVE_LETTER=%%~dF"
    )
    :: Remove trailing colon from drive letter variable
    set "DRIVE_LETTER=!DRIVE_LETTER::=!"

    echo.
    echo  %YELLOW%  Target file:  !FILE_PATH!%RESET%
    echo  %YELLOW%  Target drive: !DRIVE_LETTER!:%RESET%
    call :safety_confirm
    if "!CONFIRMED!"=="0" (
        echo  %YELLOW%[!] Operation cancelled.%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    echo.
    echo  %GREEN%[+] Deleting file...%RESET%
    del /f /q "!FILE_PATH!" >nul 2>&1
    if exist "!FILE_PATH!" (
        echo  %RED%[!] Failed to delete: !FILE_PATH!%RESET%
        call :log_entry "QUICK_CLEANUP_FAILED" "!FILE_PATH!"
        timeout /t 3 /nobreak >nul
        goto :main
    )

    echo  %GREEN%[+] Overwriting free sectors on !DRIVE_LETTER!: ...%RESET%
    echo  %YELLOW%    (This may take several minutes on large drives...)%RESET%
    cipher /w:!DRIVE_LETTER!:\ >nul 2>&1

    echo.
    echo  %GREEN%[✓] Quick cleanup completed for: !FILE_PATH!%RESET%
    call :log_entry "QUICK_CLEANUP" "!FILE_PATH!"
    echo.
    pause
    goto :main

:: ============================================================
::  OPTION 5 - Full Disk Wipe (zero-fill entire disk)
::  Uses diskpart "clean all" to write zeros to every sector
::  and remove all partitions, rendering the disk unusable.
:: ============================================================
:full_disk_wipe
    call :print_banner
    echo.
    echo  %BOLD%%WHITE%[ Full Disk Wipe — Zero-Fill Entire Disk ]%RESET%
    echo.
    echo  %RED%  ╔══════════════════════════════════════════════════════════════╗%RESET%
    echo  %RED%  ║  THIS WILL DESTROY ALL DATA AND PARTITIONS ON A DISK.      ║%RESET%
    echo  %RED%  ║  The disk will be completely zeroed and left UNUSABLE       ║%RESET%
    echo  %RED%  ║  until re-initialised and formatted in Disk Management.    ║%RESET%
    echo  %RED%  ╚══════════════════════════════════════════════════════════════╝%RESET%
    echo.

    :: Identify the system disk (the disk containing the Windows boot partition)
    set "SYS_DISK="
    for /f "tokens=*" %%A in ('wmic os get SystemDrive /value 2^>nul ^| find "="') do set "%%A"
    if defined SystemDrive (
        set "SYS_DRIVE_LETTER=!SystemDrive:~0,1!"
    ) else (
        set "SYS_DRIVE_LETTER=C"
    )

    :: Resolve the system drive letter to a physical disk number to protect it
    set "SYS_DISK_NUM="
    for /f "skip=1 tokens=1,2" %%A in ('wmic path Win32_LogicalDiskToPartition get Antecedent^,Dependent 2^>nul') do (
        echo %%B | findstr /i "!SYS_DRIVE_LETTER!:" >nul 2>&1
        if not errorlevel 1 (
            for /f "tokens=2 delims=#" %%X in ("%%A") do (
                for /f "tokens=1 delims=," %%Y in ("%%X") do set "SYS_DISK_NUM=%%Y"
            )
        )
    )

    :: List available disks
    echo  %WHITE%  Available disks:%RESET%
    echo  %CYAN%  ─────────────────────────────────────────────────────────────%RESET%
    echo.
    for /f "skip=1 tokens=1-4" %%A in ('wmic diskdrive get Index^,Model^,Size^,Status /value 2^>nul ^| findstr /r "."') do (
        echo   %%A
    )
    :: Use diskpart list disk for a cleaner view
    echo.
    set "DP_LIST=%TEMP%\bitreaper_listdisk.txt"
    (echo list disk) > "!DP_LIST!"
    diskpart /s "!DP_LIST!" 2>nul | findstr /r /c:"Disk [0-9]"
    del /f /q "!DP_LIST!" >nul 2>&1
    echo.
    echo  %CYAN%  ─────────────────────────────────────────────────────────────%RESET%
    if defined SYS_DISK_NUM (
        echo  %YELLOW%  ⚠  Disk !SYS_DISK_NUM! contains your system drive (!SYS_DRIVE_LETTER!:) and is PROTECTED.%RESET%
    ) else (
        echo  %YELLOW%  ⚠  System drive: !SYS_DRIVE_LETTER!: — its disk is protected from wiping.%RESET%
    )
    echo.

    :: Prompt for disk number
    set /p "DISK_NUM=  Enter the disk number to wipe (e.g. 1): "

    :: Validate: must be a number
    echo !DISK_NUM! | findstr /r "^[0-9][0-9]*$" >nul 2>&1
    if errorlevel 1 (
        echo.
        echo  %RED%[!] Invalid disk number: !DISK_NUM!%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    :: Safety: refuse to wipe the system disk
    if defined SYS_DISK_NUM (
        if "!DISK_NUM!"=="!SYS_DISK_NUM!" (
            echo.
            echo  %RED%[!] REFUSED — Disk !DISK_NUM! contains the system drive (!SYS_DRIVE_LETTER!:).%RESET%
            echo  %RED%    Wiping the system disk is not allowed for safety.%RESET%
            timeout /t 3 /nobreak >nul
            goto :main
        )
    )

    :: First confirmation
    echo.
    echo  %YELLOW%  Target: Disk !DISK_NUM!%RESET%
    echo.
    echo  %RED%╔══════════════════════════════════════════════════════════════╗%RESET%
    echo  %RED%║                  ⚠  FINAL WARNING  ⚠                       ║%RESET%
    echo  %RED%║  ALL data on Disk !DISK_NUM! will be PERMANENTLY DESTROYED.        ║%RESET%
    echo  %RED%║  Every sector will be overwritten with zeros.               ║%RESET%
    echo  %RED%║  All partitions will be removed.                            ║%RESET%
    echo  %RED%║  The disk will be left UNUSABLE until re-initialised.       ║%RESET%
    echo  %RED%║  This action CANNOT be undone.                              ║%RESET%
    echo  %RED%╚══════════════════════════════════════════════════════════════╝%RESET%
    echo.
    set "CONFIRMED=0"
    set /p "CONFIRM=  Type YES to continue (anything else cancels): "
    if /i not "!CONFIRM!"=="YES" (
        echo  %YELLOW%[!] Operation cancelled.%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    :: Second confirmation — require the user to re-type the disk number
    echo.
    set /p "CONFIRM_NUM=  Re-enter the disk number to confirm: "
    if not "!CONFIRM_NUM!"=="!DISK_NUM!" (
        echo.
        echo  %RED%[!] Disk number does not match. Operation cancelled.%RESET%
        timeout /t 2 /nobreak >nul
        goto :main
    )

    :: Execute full disk wipe using diskpart clean all
    echo.
    echo  %GREEN%[+] Starting full disk wipe on Disk !DISK_NUM!...%RESET%
    echo  %YELLOW%    Writing zeros to every sector. This may take a VERY long time%RESET%
    echo  %YELLOW%    depending on disk size (hours for large HDDs).%RESET%
    echo.

    :: Build diskpart script
    set "DP_SCRIPT=%TEMP%\bitreaper_wipe.txt"
    (
        echo select disk !DISK_NUM!
        echo clean all
    ) > "!DP_SCRIPT!"

    call :log_entry "FULL_DISK_WIPE_START" "Disk !DISK_NUM!"

    diskpart /s "!DP_SCRIPT!" >nul 2>&1
    set "WIPE_RESULT=!errorlevel!"
    del /f /q "!DP_SCRIPT!" >nul 2>&1

    if "!WIPE_RESULT!"=="0" (
        echo.
        echo  %GREEN%[✓] Full disk wipe completed on Disk !DISK_NUM!.%RESET%
        echo  %GREEN%    All sectors zeroed. All partitions removed.%RESET%
        echo  %GREEN%    The disk is now blank and unusable until re-initialised.%RESET%
        call :log_entry "FULL_DISK_WIPE_COMPLETE" "Disk !DISK_NUM!"
    ) else (
        echo.
        echo  %RED%[!] Disk wipe may have failed or encountered errors on Disk !DISK_NUM!.%RESET%
        echo  %RED%    Check that the disk is not in use and try again.%RESET%
        call :log_entry "FULL_DISK_WIPE_FAILED" "Disk !DISK_NUM!"
    )
    echo.
    pause
    goto :main

:: ============================================================
::  EXIT
:: ============================================================
:exit_tool
    call :print_banner
    echo.
    echo  %CYAN%  Thank you for using BitReaper. Stay secure.%RESET%
    echo.
    call :log_entry "EXIT" "N/A"
    timeout /t 2 /nobreak >nul
    endlocal
    exit /b 0
