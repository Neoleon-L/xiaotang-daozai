param([switch]$Silent)
$ErrorActionPreference='Stop'
try { Add-Type -AssemblyName System.Windows.Forms } catch {}

function Ask-User([string]$text, [string]$title, [string]$buttons, [string]$icon) {
    if ($Silent) { return 'Yes' }
    try { return [System.Windows.Forms.MessageBox]::Show($text, $title, $buttons, $icon).ToString() } catch { return 'Yes' }
}

$installDir=[System.IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs\Daozhu'))
if([System.IO.Path]::GetFullPath($PSScriptRoot) -ne $installDir){throw '卸载脚本只能在岛主安装目录中运行。'}
$exePath=Join-Path $installDir 'daozhu.exe'

$answer = Ask-User "确定要卸载 岛主 Daozhu 吗？`r`n`r`n将删除程序文件、桌面与开始菜单快捷方式以及卸载入口。`r`n你的设置、待办、饮水记录和置物记录仍保留在 %APPDATA%\Daozhu，不会被删除。`r`n`r`n是否继续卸载？" '卸载 岛主 Daozhu' 'YesNo' 'Warning'
if($answer -ne 'Yes'){
    if(-not $Silent){ [System.Windows.Forms.MessageBox]::Show('已取消卸载，程序保持原样。','已取消','OK','Information') | Out-Null }
    exit 0
}

Get-Process daozhu -ErrorAction SilentlyContinue | Where-Object {$_.Path -eq $exePath} | ForEach-Object {
    $null=$_.CloseMainWindow();if(-not $_.WaitForExit(3000)){Stop-Process -Id $_.Id}
}
$shell=New-Object -ComObject WScript.Shell
$links=@((Join-Path $shell.SpecialFolders.Item('Desktop') '岛主.lnk'),(Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\岛主.lnk'),(Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\岛主设置.lnk'))
foreach($path in $links){if((Test-Path -LiteralPath $path) -and $shell.CreateShortcut($path).TargetPath -eq $exePath){Remove-Item -LiteralPath $path}}
$runKey='HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
Remove-ItemProperty -Path $runKey -Name Daozhu -ErrorAction SilentlyContinue
Remove-Item -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Daozhu' -ErrorAction SilentlyContinue
foreach($name in @('daozhu.exe','daozhu-previous.exe','daozhu-v0.2-backup.exe','THIRD_PARTY_NOTICES.txt','LICENSE','uninstall.ps1')){
    $path=Join-Path $installDir $name;if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $path}
}
if(-not(Get-ChildItem -LiteralPath $installDir -Force -ErrorAction SilentlyContinue)){Remove-Item -LiteralPath $installDir -ErrorAction SilentlyContinue}

if(-not $Silent){
    [System.Windows.Forms.MessageBox]::Show("岛主 已卸载。`r`n`r`n你的设置、待办、饮水与置物记录仍保存在 %APPDATA%\Daozhu。",'卸载完成','OK','Information') | Out-Null
}else{
    Write-Output '岛主已卸载。待办、饮水记录和设置仍保存在本机用户数据目录中。'
}
