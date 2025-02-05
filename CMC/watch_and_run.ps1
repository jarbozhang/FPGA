param(
    [bool]$CLIMode = $false
)

# 新增配置区块
$global:config = @{
    ModelSimPath = "C:\Modelsim_win64_SE_10.5_and_crack\win64"
    ProjectRoot = "C:\Users\OS\Documents\Develop\bfelab\FPGA\CMC"
    DoFilePath = "simulation/modelsim/CMC_run_msim_rtl_verilog.do"
    WatchFolders = @(
        "rtl"
    )
    FileExtensions = @("*.v", "*.sv")
}

# 设置环境变量
$env:Path += ";C:\Modelsim_win64_SE_10.5_and_crack\win64"

# 设置输出编码
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001

# 设置ModelSim路径
$modelsimPath = $config.ModelSimPath

# 设置要监视的文件路径数组
$filePaths = $config.WatchFolders | ForEach-Object {
    $folder = Join-Path $config.ProjectRoot $_
    Get-ChildItem -Path $folder -Recurse -Include $config.FileExtensions | ForEach-Object {
        $_.FullName
    }
}

# 初始化文件最后修改时间的哈希表
$lastWrites = @{}
foreach ($file in $filePaths) {
    $lastWrites[$file] = (Get-Item $file).LastWriteTime
}

# ModelSim执行命令 - 使用Start-Process来执行
$vsimPath = Join-Path $modelsimPath "vsim.exe"

Write-Host "开始监视以下文件:"
$filePaths | ForEach-Object { Write-Host "- $_" }

while ($true) {
    $needsRerun = $false
    
    # 检查每个文件是否有更改
    foreach ($file in $filePaths) {
        $currentWrite = (Get-Item $file).LastWriteTime
        if ($currentWrite -ne $lastWrites[$file]) {
            Write-Host "检测到文件更改: $file"
            $lastWrites[$file] = $currentWrite
            $needsRerun = $true
        }
    }
    
    # 如果有任何文件更改，则重新运行仿真
    if ($needsRerun) {
        Write-Host "重新运行仿真..."
        # 切换到工作目录
        Set-Location -Path $config.ProjectRoot
        
        # 新增：关闭现有ModelSim进程
        try {
            Get-Process vsim -ErrorAction SilentlyContinue | Stop-Process -Force
            Write-Host "已关闭现有ModelSim进程"
        } catch {
            Write-Host "没有找到正在运行的ModelSim进程"
        }

        # 使用Start-Process执行ModelSim命令
        $simArgs = @("-do", "$($config.DoFilePath)")
        if ($CLIMode) {
            $simArgs = @("-c") + $simArgs
        }
        Write-Host "filepath: $vsimPath"
        Write-Host "simArgs: $simArgs"
        Start-Process -FilePath $vsimPath -ArgumentList $simArgs -NoNewWindow -Wait
    }
    
    Start-Sleep -Seconds 1
}