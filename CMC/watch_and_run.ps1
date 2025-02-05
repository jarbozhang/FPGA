# 设置输出编码
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001

# 设置ModelSim路径
$modelsimPath = "C:\Modelsim_win64_SE_10.5_and_crack\win64"  # 替换为你的实际安装路径

# 设置要监视的文件路径数组
$filePaths = @(
    "C:\Users\OS\Documents\Develop\bfelab\FPGA\CMC\rtl\pip_tb.v"
    # "你的文件路径2/dut.v",
    # "你的文件路径3/testbench.v"
)

# 初始化文件最后修改时间的哈希表
$lastWrites = @{}
foreach ($file in $filePaths) {
    $lastWrites[$file] = (Get-Item $file).LastWriteTime
}

# ModelSim执行命令 - 使用Start-Process来执行
$vsimPath = Join-Path $modelsimPath "vsim.exe"
$doCommand = "restart -f; run 10ns; quit -f"

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
        Set-Location -Path "C:\Users\OS\Documents\Develop\bfelab\FPGA\CMC"
        
        # 使用Start-Process执行ModelSim命令
        Start-Process -FilePath $vsimPath -ArgumentList "-c", "-do", $doCommand, "work.pip_tb" -NoNewWindow -Wait
    }
    
    Start-Sleep -Seconds 1
}