@echo off
setlocal EnableExtensions
title Echo Payam - Cloudflare Pages Deploy
color 0B
set "WRANGLER_SEND_METRICS=false"
set "CI="

echo.
echo  ==================================================
echo    Echo Payam  -^>  Cloudflare Pages  (auto deploy)
echo  ==================================================
echo.

rem ---------- check Node.js ----------
where node >nul 2>&1
if errorlevel 1 goto :nonode
for /f "tokens=1 delims=." %%v in ('node -v') do set "NV=%%v"
set "NV=%NV:v=%"
if %NV% LSS 20 goto :oldnode

rem ---------- 1. token ----------
echo [1/4] Cloudflare API Token
echo       Create it at: https://dash.cloudflare.com/profile/api-tokens
echo       Custom token, permission: Account ^> Cloudflare Pages ^> Edit
echo       Typing is hidden. Paste the token and press Enter.
set "CLOUDFLARE_API_TOKEN="
set /p "=      Token: " <nul
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "$s=Read-Host -AsSecureString; [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))"`) do set "CLOUDFLARE_API_TOKEN=%%T"
echo.
if not defined CLOUDFLARE_API_TOKEN goto :notoken

rem ---------- 2. account id (optional) ----------
echo.
echo [2/4] Cloudflare Account ID  (optional)
echo       Dashboard ^> Workers ^& Pages ^> "Account ID" on the right side.
echo       Press Enter to auto-detect (works if you have only one account).
set "ACC="
set /p "ACC=      Account ID: "
if defined ACC set "CLOUDFLARE_ACCOUNT_ID=%ACC%"

rem ---------- 3. project link ----------
echo.
echo [3/4] Project link
echo       GitHub repo URL  (https://github.com/USER/REPO)
echo       or a local folder path on this PC.
set "SRC="
set /p "SRC=      Link: "
if not defined SRC goto :nosrc
set "SRC=%SRC:"=%"

rem ---------- 4. name prefix ----------
echo.
echo [4/4] Cloudflare project name prefix
echo       Result: https://PREFIX.pages.dev  and  https://PREFIX-admin.pages.dev
set "PFX=echo-payam"
set /p "PFX=      Prefix [echo-payam]: "
for /f "delims=" %%i in ('powershell -NoProfile -Command "('%PFX%').ToLower() -replace '[^a-z0-9-]','-'"') do set "PFX=%%i"

rem ---------- get the source ----------
set "WORK="
set "CLONED=0"
if exist "%SRC%\" (
  set "WORK=%SRC%"
) else (
  where git >nul 2>&1
  if errorlevel 1 goto :nogit
  if exist "%TEMP%\echo_payam_deploy" rmdir /s /q "%TEMP%\echo_payam_deploy"
  echo.
  echo Cloning %SRC% ...
  git clone --depth 1 "%SRC%" "%TEMP%\echo_payam_deploy"
  if errorlevel 1 goto :noclone
  set "WORK=%TEMP%\echo_payam_deploy"
  set "CLONED=1"
)

rem ---------- find the web folders ----------
set "UDIR="
set "ADIR="
if exist "%WORK%\user\index.html" set "UDIR=%WORK%\user"
if not defined UDIR if exist "%WORK%\user_pwa\index.html" set "UDIR=%WORK%\user_pwa"
if exist "%WORK%\admin\index.html" set "ADIR=%WORK%\admin"
if not defined ADIR if exist "%WORK%\admin_pwa\index.html" set "ADIR=%WORK%\admin_pwa"
if not defined UDIR if not defined ADIR if exist "%WORK%\index.html" set "UDIR=%WORK%"
if not defined UDIR if not defined ADIR goto :nofolders

rem ---------- deploy ----------
set "FAILED=0"
if defined UDIR call :deploy "%UDIR%" "%PFX%"
if defined ADIR call :deploy "%ADIR%" "%PFX%-admin"

if "%CLONED%"=="1" rmdir /s /q "%TEMP%\echo_payam_deploy" >nul 2>&1

echo.
echo  ==================================================
if "%FAILED%"=="1" goto :finished_err
echo    ALL DONE
if defined UDIR echo    User app  : https://%PFX%.pages.dev
if defined ADIR echo    Admin app : https://%PFX%-admin.pages.dev
echo    (if a name was already taken, Cloudflare adds a suffix - see the URLs printed above)
echo  ==================================================
echo.
pause
exit /b 0

:finished_err
echo    FINISHED WITH ERRORS - read the messages above.
echo  ==================================================
echo.
pause
exit /b 1

rem ================= subroutine =================
:deploy
echo.
echo  --------------------------------------------------
echo   Folder : %~1
echo   Project: %~2
echo  --------------------------------------------------
call npx --yes wrangler@latest pages project create %~2 --production-branch main >nul 2>&1
call npx --yes wrangler@latest pages deploy "%~1" --project-name %~2 --branch main --commit-dirty=true
if errorlevel 1 goto :deploy_fail
echo  [OK] %~2  -^>  https://%~2.pages.dev
exit /b 0
:deploy_fail
set "FAILED=1"
echo  [FAILED] %~2
exit /b 1

rem ================= errors =================
:nonode
echo [ERROR] Node.js is not installed.
echo         Install it with:  winget install OpenJS.NodeJS.LTS
echo         (or from https://nodejs.org) then run this file again.
goto :end_err
:oldnode
echo [ERROR] Node.js is too old (need v20 or newer). Found v%NV%.
echo         Update:  winget upgrade OpenJS.NodeJS.LTS
goto :end_err
:notoken
echo [ERROR] No token entered.
goto :end_err
:nosrc
echo [ERROR] No project link entered.
goto :end_err
:nogit
echo [ERROR] Git is not installed (needed to download the repo).
echo         Install it with:  winget install Git.Git
echo         Or pass a local folder path instead of a link.
goto :end_err
:noclone
echo [ERROR] Could not download the repo. Check the link.
echo         For a private repo, Git will ask you to sign in - or use a local folder.
goto :end_err
:nofolders
echo [ERROR] No web folder found. Expected user\index.html and/or admin\index.html
echo         inside the project.
if "%CLONED%"=="1" rmdir /s /q "%TEMP%\echo_payam_deploy" >nul 2>&1
goto :end_err
:end_err
echo.
pause
exit /b 1
