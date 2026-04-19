@echo off
setlocal enabledelayedexpansion

:: Список папок с заданиями
set tasks=Task1 Task2 Task3 Task4 Task5

for %%t in (%tasks%) do (
    echo ========================================
    echo Processing %%t...
    
    if exist "%%t\export.bat" (
        pushd ".\%%t"
        del /q /s ".\results\*.md"
        call export.bat
        popd
    ) else (
        echo Error: export.bat not found in %%t
    )
)

echo ========================================
echo All tasks processed!
pause