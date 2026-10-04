@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"

rem ===== AYARLAR =====
set GH_USER=enesboz-9
set REPO=spatial-memory
set REMOTE=https://github.com/%GH_USER%/%REPO%.git
rem ===================

echo.
echo === 1/6 Arac kontrolu ===
where git >nul 2>nul || (echo [HATA] git kurulu degil: https://git-scm.com & goto :fail)
where flutter >nul 2>nul || (echo [HATA] flutter PATH'te degil & goto :fail)

echo.
echo === 2/6 Web platformu hazirlaniyor ===
if not exist web (
  echo web klasoru yok, olusturuluyor...
  call flutter create . --platforms=web --project-name spatial_memory
  if errorlevel 1 goto :fail
)

if not exist .gitignore (
  (
    echo .dart_tool/
    echo .packages
    echo build/
    echo .idea/
    echo *.iml
    echo .flutter-plugins
    echo .flutter-plugins-dependencies
    echo pubspec.lock
  ) > .gitignore
)

echo.
echo === 3/6 Bagimliliklar ve testler ===
call flutter pub get || goto :fail
call flutter test
if errorlevel 1 (
  echo [UYARI] Testler basarisiz. Yine de devam etmek icin bir tusa bas, durdurmak icin Ctrl+C.
  pause >nul
)

echo.
echo === 4/6 Web surumu derleniyor ===
call flutter build web --release --base-href "/%REPO%/"
if errorlevel 1 goto :fail

echo.
echo === 5/6 Kaynak kod GitHub'a gonderiliyor (main) ===
if not exist .git git init -b main
git add -A
git commit -m "Spatial Memory: guncelleme" >nul 2>nul
git branch -M main
git remote remove origin >nul 2>nul
git remote add origin %REMOTE%
git push -u origin main
if errorlevel 1 (
  echo.
  echo [HATA] Push basarisiz. Repo yoksa once https://github.com/new adresinden
  echo        "%REPO%" adinda BOS bir public repo olustur, sonra bu dosyayi tekrar calistir.
  goto :fail
)

echo.
echo === 6/6 Web surumu gh-pages dalina yukleniyor ===
pushd build\web
if exist .git rmdir /s /q .git
git init -b gh-pages
git add -A
git commit -m "Web yayini" >nul
git remote add origin %REMOTE%
git push -f origin gh-pages
set PUSHERR=!errorlevel!
popd
if not "!PUSHERR!"=="0" goto :fail

echo.
echo ================================================
echo  TAMAM! Son adim (sadece ilk seferde):
echo  https://github.com/%GH_USER%/%REPO%/settings/pages
echo  Branch: gh-pages  /  (root)  sec ve Save'e bas.
echo.
echo  Oyun linki (1-2 dk sonra acilir):
echo  https://%GH_USER%.github.io/%REPO%/
echo ================================================
pause
exit /b 0

:fail
echo.
echo Islem yarim kaldi. Yukaridaki hatayi kontrol et.
pause
exit /b 1
