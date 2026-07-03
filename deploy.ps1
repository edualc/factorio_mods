$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$DeployDir  = Join-Path (Split-Path -Parent $ScriptDir) "deploy"
New-Item -ItemType Directory -Force $DeployDir | Out-Null
Remove-Item (Join-Path $DeployDir "*.zip") -ErrorAction SilentlyContinue

Set-Location $ScriptDir

foreach ($dir in Get-ChildItem -Directory) {
    if (-not (Test-Path (Join-Path $dir.FullName "info.json"))) { continue }
    $zipPath = Join-Path $DeployDir "$($dir.Name).zip"
    Compress-Archive -Path $dir.FullName -DestinationPath $zipPath
    Write-Host "Packed $zipPath"
}

Write-Host "Done. ZIPs are in $DeployDir"
