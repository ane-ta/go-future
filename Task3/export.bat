call ./../export-org.bat ./docs/regions.org ./results/
call ./../export-org.bat ./docs/replication.org ./results/
call ./../export-org.bat ./docs/georouting.org ./results/
call ./../export-org.bat ./docs/failover-failback.org ./results/
call ./../export-org.bat ./docs/Safety.org ./results/

@REM xcopy /y ".\docs\С2-to-be.puml" ".\results\"