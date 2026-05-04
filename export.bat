@echo off
setlocal enabledelayedexpansion
call docker run --rm -v "%CD%\docs:/usr/local/structurizr" structurizr/structurizr export -workspace /usr/local/structurizr/workspace.dsl -format plantuml/c4plantuml -output /usr/local/structurizr/puml/
call docker run --rm -v "%CD%\docs:/data" plantuml/plantuml -tsvg /data/puml/*.puml -o /data/images/

@REM call docker run --rm -v "%CD%\Task1\docs:/usr/local/structurizr" structurizr/structurizr export -workspace /usr/local/structurizr/workspace.dsl -format themeable-svg -output /usr/local/structurizr/images/

:: Список папок с заданиями
set numbers=1 2 3 4 5

for %%t in (%numbers%) do (
    set task=Task%%t
    echo ========================================
    echo Processing !task!...
    
    if exist "!task!\export.bat" (
        pushd ".\!task!"
            del /q /s ".\results\*.md"
            del /q /s ".\results\*.puml"
            del /q /s ".\results\*.svg"
            call export.bat
        popd
        xcopy /y ".\docs\puml\structurizr-0%%t*.puml" ".\!task!\results\"
        xcopy /y ".\docs\images\structurizr-0%%t*.svg" ".\!task!\results\"

    ) else (
        echo Error: export.bat not found in !task!
    )
)

echo ========================================
echo All tasks processed!
pause
