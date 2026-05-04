pushd "%~dp0"

call ./../export-org.bat ./docs/01-microservices.org ./results/
call ./../export-org.bat ./docs/02-interaction.org ./results/
call ./../export-org.bat ./docs/03-orchestrator.org ./results/
call ./../export-org.bat ./docs/04-reliability.org ./results/

call ./../export-org.bat ./docs/05-monitoring.org ./results/
call ./../export-org.bat ./docs/06-monitoring-metrics.org ./results/

call ./../export-org.bat ./docs/07-topics.org ./results/

popd