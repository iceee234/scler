@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "ZIP_FILE=%SCRIPT_DIR%\update.zip"
set "TEMP_DIR=%SCRIPT_DIR%\update_temp"

echo ========================================
echo SCLER Updater
echo ========================================
echo.

:: ---------- Clean up old extracted files ----------
if exist "%TEMP_DIR%\scler-latest" (
    del "%TEMP_DIR%\scler-latest\*.ps1" >nul 2>&1
    del "%TEMP_DIR%\scler-latest\*.bat" >nul 2>&1
    del "%TEMP_DIR%\scler-latest\*.txt" >nul 2>&1
    del "%TEMP_DIR%\scler-latest\*.cfg" >nul 2>&1
)

echo Extracting archive...
powershell -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%TEMP_DIR%' -Force"
if errorlevel 1 (
    echo Error: Failed to extract archive.
    del "%ZIP_FILE%" >nul 2>&1
    pause
    exit /b 1
)

for /d %%d in ("%TEMP_DIR%\*") do set "EXTRACT_DIR=%%d"
if not defined EXTRACT_DIR (
    echo Error: No extracted folder found.
    pause
    exit /b 1
)
echo   Extracted to: !EXTRACT_DIR!

echo.
echo Copying files...
copy /y "!EXTRACT_DIR!\scler.ps1" "%SCRIPT_DIR%\scler.ps1" >nul
if errorlevel 1 goto :update_failed

copy /y "!EXTRACT_DIR!\scler_tables.ps1" "%SCRIPT_DIR%\scler_tables.ps1" >nul
if errorlevel 1 goto :update_failed

timeout /t 3 /nobreak >nul
copy /y "!EXTRACT_DIR!\SCLER.bat" "%SCRIPT_DIR%\SCLER.bat" >nul 2>&1
if errorlevel 1 (
    echo Warning: Could not copy SCLER.bat.
    goto :update_failed
)
echo   Files copied.

:: ---------- Save new updater for next restart ----------
if exist "!EXTRACT_DIR!\_updater.bat" (
    (
        echo :: updater copy
        type "!EXTRACT_DIR!\_updater.bat"
    ) > "%SCRIPT_DIR%\_updater_new.bat"
)

echo.
echo Updating urls.cfg...
if exist "!EXTRACT_DIR!\urls.cfg" (
    if not exist "%SCRIPT_DIR%\urls.cfg" (
        copy /y "!EXTRACT_DIR!\urls.cfg" "%SCRIPT_DIR%\urls.cfg" >nul
        echo   Created new urls.cfg
    ) else (
        for /f "usebackq tokens=1,* delims==" %%a in ("!EXTRACT_DIR!\urls.cfg") do (
            set "URL_KEY=%%a"
            set "URL_VAL=%%b"
            if not "!URL_KEY!"=="" if not "!URL_KEY:~0,1!"=="#" (
                findstr /b /c:"!URL_KEY!=" "%SCRIPT_DIR%\urls.cfg" >nul 2>&1
                if errorlevel 1 (
                    echo !URL_KEY!=!URL_VAL! >>"%SCRIPT_DIR%\urls.cfg"
                    echo   Added: !URL_KEY!
                )
            )
        )
    )
)

echo.
echo Cleanup...
if exist "%ZIP_FILE%" (
    move /y "%ZIP_FILE%" "%TEMP%\scler_update_archive.zip" >nul 2>&1
    if errorlevel 1 echo Warning: Failed to move update archive.
)


:: Reset update counters on success
powershell -Command "$cfg = Get-Content '%SCRIPT_DIR%\SCLER.cfg' -Encoding UTF8 -Raw; ..."

echo.
echo Done. This window will close in 5 seconds...
timeout /t 5 /nobreak >nul
start "" "%SCRIPT_DIR%\SCLER.bat"
exit

:update_failed
echo.
echo Error: Update failed - some files could not be updated.
echo Please reinstall SCLER from GitHub.
echo https://github.com/iceee234/scler/releases

set "CFG_FILE=%SCRIPT_DIR%\SCLER.cfg"
set "ATTEMPTS=1"
for /f "usebackq tokens=2 delims==" %%a in (`findstr /b "UPDATE_ATTEMPTS=" "%CFG_FILE%" 2^>nul`) do set /a "ATTEMPTS=%%a+1"
powershell -Command "$cfg = Get-Content '%CFG_FILE%' -Encoding UTF8 -Raw; if ($cfg -notmatch 'UPDATE_ATTEMPTS=') { $cfg += \"`nUPDATE_ATTEMPTS=!ATTEMPTS!\" } else { $cfg = $cfg -replace 'UPDATE_ATTEMPTS=.*', 'UPDATE_ATTEMPTS=!ATTEMPTS!' }; if (!ATTEMPTS! -ge 3) { if ($cfg -notmatch 'UPDATE_FAILED=') { $cfg += \"`nUPDATE_FAILED=1\" } else { $cfg = $cfg -replace 'UPDATE_FAILED=.*', 'UPDATE_FAILED=1' } }; $cfg | Set-Content '%CFG_FILE%' -Encoding UTF8"

pause
exit /b 1