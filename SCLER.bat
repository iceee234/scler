@echo off
chcp 65001 >nul
:: SCLER v1.13

if /i "%~1"=="-?" goto :help
if /i "%~1"=="-h" goto :help
if /i "%~1"=="--help" goto :help
goto :main

:help
cls
echo =======================================================================================================
echo SCLER - SC Localization Enhancer Russian v1.13
echo =======================================================================================================
echo.
echo Usage: SCLER_1.13.bat [source_file] [options]
echo.
echo   source_file     - Path to global.ini (optional, see documentation for search order)
echo.
echo Options:
echo   -s, --skip      - Skip main stages, apply only user notes and user dictionary
echo   -p, --path      - Pick new global.ini via file dialog and save to config
echo   -r, --restore   - Restore global.ini from backup: global.ini.noblueprints.bak
echo   -?, -h, --help  - Show this help
echo.
echo Description:
echo   Adds blueprint information to mission titles and descriptions based on contracts.ini.
echo   Adds guidance type (CS/EM/IR) to missile/torpedo names from ordnance.ini.
echo   Optionally adds color tags to specified commodity items.
echo   Adds Reputation Awarded and Scenario Progress Points information.
echo   Optionally adds user notes from user_notes.ini.
echo.
echo   Replacement files are downloaded from https://github.com/MrKraken/StarStrings
echo.
echo   Creates a backup (global.ini.noblueprints.bak) only when changes are made.
echo.
echo   The script is configured via an external file SCLER.cfg (created on first run).
echo   PowerShell logic is in scler.ps1 (must be in the same folder).
echo   Translation tables are in scler_tables.ps1 (must be in the same folder).
echo.
echo Examples:
echo   SCLER_1.13.bat
echo   SCLER_1.13.bat "D:\Games\RSI\StarCitizen\LIVE\data\Localization\korean_(south_korea)\global.ini"
echo.
echo Author: iceee23
echo Email: dhhq2h9bkry3@mail.ru
echo Version: 1.13 (2026-07-20)
echo =======================================================================================================
pause
exit /b

:main
setlocal enabledelayedexpansion

set "RESTORE_MODE=0"
set "CUSTOM_ONLY=0"
set "PICK_PATH=0"
set "SOURCE_PATH="

:: Check %1 for key
if /i "%~1"=="-s"      set "CUSTOM_ONLY=1"
if /i "%~1"=="--skip"  set "CUSTOM_ONLY=1"
if /i "%~1"=="-p"      set "PICK_PATH=1"
if /i "%~1"=="--path"  set "PICK_PATH=1"
if /i "%~1"=="-r"      set "RESTORE_MODE=1"
if /i "%~1"=="--restore" set "RESTORE_MODE=1"

:: If %1 was -s or -r, %2 is the path (check it exists)
if "%CUSTOM_ONLY%"=="1" if not "%~2"=="" (
    if exist "%~f2" (
        set "SOURCE_PATH=%~f2"
    ) else (
        echo.
        echo Error: File not found: %~2
        pause
        exit /b 1
    )
)
if "%RESTORE_MODE%"=="1" if not "%~2"=="" (
    if exist "%~f2" (
        set "SOURCE_PATH=%~f2"
    ) else (
        echo.
        echo Error: File not found: %~2
        pause
        exit /b 1
    )
)

:: If no key detected, %1 might be a path
if not defined SOURCE_PATH if not "%~1"=="" (
    set "FIRST_CHAR=%~1"
    set "FIRST_CHAR=!FIRST_CHAR:~0,1!"
    if "!FIRST_CHAR!" neq "-" set "SOURCE_PATH=%~f1"
)

powershell -? >nul 2>&1 || (
    echo.
    echo Error: PowerShell is required. This script cannot run without it.
    pause
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not exist "!SCRIPT_DIR!\scler.ps1" (
    echo.
    echo Error: scler.ps1 not found. Please reinstall the program.
    pause
    exit /b 1
)

set "CONFIG_FILE=!SCRIPT_DIR!\SCLER.cfg"

if "%RESTORE_MODE%"=="1" goto :skip_config

:: ---------- Config processing ----------
if not exist "!CONFIG_FILE!" (
    echo Creating default configuration file...
    chcp 1251 >nul
    (
        echo # SCLER - user configuration file
        echo.
        echo # Reputation Awarded tag addition ^(1 = enabled, 0 = disabled^)
        echo USE_RP_AWARD_TAG=0
        echo # Scenario Progress Points tag addition ^(1 = enabled, 0 = disabled^)
        echo USE_SPP_TAG=0
        echo # Commodity color tags ^(1 = enabled, 0 = disabled^)
        echo USE_COLOR_TAGS=1
        echo # User notes addition ^(1 = enabled, 0 = disabled^)
        echo USE_USER_NOTES=0
        echo # User dictionary replacements ^(1 = enabled, 0 = disabled^)
        echo USE_USER_DICT=0
        echo.
        echo # Commodity color words ^(semicolon-separated^)
        echo # Known commodity words: Adult; Apex; Grade A; Grade AA; Grade AAA; Grade B; Grade C; Juvenile; Ore; Pure; R; Raw;
        echo COLOR_TAGS_BLUE=
        echo COLOR_TAGS_GREEN=Grade AAA;
        echo COLOR_TAGS_YELLOW=
        echo COLOR_TAGS_RED=Pure;
        echo.
        echo # Cargo titles enrichment ^(1 = enabled, 0 = disabled^)
        echo USE_CARGO_TITLES=1
        echo.
        echo # Cargo title format:
        echo # 1 ^= Direction ^| Rank ^| Haul        ^(default^)
        echo # 2 ^= Direction ^| Haul ^| Rank
        echo # 3 ^= Rank ^| Haul ^| Direction
        echo # 4 ^= Rank ^| Direction ^| Haul
        echo # 5 ^= Haul ^| Rank ^| Direction
        echo # 6 ^= Haul ^| Direction ^| Rank
        echo TITLE_FORMAT=1
        echo.
        echo # Path to global.ini file ^(full path including filename, without quotes^). Leave empty for auto-detection.
        set "EXAMPLE_PATH=D:\Games\RSI\StarCitizen\LIVE\data\Localization\korean_(south_korea)\global.ini"
        echo #   GLOBAL_INI_PATH=!EXAMPLE_PATH!
        echo GLOBAL_INI_PATH=
    ) >"!CONFIG_FILE!" 2>nul
    chcp 65001 >nul
    if errorlevel 1 (
        echo Warning: Could not create config file. Using default settings.
    )
    set "USE_RP_AWARD_TAG=0"
    set "USE_SPP_TAG=0"
    set "USE_COLOR_TAGS=1"
    set "USE_USER_NOTES=0"
    set "USE_USER_DICT=0"
    set "COLOR_TAGS_BLUE="
    set "COLOR_TAGS_GREEN=Grade AAA;"
    set "COLOR_TAGS_YELLOW="
    set "COLOR_TAGS_RED=Pure;"
    set "USE_CARGO_TITLES=1"
    set "TITLE_FORMAT=1"
    set "CFG_GLOBAL_INI_PATH="
    goto :config_done
)

:: Read existing config
chcp 1251 >nul
set "CFG_USE_RP_AWARD_TAG="
set "CFG_USE_SPP_TAG="
set "CFG_USE_COLOR_TAGS="
set "CFG_USE_USER_NOTES="
set "CFG_USE_USER_DICT="
set "CFG_COLOR_TAGS_BLUE="
set "CFG_COLOR_TAGS_GREEN="
set "CFG_COLOR_TAGS_YELLOW="
set "CFG_COLOR_TAGS_RED="
set "CFG_USE_CARGO_TITLES="
set "CFG_TITLE_FORMAT="
set "CFG_GLOBAL_INI_PATH="

for /f "usebackq tokens=1,* delims==" %%a in ("!CONFIG_FILE!") do (
    set "key=%%a"
    set "val=%%b"
    if not "!key!"=="" if not "!key:~0,1!"=="#" if not "!key:~0,1!"==";" (
        if /i "!key!"=="USE_RP_AWARD_TAG" (
            if "!val!"=="1" set "CFG_USE_RP_AWARD_TAG=1"
            if "!val!"=="0" set "CFG_USE_RP_AWARD_TAG=0"
        )
        if /i "!key!"=="USE_SPP_TAG" (
            if "!val!"=="1" set "CFG_USE_SPP_TAG=1"
            if "!val!"=="0" set "CFG_USE_SPP_TAG=0"
        )
        if /i "!key!"=="USE_USER_NOTES" (
            if "!val!"=="1" set "CFG_USE_USER_NOTES=1"
            if "!val!"=="0" set "CFG_USE_USER_NOTES=0"
        )
        if /i "!key!"=="USE_COLOR_TAGS" (
            if "!val!"=="1" set "CFG_USE_COLOR_TAGS=1"
            if "!val!"=="0" set "CFG_USE_COLOR_TAGS=0"
        )
        if /i "!key!"=="COLOR_TAGS_BLUE" (
            for /f "delims=" %%T in ('powershell -Command "Write-Host ('!val!'.Trim())"') do set "CFG_COLOR_TAGS_BLUE=%%T"
        )
        if /i "!key!"=="COLOR_TAGS_GREEN" (
            for /f "delims=" %%T in ('powershell -Command "Write-Host ('!val!'.Trim())"') do set "CFG_COLOR_TAGS_GREEN=%%T"
        )
        if /i "!key!"=="COLOR_TAGS_YELLOW" (
            for /f "delims=" %%T in ('powershell -Command "Write-Host ('!val!'.Trim())"') do set "CFG_COLOR_TAGS_YELLOW=%%T"
        )
        if /i "!key!"=="COLOR_TAGS_RED" (
            for /f "delims=" %%T in ('powershell -Command "Write-Host ('!val!'.Trim())"') do set "CFG_COLOR_TAGS_RED=%%T"
        )
        if /i "!key!"=="GLOBAL_INI_PATH" (
            set "CFG_GLOBAL_INI_PATH=!val!"
        )
        if /i "!key!"=="TITLE_FORMAT" (
            set "CFG_TITLE_FORMAT=!val!"
        )
        if /i "!key!"=="USE_CARGO_TITLES" (
            if "!val!"=="1" set "CFG_USE_CARGO_TITLES=1"
            if "!val!"=="0" set "CFG_USE_CARGO_TITLES=0"
        )
        if /i "!key!"=="USE_USER_DICT" (
            if "!val: =!"=="1" set "CFG_USE_USER_DICT=1"
            if "!val: =!"=="0" set "CFG_USE_USER_DICT=0"
        )
    )
)
chcp 65001 >nul

:: Add missing parameters to existing config
call :add_config_param USE_USER_NOTES 0
call :add_config_param USE_USER_DICT 0
call :add_config_param USE_CARGO_TITLES 1
call :add_config_param TITLE_FORMAT 1

:: Validate and apply configuration values
if defined CFG_USE_RP_AWARD_TAG (set "USE_RP_AWARD_TAG=!CFG_USE_RP_AWARD_TAG!") else (set "USE_RP_AWARD_TAG=0")
if defined CFG_USE_SPP_TAG      (set "USE_SPP_TAG=!CFG_USE_SPP_TAG!")      else (set "USE_SPP_TAG=0")
if defined CFG_USE_USER_NOTES   (set "USE_USER_NOTES=!CFG_USE_USER_NOTES!")   else (set "USE_USER_NOTES=0")
if defined CFG_USE_COLOR_TAGS   (set "USE_COLOR_TAGS=!CFG_USE_COLOR_TAGS!")   else (set "USE_COLOR_TAGS=1")
if defined CFG_USE_USER_DICT    (set "USE_USER_DICT=!CFG_USE_USER_DICT!")    else (set "USE_USER_DICT=0")
if defined CFG_USE_CARGO_TITLES (set "USE_CARGO_TITLES=!CFG_USE_CARGO_TITLES!") else (set "USE_CARGO_TITLES=1")

:: Validate TITLE_FORMAT
if not defined CFG_TITLE_FORMAT set "CFG_TITLE_FORMAT=1"
set "TITLE_FORMAT=!CFG_TITLE_FORMAT!"
if not "!TITLE_FORMAT!"=="1" if not "!TITLE_FORMAT!"=="2" if not "!TITLE_FORMAT!"=="3" if not "!TITLE_FORMAT!"=="4" if not "!TITLE_FORMAT!"=="5" if not "!TITLE_FORMAT!"=="6" (
    echo Warning: Invalid TITLE_FORMAT value. Using default 1.
    set "TITLE_FORMAT=1"
)

:: Validate COLOR_TAGS_* length (max 64 characters)
for %%v in (BLUE GREEN YELLOW RED) do (
    if defined CFG_COLOR_TAGS_%%v (
        for /f "delims=" %%L in ('powershell -Command "Write-Host ('!CFG_COLOR_TAGS_%%v!'.Length)"') do set /a "len=%%L"
        if !len! gtr 64 (
            echo Warning: Value for COLOR_TAGS_%%v is too long. Using empty.
            set "COLOR_TAGS_%%v="
        ) else (
            set "COLOR_TAGS_%%v=!CFG_COLOR_TAGS_%%v!"
        )
    ) else (
        set "COLOR_TAGS_%%v="
    )
)

:config_done

if "%USE_RP_AWARD_TAG%"=="0" (
    echo Reputation Awarded module is disabled.
)
if "%USE_SPP_TAG%"=="0" (
    echo Scenario Progress Points module is disabled.
)
if "%USE_COLOR_TAGS%"=="0" (
    echo Color Tags module is disabled.
)
if "%USE_USER_NOTES%"=="0" (
    echo User Notes module is disabled.
)
if "%USE_USER_DICT%"=="0" (
    echo User Dict module is disabled.
)

if "%USE_USER_NOTES%"=="1" (
    if not exist "!SCRIPT_DIR!\user_notes.ini" (
        echo Warning: USE_USER_NOTES enabled but user_notes.ini not found. Disabling.
        set "USE_USER_NOTES=0"
    )
)
if "%USE_USER_DICT%"=="1" (
    if not exist "!SCRIPT_DIR!\user_dict.ini" (
        echo Warning: USE_USER_DICT enabled but user_dict.ini not found. Disabling.
        set "USE_USER_DICT=0"
    )
)

:: ---------- Find global.ini ----------
set "GLOBAL_INI="
set "SOURCE="

:: 1. Command line argument (via SOURCE_PATH)
if defined SOURCE_PATH (
    set "GLOBAL_INI=!SOURCE_PATH!"
    set "SOURCE=command line"
    goto :report_source
)

:: 2. Pick path via file dialog
if "%PICK_PATH%"=="1" goto :file_dialog

:: 3. Local config (SCLER.cfg)
if defined CFG_GLOBAL_INI_PATH (
    set "CLEAN_PATH=!CFG_GLOBAL_INI_PATH:"=!"
    for /f "tokens=*" %%s in ("!CLEAN_PATH!") do set "GLOBAL_INI=%%s"
    if "!GLOBAL_INI:~1,1!" neq ":" if "!GLOBAL_INI!" neq "" (
        set "GLOBAL_INI=!SCRIPT_DIR!\!GLOBAL_INI!"
    )
    if exist "!GLOBAL_INI!" (
        set "SOURCE=local config"
        goto :report_source
    )
)

:: 4. STAR config (star_config.cfg)
for /f "delims=" %%f in ('powershell -ExecutionPolicy Bypass -Command ^
    "try { $l = (Get-Content '%SCRIPT_DIR%\star_config.cfg' -Encoding UTF8 | Select-String '^LIVE_PATH=(.*)').Matches.Groups[1].Value.Trim(); if ($l) { Join-Path $l 'Data\Localization\korean_(south_korea)\global.ini' } else { '' } } catch { '' }"') do set "GLOBAL_INI=%%f"

if defined GLOBAL_INI (
    if not "!GLOBAL_INI!"=="" (
        if exist "!GLOBAL_INI!" (
            set "SOURCE=star_config.cfg"
            goto :report_source
        )
    )
)

:: 5. Current directory
set "GLOBAL_INI=%CD%\global.ini"
if exist "!GLOBAL_INI!" (
    set "SOURCE=local file"
    goto :report_source
)

:: 6. Script directory
set "GLOBAL_INI=%SCRIPT_DIR%\global.ini"
if exist "!GLOBAL_INI!" (
    set "SOURCE=script directory"
    goto :report_source
)

:file_dialog
:: 7. File dialog
for /f "delims=" %%f in ('powershell -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'Global.ini|global.ini'; $f.Title = 'Select global.ini'; if ($f.ShowDialog() -eq 'OK') { $f.FileName }"') do set "GLOBAL_INI=%%f"
if defined GLOBAL_INI (
    if exist "!GLOBAL_INI!" (
        set "SOURCE=file dialog"
        if defined CONFIG_FILE (
            powershell -Command "$path = '!GLOBAL_INI!'; $cfg = Get-Content '!CONFIG_FILE!' -Encoding UTF8 -Raw; $cfg = $cfg -replace '^GLOBAL_INI_PATH=.*', ('GLOBAL_INI_PATH=' + $path); [System.IO.File]::WriteAllText('!CONFIG_FILE!', $cfg, [System.Text.Encoding]::UTF8)"
        )
        goto :report_source
    )
)

echo.
echo Error: global.ini not found. Check the file path or place the file in the program folder.
pause
exit /b 1

:report_source
if "%RESTORE_MODE%"=="1" (
    set "BACKUP_FILE=!GLOBAL_INI!.noblueprints.bak"
    if not exist "!BACKUP_FILE!" (
        echo.
        echo Error: Backup file not found.
        pause
        exit /b 1
    )
    echo.
    for %%f in ("!BACKUP_FILE!") do echo Backup from: %%~tf
    echo Restore global.ini from this backup? Press Y to confirm, N to cancel.
    choice /c YN /n >nul
    if errorlevel 2 (
        echo Restore cancelled by user.
        pause
        exit /b
    )
    copy /y "!BACKUP_FILE!" "!GLOBAL_INI!"
    echo Restored global.ini from backup.
    pause
    exit /b
)

echo Using global.ini from %SOURCE%: "!GLOBAL_INI!"

:: ---------- Validate global.ini ----------
powershell -ExecutionPolicy Bypass -Command "& { if ((Get-Item -LiteralPath '%GLOBAL_INI%').Length -lt 1048576) { exit 1 } }" >nul 2>&1
if errorlevel 1 (
    echo.
    echo Error: Source file "%GLOBAL_INI%" is too small. The file may be corrupted.
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -Command "try { $f = [System.IO.File]::Open('%GLOBAL_INI%', 'Open', 'Write', 'None'); $f.Close() } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
    echo.
    echo Error: global.ini is not writable.
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -Command "& { $content = Get-Content -LiteralPath '%GLOBAL_INI%' -Encoding UTF8 -Raw; if ($content -notmatch 'Frontend_PU_Version') { exit 1 } }" >nul 2>&1
if errorlevel 1 (
    echo.
    echo Error: The file does not appear to be a valid global.ini.
    pause
    exit /b 1
)

if "%CUSTOM_ONLY%"=="1" (
    set "CONTRACTS_FILE="
    set "ORDNANCE_FILE="
    goto :skip_downloads
)

:: ---------- Download and validate contracts.ini ----------
set "URL_CONTRACTS=https://raw.githubusercontent.com/MrKraken/StarStrings/master/src/For_Tool_Creators/contracts.ini"
set "CONTRACTS_FILE=%SCRIPT_DIR%\contracts.ini"

if not exist "%CONTRACTS_FILE%" (
    echo Downloading contracts.ini...
    powershell -ExecutionPolicy Bypass -Command "& { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL_CONTRACTS%' -OutFile '%CONTRACTS_FILE%' -UseBasicParsing | Out-Null }"
    if errorlevel 1 (
        echo.
        echo Error: Failed to download contracts.ini.
        pause
        exit /b 1
    )
) else (
    echo Using contracts.ini from local file.
)

powershell -ExecutionPolicy Bypass -Command "& { if ((Get-Item -LiteralPath '%CONTRACTS_FILE%').Length -lt 10) { exit 1 } }" >nul 2>&1
if errorlevel 1 (
    echo.
    echo Error: contracts.ini is empty.
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -Command "& { $content = Get-Content -LiteralPath '%CONTRACTS_FILE%' -Encoding UTF8 -Raw; if ($content -notmatch '<EM\d>Potential Blueprints\s*</EM\d>') { exit 1 } }" >nul 2>&1
if errorlevel 1 (
    echo.
    echo Error: contracts.ini does not contain required marker.
    pause
    exit /b 1
)

:: ---------- Download and validate ordnance.ini ----------
set "URL_ORDNANCE=https://raw.githubusercontent.com/MrKraken/StarStrings/master/src/For_Tool_Creators/ordnance.ini"
set "ORDNANCE_FILE=%SCRIPT_DIR%\ordnance.ini"

if not exist "%ORDNANCE_FILE%" (
    echo Downloading ordnance.ini...
    powershell -ExecutionPolicy Bypass -Command "& { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL_ORDNANCE%' -OutFile '%ORDNANCE_FILE%' -UseBasicParsing | Out-Null }"
    if errorlevel 1 (
        echo Warning: Failed to download ordnance.ini. Ordnance module skipped.
        set "ORDNANCE_FILE="
    )
) else (
    echo Using ordnance.ini from local file.
)

if defined ORDNANCE_FILE (
    powershell -ExecutionPolicy Bypass -Command "& { if ((Get-Item -LiteralPath '%ORDNANCE_FILE%').Length -lt 10) { exit 1 } }" >nul 2>&1
    if errorlevel 1 (
        echo Warning: ordnance.ini is empty. Ordnance module skipped.
        set "ORDNANCE_FILE="
    )
)

if defined ORDNANCE_FILE (
    powershell -ExecutionPolicy Bypass -Command "if ((Get-Content -LiteralPath '%ORDNANCE_FILE%' -Encoding UTF8 -Raw) -notmatch '\[(CS|EM|IR)\d*\]') { exit 1 }" >nul 2>&1
    if errorlevel 1 (
        echo Warning: ordnance.ini does not contain required marker. Ordnance module skipped.
        set "ORDNANCE_FILE="
    )
)

:skip_downloads
:: ---------- Run scler.ps1 ----------
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\scler.ps1" -file1 "%GLOBAL_INI%" -file2 "%CONTRACTS_FILE%" -ordnancePath "%ORDNANCE_FILE%" -useColorTags %USE_COLOR_TAGS% -useRpAwardTag %USE_RP_AWARD_TAG% -useSppTag %USE_SPP_TAG% -useUserNotes %USE_USER_NOTES% -colorBlue "%COLOR_TAGS_BLUE%" -colorGreen "%COLOR_TAGS_GREEN%" -colorYellow "%COLOR_TAGS_YELLOW%" -colorRed "%COLOR_TAGS_RED%" -titleFormat "!TITLE_FORMAT!" -useCargoTitles !USE_CARGO_TITLES! -useUserDict !USE_USER_DICT! -customOnly !CUSTOM_ONLY!
if errorlevel 1 echo Error: PowerShell error occurred.

:: ---------- Cleanup ----------
if exist "%CONTRACTS_FILE%" del "%CONTRACTS_FILE%" 2>nul
if exist "%ORDNANCE_FILE%" del "%ORDNANCE_FILE%" 2>nul
echo Done.
pause
exit /b

:add_config_param
:: %1 = param name, %2 = default value
if not defined CFG_%1 (
    echo Adding %1 to existing config...
    echo %1=%2 >>"!CONFIG_FILE!"
    set "CFG_%1=%2"
)
goto :eof
