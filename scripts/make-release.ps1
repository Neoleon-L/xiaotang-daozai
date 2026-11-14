# 生成 GitHub Releases 用的在线更新包。
# 目录名与压缩包名必须与程序内置规则一致：Daozhu-v<版本>-windows-x64.zip，
# 且压缩包内只有 Daozhu-v<版本>-windows-x64/daozhu.exe 这一条程序路径。
param(
    [string]$SourceExe = 'C:\cargo-target\daozhu\x86_64-pc-windows-msvc\release\daozhu.exe',
    [string]$OutputDir = (Join-Path $PSScriptRoot '..\dist'),
    [string]$SetupExe
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $SourceExe -PathType Leaf)) { throw "找不到程序：$SourceExe" }
$version = [Diagnostics.FileVersionInfo]::GetVersionInfo((Resolve-Path -LiteralPath $SourceExe).Path).FileVersion
$parts = ($version -split '\.')[0..2]
$version = ($parts -join '.')
$packageName = "Daozhu-v$version-windows-x64"
$staging = Join-Path $OutputDir $packageName
if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging -Force | Out-Null
Copy-Item -LiteralPath $SourceExe -Destination (Join-Path $staging 'daozhu.exe')
foreach ($file in 'LICENSE', 'THIRD_PARTY_NOTICES.txt') {
    $source = Join-Path (Join-Path $PSScriptRoot '..') $file
    if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination $staging }
}
if ($SetupExe -and (Test-Path -LiteralPath $SetupExe)) { Copy-Item -LiteralPath $SetupExe -Destination $staging }
$archive = Join-Path $OutputDir "$packageName.zip"
if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
Compress-Archive -LiteralPath $staging -DestinationPath $archive -CompressionLevel Optimal
# 自检：压缩包里必须能按内置规则找到程序
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($archive)
try {
    $entry = "$packageName/daozhu.exe"
    $found = @($zip.Entries | Where-Object { $_.FullName.Replace('\', '/') -ceq $entry })
    if ($found.Count -ne 1) { throw "压缩包缺少 $entry" }
} finally { $zip.Dispose() }
$hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
$size = [math]::Round((Get-Item -LiteralPath $archive).Length / 1MB, 2)
Write-Output "更新包：$archive"
Write-Output "版本：v$version  大小：$size MB"
Write-Output "SHA256：$hash"
Write-Output ''
Write-Output '下一步：在 GitHub 仓库 Neoleon-L/xiaotang-daozai 新建 Release，'
Write-Output " tag 填 v$version，把 $packageName.zip 作为附件上传。"
Write-Output ' 程序会读取该 Release 的资产摘要，附件名必须是上面这个 zip 名。'
