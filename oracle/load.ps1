<#
  Loads the corp_mock data into the Oracle Free Docker container (schema CORP_MOCK).

  Usage (PowerShell, from any folder):
      .\load.ps1
      .\load.ps1 -SchemaPassword Corp_Mock_2026

  Setup: unzip this folder into the container's read-only setup mount on the Windows machine:
      C:\Users\thedo\Documents\db-lab\init\oracle\corp_mock_oracle
  (it appears inside the container as /opt/oracle/scripts/setup/corp_mock_oracle).

  Administration uses OS authentication inside the container ("/ as sysdba"), so no admin password is needed.
  SchemaPassword is the password for the new CORP_MOCK schema: letters, digits and underscore only,
  starting with a letter. Re-running with a different value resets that password.
#>
param(
    [string]$Container      = 'dblab-oracle',
    [ValidatePattern('^[A-Za-z][A-Za-z0-9_]*$')]
    [string]$SchemaPassword = 'Corp_Mock_2026',
    [string]$ContainerDir   = '/opt/oracle/scripts/setup/corp_mock_oracle'
)
$ErrorActionPreference = 'Stop'

# Runs a bash command inside the container; no double quotes are used so quoting survives any PowerShell version.
function Invoke-InContainer([string]$Cmd) {
    docker exec $Container bash -c $Cmd
    if ($LASTEXITCODE -ne 0) { throw "Command failed (exit code $LASTEXITCODE). See the messages above." }
}

$running = docker inspect -f '{{.State.Running}}' $Container 2>$null
if ($running -ne 'true') { throw "Container '$Container' is not running. Start it first (docker start $Container)." }

docker exec $Container test -f "$ContainerDir/run_all.sql"
if ($LASTEXITCODE -ne 0) {
    throw "Cannot see $ContainerDir/run_all.sql inside '$Container'. Unzip the package into C:\Users\thedo\Documents\db-lab\init\oracle\ so the folder is corp_mock_oracle, or pass -ContainerDir."
}

Write-Host 'Creating the CORP_MOCK schema and directory object...'
Invoke-InContainer ('sqlplus -s / as sysdba @' + $ContainerDir + '/create_schema.sql ' + $SchemaPassword + ' ' + $ContainerDir + ' ${ORACLE_PDB:-FREEPDB1}')

Write-Host 'Building schema, loading data, adding descriptions, verifying...'
Invoke-InContainer ('sqlplus -s corp_mock/' + $SchemaPassword + '@//localhost:1521/${ORACLE_PDB:-FREEPDB1} @' + $ContainerDir + '/run_all.sql')

Write-Host 'Done. Every row above should say PASS.'
