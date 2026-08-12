@echo off
chcp 65001 >nul
echo SCLER v1.16

if /i "%~1"=="-?" goto :help
if /i "%~1"=="-h" goto :help
if /i "%~1"=="--help" goto :help
goto :main

:help
cls
echo =======================================================================================================
echo SCLER - SC Localization Enhancer Russian v1.16
echo =======================================================================================================
echo.
echo Usage: SCLER.bat [source_file] [options]
echo.
echo   source_file     - Path to global.ini (optional)
echo.
echo Options:
echo   -?, -h, --help  - Show this help
echo   -s, --skip      - Apply only user notes and dictionary
echo   -p, --path      - Pick global.ini via file dialog
echo   -r, --restore   - Restore global.ini from backup
echo   -u, --update    - Force update check
echo.
echo Examples:
echo   SCLER.bat
echo   SCLER.bat "D:\Games\RSI\StarCitizen\LIVE\data\Localization\korean_(south_korea)\global.ini"
echo   SCLER.bat -s
echo   SCLER.bat -r
echo.
echo Full documentation: SCLER_Documentation.txt
echo Author: iceee234
echo =======================================================================================================
pause
exit /b

:main
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "CONFIG_FILE=!SCRIPT_DIR!\SCLER.cfg"

:: Check for new updater version
if exist "!SCRIPT_DIR!\_updater_new.bat" (
    copy /y "!SCRIPT_DIR!\_updater_new.bat" "!SCRIPT_DIR!\_updater.bat" >nul
    del "!SCRIPT_DIR!\_updater_new.bat" >nul
    attrib +h "!SCRIPT_DIR!\_updater.bat" >nul 2>&1
)

set "RESTORE_MODE=0"
set "CUSTOM_ONLY=0"
set "PICK_PATH=0"
set "SOURCE_PATH="
set "FORCE_UPDATE=0"

:: Check %1 for key
if /i "%~1"=="-s"         set "CUSTOM_ONLY=1"
if /i "%~1"=="--skip"     set "CUSTOM_ONLY=1"
if /i "%~1"=="-p"         set "PICK_PATH=1"
if /i "%~1"=="--path"     set "PICK_PATH=1"
if /i "%~1"=="-r"         set "RESTORE_MODE=1"
if /i "%~1"=="--restore"  set "RESTORE_MODE=1"
if /i "%~1"=="-u"         set "FORCE_UPDATE=1"
if /i "%~1"=="--update"   set "FORCE_UPDATE=1"

:: If %1 was -s or -r, %2 is the path
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

:: ---------- Check for updates ----------
if not "%CUSTOM_ONLY%"=="0" goto :skip_update
if not "%RESTORE_MODE%"=="0" goto :skip_update

set "URL_API=https://api.github.com/repos/iceee234/scler/releases/latest"
set "URL_DOWNLOAD=https://github.com/iceee234/scler/archive/refs/tags/latest.zip"

:: Force update requested
if "!FORCE_UPDATE!"=="1" (
    powershell -Command "$cfg = Get-Content '!CONFIG_FILE!' -Encoding UTF8 -Raw; $cfg = $cfg -replace 'UPDATE_FAILED=.*', 'UPDATE_FAILED=0' -replace 'UPDATE_ATTEMPTS=.*', 'UPDATE_ATTEMPTS=0'; [System.IO.File]::WriteAllText('!CONFIG_FILE!', $cfg, [System.Text.Encoding]::UTF8)"
    echo Forced update check...
)

:: Check if update is blocked
if defined CFG_UPDATE_FAILED (
    if "!CFG_UPDATE_FAILED!"=="1" (
        echo.
        echo !!! Previous update attempts failed. Update check skipped.
        echo !!! Run SCLER.bat -u to force update check.
        echo.
        goto :skip_update
    )
)

:: Check for pending update
if exist "!SCRIPT_DIR!\update.zip" (
    echo Pending update found. Starting updater...
    powershell -Command "Start-Process '!SCRIPT_DIR!\_updater.bat'"
    exit
)

echo Checking for updates...
powershell -ExecutionPolicy Bypass -Command "try { $latest = (Invoke-RestMethod -Uri '!URL_API!').published_at; $local = (Get-Item '!SCRIPT_DIR!\SCLER.bat').LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ssZ'); if ($latest -gt $local) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 (
    echo Update available. Downloading...
    powershell -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Headers @{ 'User-Agent'='SCLR-Updater' } -Uri '!URL_DOWNLOAD!' -OutFile '!SCRIPT_DIR!\update.zip' -UseBasicParsing" >nul 2>&1

    if exist "!SCRIPT_DIR!\update.zip" (
        powershell -ExecutionPolicy Bypass -Command "if ((Get-Item -Force '!SCRIPT_DIR!\update.zip').Length -lt 1024) { exit 1 }" >nul 2>&1
        if errorlevel 1 (
            echo.
            echo Error: Downloaded update is damaged. Please try again later.
            del "!SCRIPT_DIR!\update.zip" >nul 2>&1
            pause
            exit /b 1
        )
        if exist "!SCRIPT_DIR!\_updater.bat" (
            powershell -ExecutionPolicy Bypass -Command "if ((Get-Item -Force '!SCRIPT_DIR!\_updater.bat').Length -lt 2048) { exit 1 }" >nul 2>&1
            if errorlevel 1 (
                echo.
                echo Error: _updater.bat is damaged. Please reinstall SCLER from GitHub.
                echo https://github.com/iceee234/scler/releases
                del "!SCRIPT_DIR!\update.zip" >nul 2>&1
                pause
                exit /b 1
            )
        )
        if not exist "!SCRIPT_DIR!\_updater.bat" (
            echo.
            echo Error: _updater.bat not found. Update cannot be completed.
            echo Please reinstall SCLER from GitHub.
            echo https://github.com/iceee234/scler/releases
            del "!SCRIPT_DIR!\update.zip" >nul 2>&1
            pause
            exit /b 1
        )
        echo This window will close in 3 seconds...
        timeout /t 3 /nobreak >nul
        powershell -Command "Start-Process '!SCRIPT_DIR!\_updater.bat'"
        exit
    )
) else (
    echo No updates found.
)

:skip_update

powershell -? >nul 2>&1 || (
    echo.
    echo Error: PowerShell is required. This script cannot run without it.
    pause
    exit /b 1
)

if not exist "!SCRIPT_DIR!\scler.ps1" (
    echo.
    echo Error: scler.ps1 not found. Please reinstall the program.
    pause
    exit /b 1
)

:: ---------- Config processing ----------
if not exist "!CONFIG_FILE!" (
    echo Creating default configuration file...
    (
        echo # SCLER - user configuration file
        echo.
    ) >"!CONFIG_FILE!"
)

:: Read existing config and restore missing keys
chcp 1251 >nul
set "CFG_USE_RP_AWARD_TAG="
set "CFG_USE_SPP_TAG="
set "CFG_USE_COLOR_TAGS="
set "CFG_USE_USER_NOTES="
set "CFG_USE_USER_DICT="
set "CFG_USE_STAR="
set "CFG_USE_MINING="
set "CFG_USE_CARGO_TITLES="
set "CFG_TITLE_FORMAT="
set "CFG_GLOBAL_INI_PATH="
set "CFG_LIVE_PATH="
set "CFG_UPDATE_FAILED="
set "CFG_UPDATE_ATTEMPTS="
set "CFG_COLOR_TAGS_BLUE="
set "CFG_COLOR_TAGS_GREEN="
set "CFG_COLOR_TAGS_YELLOW="
set "CFG_COLOR_TAGS_RED="

set "FOUND_USE_RP_AWARD_TAG=0"
set "FOUND_USE_SPP_TAG=0"
set "FOUND_USE_COLOR_TAGS=0"
set "FOUND_USE_USER_NOTES=0"
set "FOUND_USE_USER_DICT=0"
set "FOUND_USE_STAR=0"
set "FOUND_USE_MINING=0"
set "FOUND_USE_CARGO_TITLES=0"
set "FOUND_TITLE_FORMAT=0"
set "FOUND_GLOBAL_INI_PATH=0"
set "FOUND_COLOR_TAGS_BLUE=0"

for /f "usebackq tokens=1,* delims==" %%a in ("!CONFIG_FILE!") do (
    set "key=%%a"
    set "val=%%b"
    if not "!key!"=="" if not "!key:~0,1!"=="#" if not "!key:~0,1!"==";" (
        if /i "!key!"=="USE_RP_AWARD_TAG" (
            if "!val: =!"=="1" (set "CFG_USE_RP_AWARD_TAG=1") else (set "CFG_USE_RP_AWARD_TAG=0")
            set "FOUND_USE_RP_AWARD_TAG=1"
        )
        if /i "!key!"=="USE_SPP_TAG" (
            if "!val: =!"=="1" (set "CFG_USE_SPP_TAG=1") else (set "CFG_USE_SPP_TAG=0")
            set "FOUND_USE_SPP_TAG=1"
        )
        if /i "!key!"=="USE_USER_NOTES" (
            if "!val: =!"=="1" (set "CFG_USE_USER_NOTES=1") else (set "CFG_USE_USER_NOTES=0")
            set "FOUND_USE_USER_NOTES=1"
        )
        if /i "!key!"=="USE_COLOR_TAGS" (
            if "!val: =!"=="1" (set "CFG_USE_COLOR_TAGS=1") else (set "CFG_USE_COLOR_TAGS=0")
            set "FOUND_USE_COLOR_TAGS=1"
        )
        if /i "!key!"=="COLOR_TAGS_BLUE" (
            for /f "delims=" %%T in ('powershell -Command "Write-Host ('!val!'.Trim())"') do set "CFG_COLOR_TAGS_BLUE=%%T"
            set "FOUND_COLOR_TAGS_BLUE=1"
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
            set "FOUND_GLOBAL_INI_PATH=1"
        )
        if /i "!key!"=="TITLE_FORMAT" (
            set "CFG_TITLE_FORMAT=!val: =!"
            set "FOUND_TITLE_FORMAT=1"
        )
        if /i "!key!"=="USE_CARGO_TITLES" (
            if "!val: =!"=="1" (set "CFG_USE_CARGO_TITLES=1") else (set "CFG_USE_CARGO_TITLES=0")
            set "FOUND_USE_CARGO_TITLES=1"
        )
        if /i "!key!"=="USE_USER_DICT" (
            if "!val: =!"=="1" (set "CFG_USE_USER_DICT=1") else (set "CFG_USE_USER_DICT=0")
            set "FOUND_USE_USER_DICT=1"
        )
        if /i "!key!"=="USE_STAR" (
            if "!val: =!"=="1" (set "CFG_USE_STAR=1") else (set "CFG_USE_STAR=0")
            set "FOUND_USE_STAR=1"
        )
        if /i "!key!"=="USE_MINING" (
            if "!val: =!"=="1" (set "CFG_USE_MINING=1") else (set "CFG_USE_MINING=0")
            set "FOUND_USE_MINING=1"
        )
        if /i "!key!"=="UPDATE_FAILED" (
            set "CFG_UPDATE_FAILED=!val: =!"
        )
        if /i "!key!"=="UPDATE_ATTEMPTS" (
            set "CFG_UPDATE_ATTEMPTS=!val: =!"
        )
        if /i "!key!"=="LIVE_PATH" (
            set "CFG_LIVE_PATH=!val!"
        )
    )
)

if "!FOUND_USE_RP_AWARD_TAG!"=="0" (
    echo # Reputation Awarded tag addition ^(1 = enabled, 0 = disabled^) >>"!CONFIG_FILE!"
    echo USE_RP_AWARD_TAG=0 >>"!CONFIG_FILE!"
    set "CFG_USE_RP_AWARD_TAG=0"
)
if "!FOUND_USE_SPP_TAG!"=="0" (
    echo # Scenario Progress Points tag addition ^(1 = enabled, 0 = disabled^) >>"!CONFIG_FILE!"
    echo USE_SPP_TAG=0 >>"!CONFIG_FILE!"
    set "CFG_USE_SPP_TAG=0"
)
if "!FOUND_USE_COLOR_TAGS!"=="0" (
    echo # Commodity color tags ^(1 = enabled, 0 = disabled^) >>"!CONFIG_FILE!"
    echo USE_COLOR_TAGS=1 >>"!CONFIG_FILE!"
    set "CFG_USE_COLOR_TAGS=1"
)
if "!FOUND_USE_USER_NOTES!"=="0" (
    echo # User notes addition ^(1 = enabled, 0 = disabled^) >>"!CONFIG_FILE!"
    echo USE_USER_NOTES=0 >>"!CONFIG_FILE!"
    set "CFG_USE_USER_NOTES=0"
)
if "!FOUND_USE_USER_DICT!"=="0" (
    echo # User dictionary replacements ^(1 = enabled, 0 = disabled^) >>"!CONFIG_FILE!"
    echo USE_USER_DICT=0 >>"!CONFIG_FILE!"
    set "CFG_USE_USER_DICT=0"
)
if "!FOUND_USE_STAR!"=="0" (
    echo # Use STAR for automatic global.ini download >>"!CONFIG_FILE!"
    echo USE_STAR=1 >>"!CONFIG_FILE!"
    set "CFG_USE_STAR=1"
)
if "!FOUND_USE_MINING!"=="0" (
    echo # Mining module ^(1 = enabled, 0 = disabled^) >>"!CONFIG_FILE!"
    echo USE_MINING=1 >>"!CONFIG_FILE!"
    set "CFG_USE_MINING=1"
)
if "!FOUND_COLOR_TAGS_BLUE!"=="0" (
    echo # Commodity color words ^(semicolon-separated^) >>"!CONFIG_FILE!"
    echo # Known commodity words: Adult; Apex; Grade A; Grade AA; Grade AAA; Grade B; Grade C; Juvenile; Ore; Pure; R; Raw; >>"!CONFIG_FILE!"
    echo COLOR_TAGS_BLUE= >>"!CONFIG_FILE!"
    echo COLOR_TAGS_GREEN=Grade AAA; >>"!CONFIG_FILE!"
    echo COLOR_TAGS_YELLOW= >>"!CONFIG_FILE!"
    echo COLOR_TAGS_RED=Pure; >>"!CONFIG_FILE!"
    set "CFG_COLOR_TAGS_BLUE="
    set "CFG_COLOR_TAGS_GREEN=Grade AAA;"
    set "CFG_COLOR_TAGS_YELLOW="
    set "CFG_COLOR_TAGS_RED=Pure;"
)
if "!FOUND_USE_CARGO_TITLES!"=="0" (
    echo # Cargo titles enrichment ^(1 = enabled, 0 = disabled^) >>"!CONFIG_FILE!"
    echo USE_CARGO_TITLES=1 >>"!CONFIG_FILE!"
    set "CFG_USE_CARGO_TITLES=1"
)
if "!FOUND_TITLE_FORMAT!"=="0" (
    echo # Cargo title format: >>"!CONFIG_FILE!"
    echo # 1 ^= Direction ^| Rank ^| Haul        ^(default^) >>"!CONFIG_FILE!"
    echo # 2 ^= Direction ^| Haul ^| Rank >>"!CONFIG_FILE!"
    echo # 3 ^= Rank ^| Haul ^| Direction >>"!CONFIG_FILE!"
    echo # 4 ^= Rank ^| Direction ^| Haul >>"!CONFIG_FILE!"
    echo # 5 ^= Haul ^| Rank ^| Direction >>"!CONFIG_FILE!"
    echo # 6 ^= Haul ^| Direction ^| Rank >>"!CONFIG_FILE!"
    echo TITLE_FORMAT=1 >>"!CONFIG_FILE!"
    set "CFG_TITLE_FORMAT=1"
)
if "!FOUND_GLOBAL_INI_PATH!"=="0" (
    echo # Path to global.ini file ^(full path including filename, without quotes^). Leave empty for auto-detection. >>"!CONFIG_FILE!"
    echo #   GLOBAL_INI_PATH=D:\Games\RSI\StarCitizen\LIVE\data\Localization\korean_^(south_korea^)\global.ini >>"!CONFIG_FILE!"
    echo GLOBAL_INI_PATH= >>"!CONFIG_FILE!"
    set "CFG_GLOBAL_INI_PATH="
)

chcp 65001 >nul

:: Validate and apply configuration values
set "USE_RP_AWARD_TAG=!CFG_USE_RP_AWARD_TAG!"
set "USE_SPP_TAG=!CFG_USE_SPP_TAG!"
set "USE_COLOR_TAGS=!CFG_USE_COLOR_TAGS!"
set "USE_USER_NOTES=!CFG_USE_USER_NOTES!"
set "USE_USER_DICT=!CFG_USE_USER_DICT!"
set "USE_STAR=!CFG_USE_STAR!"
set "USE_MINING=!CFG_USE_MINING!"
set "USE_CARGO_TITLES=!CFG_USE_CARGO_TITLES!"
set "TITLE_FORMAT=!CFG_TITLE_FORMAT!"

:: Validate TITLE_FORMAT
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
if "%USE_STAR%"=="0" (
    echo STAR integration is disabled.
)
if "%USE_MINING%"=="0" (
    echo Mining module is disabled.
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

:: ---------- Load URLs ----------
set "URLS_FILE=!SCRIPT_DIR!\urls.cfg"

if exist "!URLS_FILE!" (
    for /f "usebackq tokens=1,* delims==" %%a in ("!URLS_FILE!") do (
        set "key=%%a"
        set "val=%%b"
        if not "!key!"=="" if not "!key:~0,1!"=="#" (
            if /i "!key!"=="URL_STAR"       set "URL_STAR=!val!"
            if /i "!key!"=="URL_STAR_API"   set "URL_STAR_API=!val!"
            if /i "!key!"=="URL_CONTRACTS"  set "URL_CONTRACTS=!val!"
            if /i "!key!"=="URL_ORDNANCE"   set "URL_ORDNANCE=!val!"
            if /i "!key!"=="URL_MINING"     set "URL_MINING=!val!"
        )
    )
)

:: ---------- Download and validate STAR.bat ----------
set "STAR_FILE=!SCRIPT_DIR!\STAR.bat"

if not "%CUSTOM_ONLY%"=="1" (
    if not defined URL_STAR (
        echo Warning: URL_STAR not configured. STAR integration skipped.
        set "USE_STAR=0"
        goto :star_done
    )

    set "NEED_DOWNLOAD=1"

    :: Check GitHub for latest version
    for /f "usebackq delims=" %%v in (`powershell -ExecutionPolicy Bypass -Command "try { (Invoke-RestMethod -Uri '!URL_STAR_API!').tag_name } catch { }"`) do set "LATEST_STAR_VERSION=%%v"

    if defined LATEST_STAR_VERSION (
        :: Check local version if file exists
        if exist "!STAR_FILE!" (
            set "LOCAL_STAR_VERSION="
            for /f "usebackq tokens=2 delims==" %%l in (`findstr /b /c:"set STAR_VERSION=" "!STAR_FILE!" 2^>nul`) do set "LOCAL_STAR_VERSION=%%~l"
            if "!LOCAL_STAR_VERSION!"=="!LATEST_STAR_VERSION!" (
                set "NEED_DOWNLOAD=0"
            )
        )
    ) else (
        if exist "!STAR_FILE!" set "NEED_DOWNLOAD=0"
    )

    if "!NEED_DOWNLOAD!"=="1" (
        echo Downloading STAR.bat ...
        powershell -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Headers @{ 'User-Agent'='SC-RU-Updater' } -Uri '!URL_STAR!' -OutFile '!STAR_FILE!' -UseBasicParsing" >nul 2>&1
        if errorlevel 1 (
            echo Warning: Failed to download STAR.bat. STAR integration skipped.
            set "USE_STAR=0"
            goto :star_done
        )

        powershell -ExecutionPolicy Bypass -Command "$lines = [System.IO.File]::ReadAllLines('!STAR_FILE!', [System.Text.Encoding]::UTF8); if ($lines[1] -notmatch 'STAR_VERSION=') { $verLine = 'set STAR_VERSION=!LATEST_STAR_VERSION!'; $newLines = @($lines[0]; $verLine) + $lines[1..($lines.Length-1)]; $utf8NoBom = New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllLines('!STAR_FILE!', $newLines, $utf8NoBom) }" >nul 2>&1

        powershell -ExecutionPolicy Bypass -Command "$content = [System.IO.File]::ReadAllText('!STAR_FILE!', [System.Text.Encoding]::UTF8); $content = $content -replace \"`r`n\", \"`n\" -replace \"`n\", \"`r`n\"; $utf8NoBom = New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText('!STAR_FILE!', $content, $utf8NoBom)" >nul 2>&1

        powershell -ExecutionPolicy Bypass -Command "& { if ((Get-Item -LiteralPath '!STAR_FILE!').Length -lt 30720) { exit 1 } }" >nul 2>&1
        if errorlevel 1 (
            echo Warning: STAR.bat is too small. STAR integration skipped.
            set "USE_STAR=0"
            goto :star_done
        )

        powershell -ExecutionPolicy Bypass -Command "& { $content = Get-Content -LiteralPath '!STAR_FILE!' -Encoding UTF8 -Raw; if ($content -notmatch 'STAR' -or $content -notmatch 'ssvasilev') { exit 1 } }" >nul 2>&1
        if errorlevel 1 (
            echo Warning: STAR.bat does not appear to be valid. STAR integration skipped.
            set "USE_STAR=0"
            goto :star_done
        )

        attrib +h "!STAR_FILE!" >nul 2>&1
    )
)

:star_done

:: ---------- Find global.ini ----------
set "GLOBAL_INI="
set "SOURCE="
set "LOCAL_INI="
set "LOCAL_SOURCE="

:: 1. Command line argument (via SOURCE_PATH)
if defined SOURCE_PATH (
    set "GLOBAL_INI=!SOURCE_PATH!"
    set "SOURCE=command line"
    goto :report_source
)

:: ---------- Restore mode ----------
if "%RESTORE_MODE%"=="1" if not defined SOURCE_PATH (
    if defined CFG_GLOBAL_INI_PATH if not "!CFG_GLOBAL_INI_PATH!"=="" (
        set "GLOBAL_INI=!CFG_GLOBAL_INI_PATH!"
        set "SOURCE=local config"
        goto :report_source
    )
)

:: 2. File dialog (-p)
if "%PICK_PATH%"=="1" goto :file_dialog

:: 3. Local config (SCLER.cfg)
if defined CFG_GLOBAL_INI_PATH if not "!CFG_GLOBAL_INI_PATH!"=="" (
    set "CLEAN_PATH=!CFG_GLOBAL_INI_PATH:"=!"
    for /f "tokens=*" %%s in ("!CLEAN_PATH!") do set "GLOBAL_INI=%%s"
    if "!GLOBAL_INI:~1,1!" neq ":" if "!GLOBAL_INI!" neq "" (
        set "GLOBAL_INI=!SCRIPT_DIR!\!GLOBAL_INI!"
    )
    if exist "!GLOBAL_INI!" (
        set "LOCAL_INI=!GLOBAL_INI!"
        set "LOCAL_SOURCE=local config"
        set "GLOBAL_INI="
    ) else (
        set "GLOBAL_INI="
    )
)

:: 4. Script directory (for debugging)
if not defined LOCAL_INI (
    set "GLOBAL_INI=%SCRIPT_DIR%\global.ini"
    if exist "!GLOBAL_INI!" (
        set "LOCAL_INI=!GLOBAL_INI!"
        set "LOCAL_SOURCE=script directory"
        set "GLOBAL_INI="
    ) else (
        set "GLOBAL_INI="
    )
)

:: 5. STAR — check for updates
if "%CUSTOM_ONLY%"=="0" if "%PICK_PATH%"=="0" if "%RESTORE_MODE%"=="0" if "!USE_STAR!"=="1" if exist "!SCRIPT_DIR!\STAR.bat" (
    call :run_star
    if defined GLOBAL_INI goto :report_source
)

:: 6. Use locally found file if STAR didn't provide one
if not defined GLOBAL_INI if defined LOCAL_INI (
    set "GLOBAL_INI=!LOCAL_INI!"
    set "SOURCE=!LOCAL_SOURCE!"
    goto :report_source
)

:file_dialog
:: 7. File dialog (always for -p, or as last resort)
if defined GLOBAL_INI goto :after_dialog
for /f "delims=" %%f in ('powershell -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'Global.ini|global.ini'; $f.Title = 'Select global.ini'; if ($f.ShowDialog() -eq 'OK') { $f.FileName }"') do set "GLOBAL_INI=%%f"
if defined GLOBAL_INI (
    if exist "!GLOBAL_INI!" (
        set "SOURCE=file dialog"
        if defined CONFIG_FILE (
            powershell -Command "$path = '!GLOBAL_INI!'; $cfg = Get-Content '!CONFIG_FILE!' -Encoding UTF8 -Raw; $cfg = $cfg -replace '^GLOBAL_INI_PATH=.*', ('GLOBAL_INI_PATH=' + $path); [System.IO.File]::WriteAllText('!CONFIG_FILE!', $cfg, [System.Text.Encoding]::UTF8)"
        )
        goto :report_source
    )
    set "GLOBAL_INI="
)

:after_dialog
if defined GLOBAL_INI goto :report_source

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
    powershell -Command "$f='!GLOBAL_INI!'; $c=Get-Content $f -Encoding UTF8; $c=$c -notmatch '^SCLER_backup_created='; [System.IO.File]::WriteAllLines($f, $c, [System.Text.Encoding]::UTF8)"
    echo Restored global.ini from backup.
    pause
    exit /b
)

echo Using global.ini from !SOURCE!: "!GLOBAL_INI!"

:: ---------- Validate global.ini ----------
powershell -ExecutionPolicy Bypass -Command "& { if ((Get-Item -LiteralPath '%GLOBAL_INI%').Length -lt 1048576) { exit 1 } }" >nul 2>&1
if errorlevel 1 (
    echo.
    echo Error: "%GLOBAL_INI%" is not a valid global.ini file. The file is too small or not a localization file.
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
    set "MINING_FILE="
    goto :skip_downloads
)

:: ---------- Download and validate contracts.ini ----------
if not defined URL_CONTRACTS (
    echo.
    echo Error: URL_CONTRACTS not configured. Check urls.cfg.
    pause
    exit /b 1
)

set "CONTRACTS_FILE=%SCRIPT_DIR%\contracts.ini"

if not exist "%CONTRACTS_FILE%" (
    echo Downloading contracts.ini...
    powershell -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Headers @{ 'User-Agent'='SC-RU-Updater' } -Uri '!URL_CONTRACTS!' -OutFile '%CONTRACTS_FILE%' -UseBasicParsing" >nul 2>&1
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
if not defined URL_ORDNANCE (
    echo Warning: URL_ORDNANCE not configured. Ordnance module skipped.
    set "ORDNANCE_FILE="
    goto :skip_ordnance
)

set "ORDNANCE_FILE=%SCRIPT_DIR%\ordnance.ini"

if not exist "%ORDNANCE_FILE%" (
    echo Downloading ordnance.ini...
    powershell -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Headers @{ 'User-Agent'='SC-RU-Updater' } -Uri '!URL_ORDNANCE!' -OutFile '%ORDNANCE_FILE%' -UseBasicParsing" >nul 2>&1
    if errorlevel 1 (
        echo Warning: Failed to download ordnance.ini. Ordnance module skipped.
        set "ORDNANCE_FILE="
        goto :skip_ordnance
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

:skip_ordnance

:: ---------- Download and validate mining.ini ----------
if "%USE_MINING%"=="1" (
    if not defined URL_MINING (
        echo Warning: URL_MINING not configured. Mining module skipped.
        set "USE_MINING=0"
        goto :skip_mining
    )

    set "MINING_FILE=!SCRIPT_DIR!\mining.ini"

    if not exist "!MINING_FILE!" (
        echo Downloading mining.ini...
        powershell -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Headers @{ 'User-Agent'='SC-RU-Updater' } -Uri '!URL_MINING!' -OutFile '!MINING_FILE!' -UseBasicParsing" >nul 2>&1
        if errorlevel 1 (
            echo Warning: Failed to download mining.ini. Mining module skipped.
            set "MINING_FILE="
            goto :skip_mining
        )
    ) else (
        echo Using mining.ini from local file.
    )

    if defined MINING_FILE (
        powershell -ExecutionPolicy Bypass -Command "& { if ((Get-Item -LiteralPath '!MINING_FILE!').Length -lt 10) { exit 1 } }" >nul 2>&1
        if errorlevel 1 (
            echo Warning: mining.ini is empty. Mining module skipped.
            set "MINING_FILE="
        )
    )
)

:skip_mining

:skip_downloads
if not exist "!GLOBAL_INI!" (
    echo.
    echo Error: global.ini not found.
    pause
    exit /b 1
)

:: ---------- Run scler.ps1 ----------
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\scler.ps1" -file1 "%GLOBAL_INI%" -file2 "%CONTRACTS_FILE%" -ordnancePath "%ORDNANCE_FILE%" -miningPath "%MINING_FILE%" -useColorTags %USE_COLOR_TAGS% -useRpAwardTag %USE_RP_AWARD_TAG% -useSppTag %USE_SPP_TAG% -useUserNotes %USE_USER_NOTES% -useMining %USE_MINING% -colorBlue "%COLOR_TAGS_BLUE%" -colorGreen "%COLOR_TAGS_GREEN%" -colorYellow "%COLOR_TAGS_YELLOW%" -colorRed "%COLOR_TAGS_RED%" -titleFormat "!TITLE_FORMAT!" -useCargoTitles !USE_CARGO_TITLES! -useUserDict !USE_USER_DICT! -customOnly !CUSTOM_ONLY!
if errorlevel 1 echo Error: PowerShell error occurred.

:: ---------- Cleanup ----------
if exist "%CONTRACTS_FILE%" del "%CONTRACTS_FILE%" 2>nul
if exist "%ORDNANCE_FILE%" del "%ORDNANCE_FILE%" 2>nul
if exist "!MINING_FILE!" del "!MINING_FILE!" 2>nul
attrib +h "!SCRIPT_DIR!\_updater.bat" >nul 2>&1
echo Done.

:: ---------- Launch RSI Launcher ----------
if "!USE_STAR!"=="1" if defined LAUNCHER_PATH (
    if exist "!LAUNCHER_PATH!\RSI Launcher.exe" (
        start "" "!LAUNCHER_PATH!\RSI Launcher.exe" >nul 2>&1
    )
)

pause
exit /b

goto :eof

:run_star
if not exist "!SCRIPT_DIR!\STAR.bat" (
    echo SCLER: STAR.bat not found. Skipping.
    goto :eof
)

set "STAR_VER="
for /f "usebackq tokens=2 delims==" %%v in (`findstr /b /c:"set STAR_VERSION=" "!SCRIPT_DIR!\STAR.bat" 2^>nul`) do set "STAR_VER=%%~v"
if defined STAR_VER (
    echo SCLER: Running STAR !STAR_VER!...
) else (
    echo SCLER: Running STAR...
)

start "" /wait cmd /c "!SCRIPT_DIR!\STAR.bat" -no-launch

echo STAR completed.
echo.

:: Read LIVE_PATH back from STAR config
if exist "!SCRIPT_DIR!\star_config.cfg" (
    for /f "usebackq tokens=1,* delims==" %%a in ("!SCRIPT_DIR!\star_config.cfg") do (
        if "%%a"=="LIVE_PATH" (
            set "STAR_LIVE_PATH=%%b"
            set "CFG_LIVE_PATH=%%b"
        )
        if "%%a"=="LAUNCHER_PATH" (
            set "LAUNCHER_PATH=%%b"
        )
    )
)

:: Save LIVE_PATH for future auto-mode
if defined CFG_LIVE_PATH (
    call :save_live_path
)

:: Check for global.ini
if defined CFG_LIVE_PATH (
    set "GLOBAL_INI=!CFG_LIVE_PATH!\data\Localization\korean_(south_korea)\global.ini"
    if exist "!GLOBAL_INI!" (
        set "SOURCE=STAR download"
        set "STAR_FOUND=1"
    ) else (
        set "GLOBAL_INI="
    )
)

:: Save GLOBAL_INI_PATH to config
if defined GLOBAL_INI if exist "!GLOBAL_INI!" (
    powershell -Command "$path = '!GLOBAL_INI!'; $cfg = Get-Content '!CONFIG_FILE!' -Encoding UTF8 -Raw; if ($cfg -notmatch 'GLOBAL_INI_PATH=') { $cfg += \"`nGLOBAL_INI_PATH=$path\" }; $cfg = $cfg -replace 'GLOBAL_INI_PATH=.*', ('GLOBAL_INI_PATH=' + $path); [System.IO.File]::WriteAllText('!CONFIG_FILE!', $cfg, [System.Text.Encoding]::UTF8)"
)
goto :eof

:save_live_path
if not defined CFG_LIVE_PATH goto :eof
if not exist "!CONFIG_FILE!" goto :eof
powershell -Command "$cfg = Get-Content '!CONFIG_FILE!' -Encoding UTF8 -Raw; if ($cfg -notmatch 'LIVE_PATH=') { $cfg += \"`nLIVE_PATH=!CFG_LIVE_PATH!\" }; $cfg = $cfg -replace 'LIVE_PATH=.*', 'LIVE_PATH=!CFG_LIVE_PATH!'; [System.IO.File]::WriteAllText('!CONFIG_FILE!', $cfg, [System.Text.Encoding]::UTF8)"
goto :eof

goto :eof

:add_config_param
:: %1 = param name, %2 = default value
if not defined CFG_%1 (
    echo Adding %1 to existing config...
    echo %1=%2 >>"!CONFIG_FILE!"
    set "CFG_%1=%2"
)
goto :eof