@echo off
chcp 65001 > nul

:: Параметры: %1 - входной файл, %2 - выходная папка
set "IN_FILE=%~1"
set "OUT_DIR=%~2"
set "OUT_FILE=%OUT_DIR%\%~n1.md"

:: 1. Проверяем, создана ли папка, если нет — создаем
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

:: 2. Конвертация через Pandoc
pandoc "%IN_FILE%" -f org -t gfm+raw_html -o "%OUT_FILE%" --wrap=none

:: 3. Силовая очистка: убираем экранирование \* и \<br\> через PowerShell
powershell -NoProfile -Command "$c = Get-Content '%OUT_FILE%' -Raw -Encoding UTF8; $c -replace '\\\<br\\?\>', '<br>' -replace '\\\*', '*' | Set-Content '%OUT_FILE%' -Encoding UTF8"

echo Конвертация %IN_FILE% завершена в %OUT_FILE%
