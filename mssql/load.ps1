<#
  Loads the corp_mock database into the SQL Server Docker container.

  Usage (PowerShell, from any folder):
      .\load.ps1
      .\load.ps1 -Database corp_mock -Container dblab-sqlserver

  Setup: unzip this folder into the container's /init mount on the Windows machine:
      C:\Users\thedo\Documents\db-lab\init\sqlserver\corp_mock_mssql
  (that folder appears inside the container as /init/corp_mock_mssql).

  The script signs in as 'sa' using the password already stored in the container's
  environment (MSSQL_SA_PASSWORD), so nothing is typed or saved here.
#>
param(
    [string]$Container    = 'dblab-sqlserver',
    [string]$Database     = 'corp_mock',
    [string]$ContainerDir = '/init/corp_mock_mssql'
)
$ErrorActionPreference = 'Stop'

# Runs sqlcmd inside the container; no double quotes are used so quoting survives any PowerShell version.
function Invoke-ContainerSqlcmd([string]$SqlcmdArgs) {
    $cmd = 'SQLCMDPASSWORD=$MSSQL_SA_PASSWORD /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -I -b -W ' + $SqlcmdArgs
    docker exec $Container bash -c $cmd
    if ($LASTEXITCODE -ne 0) { throw "sqlcmd failed (exit code $LASTEXITCODE). See the messages above." }
}

$running = docker inspect -f '{{.State.Running}}' $Container 2>$null
if ($running -ne 'true') { throw "Container '$Container' is not running. Start it first (docker start $Container)." }

docker exec $Container test -f "$ContainerDir/run_all.sql"
if ($LASTEXITCODE -ne 0) {
    throw "Cannot see $ContainerDir/run_all.sql inside '$Container'. Unzip the package into C:\Users\thedo\Documents\db-lab\init\sqlserver\ so the folder is corp_mock_mssql, or pass -ContainerDir."
}

Write-Host "Preparing database $Database..."
Invoke-ContainerSqlcmd "-v DBNAME=$Database -i $ContainerDir/create_db.sql"

Write-Host "Building schema, loading data, adding descriptions, verifying..."
Invoke-ContainerSqlcmd "-d $Database -v DIR=$ContainerDir -i $ContainerDir/run_all.sql"

Write-Host "Done. Every row above should say PASS."
