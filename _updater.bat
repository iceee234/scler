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

echo Extracting archive...
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" >nul
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
copy /y "!EXTRACT_DIR!\SCLER_Documentation.txt" "%SCRIPT_DIR%\SCLER_Documentation.txt" >nul
if errorlevel 1 goto :update_failed

echo.
echo Waiting for SCLER.bat to become available...
set "RETRIES=0"
:wait_loop
set /a RETRIES+=1
if %RETRIES% gtr 10 goto :update_failed
echo   Attempt %RETRIES%...
timeout /t 1 /nobreak >nul
copy /y "!EXTRACT_DIR!\SCLER.bat" "%SCRIPT_DIR%\SCLER.bat" >nul 2>&1
if errorlevel 1 goto :wait_loop
echo   SCLER.bat updated.

:: Save new updater for next restart
if exist "!EXTRACT_DIR!\_updater.bat" (
    copy /y "!EXTRACT_DIR!\_updater.bat" "%SCRIPT_DIR%\_updater_new.bat" >nul
)

echo.
echo Updating urls.cfg...
if exist "!EXTRACT_DIR!\urls.cfg" (
    if not exist "%SCRIPT_DIR%\urls.cfg" (
        copy /y "!EXTRACT_DIR!\urls.cfg" "%SCRIPT_DIR%\urls.cfg" >nul
        echo   Created new urls.cfg
    ) else (
        for /f "usebackq tokens=1,* delims==" %%a in ("!EXTRACT_DIR!\urls.cfg") do (
            set "key=%%a"
            set "val=%%b"
            if not "!key!"=="" if not "!key:~0,1!"=="#" (
                findstr /b /c:"!key!=" "%SCRIPT_DIR%\urls.cfg" >nul 2>&1
                if errorlevel 1 (
                    echo !key!=!val! >>"%SCRIPT_DIR%\urls.cfg"
                    echo   Added: !key!
                )
            )
        )
    )
)

:: Reset update counters
powershell -Command "$cfg = Get-Content '%SCRIPT_DIR%\SCLER.cfg' -Encoding UTF8 -Raw; $cfg = $cfg -replace 'UPDATE_ATTEMPTS=.*', 'UPDATE_ATTEMPTS=0' -replace 'UPDATE_FAILED=.*', 'UPDATE_FAILED=0'; [System.IO.File]::WriteAllText('%SCRIPT_DIR%\SCLER.cfg', $cfg, [System.Text.Encoding]::UTF8)" >nul 2>&1

echo.
echo Cleanup...
del "%ZIP_FILE%" >nul 2>&1
rmdir /s /q "%TEMP_DIR%" >nul 2>&1

echo.
echo Starting updated SCLER...
start "" "%SCRIPT_DIR%\SCLER.bat"
echo Done. This window will close in 5 seconds...
timeout /t 5 /nobreak >nul
exit

:update_failed
echo.
echo Error: Update failed - some files could not be updated.
echo Please reinstall SCLER from GitHub.
echo https://github.com/iceee234/scler/releases
:: Increment update attempts
set "CFG_FILE=%SCRIPT_DIR%\SCLER.cfg"
set "ATTEMPTS=1"
for /f "usebackq tokens=2 delims==" %%a in (`findstr /b "UPDATE_ATTEMPTS=" "%CFG_FILE%" 2^>nul`) do set /a "ATTEMPTS=%%a+1"
powershell -Command "$cfg = Get-Content '%CFG_FILE%' -Encoding UTF8 -Raw; if ($cfg -notmatch 'UPDATE_ATTEMPTS=') { $cfg += \"`nUPDATE_ATTEMPTS=!ATTEMPTS!\" } else { $cfg = $cfg -replace 'UPDATE_ATTEMPTS=.*', 'UPDATE_ATTEMPTS=!ATTEMPTS!' }; if (!ATTEMPTS! -ge 3) { if ($cfg -notmatch 'UPDATE_FAILED=') { $cfg += \"`nUPDATE_FAILED=1\" } else { $cfg = $cfg -replace 'UPDATE_FAILED=.*', 'UPDATE_FAILED=1' } }; [System.IO.File]::WriteAllText('%CFG_FILE%', $cfg, [System.Text.Encoding]::UTF8)"
pause
exit /b 1