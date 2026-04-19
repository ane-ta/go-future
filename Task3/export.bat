pushd "%~dp0"
call ./../export-org.bat ./docs/01-regions.org ./results/
call ./../export-org.bat ./docs/02-replication.org ./results/
call ./../export-org.bat ./docs/03-georouting.org ./results/
call ./../export-org.bat ./docs/04-failover-failback.org ./results/
call ./../export-org.bat ./docs/05-Safety.org ./results/

popd