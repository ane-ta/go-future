pushd "%~dp0"

@REM call ./../export-org.bat ./docs/classification.org ./results/
call ./../export-org.bat ./docs/microservices.org ./results/
call ./../export-org.bat ./docs/interaction.org ./results/
call ./../export-org.bat ./docs/reliability.org ./results/
call ./../export-org.bat ./docs/orchestrator.org ./results/
call ./../export-org.bat ./docs/topics.org ./results/

call ./../export-org.bat ./docs/monitoring.org ./results/
call ./../export-org.bat ./docs/monitoring-metrics.org ./results/
@REM xcopy /y ".\docs\С2-to-be.puml" ".\results\"

popd