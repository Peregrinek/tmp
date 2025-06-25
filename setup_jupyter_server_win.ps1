# PowerShell 脚本：setup_jupyter_server_win.ps1
# 请以管理员权限运行，或使用 VS Code PowerShell 执行

# -------- 参数部分 --------
$condaEnvName = "mlenv"
$pythonVersion = "3.10"
$jupyterPort = 8888
$jupyterPassword = "your_password"
$minicondaUrl = "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe"
$minicondaInstaller = "$env:TEMP\Miniconda3Installer.exe"
$minicondaTarget = "$env:USERPROFILE\Miniconda3"

# -------- 安装 Miniconda --------
if (-Not (Test-Path "$minicondaTarget\Scripts\conda.exe")) {
    Write-Output "🔧 安装 Miniconda..."
    Invoke-WebRequest -Uri $minicondaUrl -OutFile $minicondaInstaller
    Start-Process -FilePath $minicondaInstaller -ArgumentList "/InstallationType=JustMe", "/RegisterPython=0", "/AddToPath=0", "/S", "/D=$minicondaTarget" -Wait
} else {
    Write-Output "✅ Miniconda 已安装"
}

# 初始化 Conda
$env:Path = "$minicondaTarget\Scripts;$minicondaTarget;$env:Path"

# 创建 Conda 环境
$envList = conda env list
if ($envList -match $condaEnvName) {
    Write-Output "✅ Conda 环境已存在"
} else {
    Write-Output "🔧 创建环境 $condaEnvName"
    conda create -y -n $condaEnvName python=$pythonVersion
}

conda activate $condaEnvName
conda install -y jupyter numpy pandas matplotlib scikit-learn

# 获取 ZeroTier IP
$zetIP = Get-NetIPAddress | Where-Object { $_.IPAddress -like "10.144.*" -and $_.AddressFamily -eq 'IPv4' } | Select-Object -ExpandProperty IPAddress
if (-not $zetIP) {
    Write-Error "❌ 未找到 ZeroTier IP，请检查 ZeroTier 是否已连接"
    exit 1
}
Write-Output "✅ ZeroTier IP: $zetIP"

# 生成 Jupyter config
jupyter server --generate-config

# 设置密码
$hashedPassword = python -c "from notebook.auth import passwd; print(passwd('$jupyterPassword'))"

$configPath = "$env:USERPROFILE\.jupyter\jupyter_server_config.py"

Add-Content $configPath "`nc.ServerApp.ip = '$zetIP'"
Add-Content $configPath "`nc.ServerApp.port = $jupyterPort"
Add-Content $configPath "`nc.ServerApp.open_browser = False"
Add-Content $configPath "`nc.ServerApp.password = u'$hashedPassword'"

# 启动 Jupyter Server（后台运行）
Start-Process "cmd.exe" "/c conda activate $condaEnvName && jupyter server" -WindowStyle Hidden

Write-Host "`n✅ Jupyter Server 已启动，可用于 VS Code 连接"
Write-Host "🔗 地址: http://$zetIP:$jupyterPort"
Write-Host "🔐 密码: $jupyterPassword"
