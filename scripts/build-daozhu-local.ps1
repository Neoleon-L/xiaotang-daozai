param(
    [string]$TargetDir = 'C:\cargo-target\daozhu',
    [int]$WaitLimitSeconds = 1500
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$log = Join-Path $env:TEMP 'daozhu-build.log'
function Note([string]$text) { $script:line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $text; $line | Out-File -LiteralPath $log -Encoding utf8 -Append; Write-Output $line }

"=== 开始 $(Get-Date -Format o) ===" | Out-File -LiteralPath $log -Encoding utf8

$vsRoot = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools"
$sdkBin = "${env:ProgramFiles(x86)}\Windows Kits\10\bin"
$deadline = (Get-Date).AddSeconds($WaitLimitSeconds)
while ((Get-Date) -lt $deadline) {
    $link = Get-ChildItem -Path (Join-Path $vsRoot 'VC\Tools\MSVC') -Recurse -Filter link.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    $rc = Get-ChildItem -Path $sdkBin -Recurse -Filter rc.exe -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match '\\x64\\' } | Select-Object -First 1
    if ($link -and $rc) { break }
    Start-Sleep -Seconds 20
}
if (-not $link) { Note '工具链等待超时：找不到 link.exe，终止编译'; exit 3 }
if (-not $rc) { Note '工具链等待超时：找不到 rc.exe（Windows SDK），终止编译'; exit 4 }
Note ("link.exe = " + $link.FullName)
Note ("rc.exe   = " + $rc.FullName)

$env:CARGO_TARGET_DIR = $TargetDir
$env:CARGO_BUILD_JOBS = '2'
$cargoHome = if ($env:CARGO_HOME) { $env:CARGO_HOME } else { Join-Path $env:USERPROFILE '.cargo' }
$env:CARGO_ENCODED_RUSTFLAGS = @('-C', 'target-feature=+crt-static', "--remap-path-prefix=$cargoHome=cargo", "--remap-path-prefix=$projectRoot=daozhu", '-C', 'link-arg=/PDBALTPATH:%_PDB%') -join [char]0x1f
$cargo = Join-Path $cargoHome 'bin\cargo.exe'
Note ("cargo = " + $cargo)
Push-Location $projectRoot
try {
    Note '开始 release 编译（--locked, msvc target）'
    & $cargo build --locked --release --bin daozhu --target x86_64-pc-windows-msvc *>> $log
    $code = $LASTEXITCODE
    Note ("编译退出码 = " + $code)
    $exe = Join-Path $TargetDir 'x86_64-pc-windows-msvc\release\daozhu.exe'
    if (Test-Path -LiteralPath $exe) {
        $item = Get-Item -LiteralPath $exe
        Note ("产物 = " + $exe + "  大小 = " + [math]::Round($item.Length / 1MB, 2) + " MB")
        Note ("版本信息 = " + $item.VersionInfo.FileVersion + " / " + $item.VersionInfo.ProductName + " / " + $item.VersionInfo.CompanyName)
    } else {
        Note '编译结束但没有找到 daozhu.exe'
    }
    exit $code
} finally { Pop-Location }
