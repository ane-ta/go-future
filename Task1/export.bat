pushd "%~dp0"

call ./../export-org.bat ./docs/01-requirements.org ./results/
call ./../export-org.bat ./docs/02-migration.org ./results/
call ./../export-org.bat ./docs/03-migration-plan.org ./results/

popd