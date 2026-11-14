param(
    [string]$SourceExe = 'C:\cargo-target\daozhu\x86_64-pc-windows-msvc\release\daozhu.exe',
    [string]$NsisDir = 'C:\cargo-target\nsis313\nsis-bundle\windows',
    [string]$Output = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$version = [regex]::Match((Get-Content -LiteralPath (Join-Path $projectRoot 'Cargo.toml') -Raw), '(?m)^version = "([^"]+)"').Groups[1].Value
if (-not $Output) { $Output = Join-Path $projectRoot "dist\岛主-安装包-v$version.exe" }
$makensis = Join-Path $NsisDir 'makensis.exe'
if (-not (Test-Path -LiteralPath $makensis)) { throw "找不到 makensis.exe：$makensis" }
# NSIS 从 NSISDIR 找 Stubs，bundle 的 windows 子目录必须显式指定，否则会用错上级目录。
$env:NSISDIR = $NsisDir
& $makensis /V2 "/DAPP_VERSION=$version" "/DPROJECT_DIR=$projectRoot" "/DSOURCE_EXE=$SourceExe" "/DOUTPUT_FILE=$Output" (Join-Path $projectRoot 'installer\setup.nsi')
if ($LASTEXITCODE -ne 0) { throw '安装包编译失败' }
$file = Get-Item -LiteralPath $Output
Write-Output ('安装包：' + $file.FullName + '  ' + [math]::Round($file.Length / 1MB, 2) + ' MB')
