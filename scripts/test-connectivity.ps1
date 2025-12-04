# ======================================================
# Continental Dashboard - Test de Conectividad (PowerShell)
# ======================================================

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Continental Dashboard" -ForegroundColor Cyan
Write-Host "  Connectivity Test" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Cargar variables de entorno desde .env
$envFile = Join-Path $PSScriptRoot "..\..env"
if (-not (Test-Path $envFile)) {
    $envFile = Join-Path $PSScriptRoot "..\.env"
}

if (-not (Test-Path $envFile)) {
    Write-Host "Error: .env file not found" -ForegroundColor Red
    exit 1
}

# Parsear .env
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

$failures = 0

# Función para test TCP
function Test-TcpConnection {
    param(
        [string]$Host,
        [int]$Port,
        [string]$Name
    )
    
    Write-Host "Testing $Name ($Host`:$Port)... " -NoNewline
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($Host, $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne(3000, $false)
        
        if ($wait) {
            $tcpClient.EndConnect($connect)
            $tcpClient.Close()
            Write-Host "✓ OK" -ForegroundColor Green
            return $true
        } else {
            $tcpClient.Close()
            Write-Host "✗ FAILED (timeout)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ FAILED ($_)" -ForegroundColor Red
        return $false
    }
}

# Función para test HTTP
function Test-HttpConnection {
    param(
        [string]$Url,
        [string]$Name
    )
    
    Write-Host "Testing $Name ($Url)... " -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        Write-Host "✓ OK (Status: $($response.StatusCode))" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ FAILED" -ForegroundColor Red
        return $false
    }
}

# ========== KAFKA ==========
Write-Host ""
Write-Host "=== Kafka Cluster ===" -ForegroundColor Yellow
$kafkaBrokers = $env:KAFKA_BROKERS
if ($kafkaBrokers) {
    $brokers = $kafkaBrokers -split ','
    foreach ($broker in $brokers) {
        $broker = $broker.Trim()
        $parts = $broker -split ':'
        $host = $parts[0]
        $port = [int]$parts[1]
        
        if (-not (Test-TcpConnection -Host $host -Port $port -Name "Kafka Broker")) {
            $failures++
        }
    }
} else {
    Write-Host "Warning: KAFKA_BROKERS not set" -ForegroundColor Yellow
}

# ========== MySQL Master ==========
Write-Host ""
Write-Host "=== MySQL Master ===" -ForegroundColor Yellow
$dbMasterHost = $env:DB_MASTER_HOST
$dbMasterPort = if ($env:DB_MASTER_PORT) { [int]$env:DB_MASTER_PORT } else { 3306 }

if ($dbMasterHost) {
    if (-not (Test-TcpConnection -Host $dbMasterHost -Port $dbMasterPort -Name "MySQL Master")) {
        $failures++
    }
} else {
    Write-Host "Warning: DB_MASTER_HOST not set" -ForegroundColor Yellow
}

# ========== MySQL Slave ==========
Write-Host ""
Write-Host "=== MySQL Slave ===" -ForegroundColor Yellow
$dbSlaveHost = $env:DB_SLAVE_HOST
$dbSlavePort = if ($env:DB_SLAVE_PORT) { [int]$env:DB_SLAVE_PORT } else { 3306 }

if ($dbSlaveHost) {
    if (-not (Test-TcpConnection -Host $dbSlaveHost -Port $dbSlavePort -Name "MySQL Slave")) {
        $failures++
    }
} else {
    Write-Host "Warning: DB_SLAVE_HOST not set" -ForegroundColor Yellow
}

# ========== Kong Gateway ==========
Write-Host ""
Write-Host "=== Kong Gateway ===" -ForegroundColor Yellow
$kongUrl = $env:KONG_GATEWAY_URL

if ($kongUrl) {
    if (-not (Test-HttpConnection -Url $kongUrl -Name "Kong Gateway")) {
        $failures++
    }
} else {
    Write-Host "Warning: KONG_GATEWAY_URL not set" -ForegroundColor Yellow
}

# ========== DNS Resolution ==========
Write-Host ""
Write-Host "=== DNS Resolution ===" -ForegroundColor Yellow

$hostsToResolve = @()
if ($dbMasterHost) { $hostsToResolve += $dbMasterHost }
if ($dbSlaveHost) { $hostsToResolve += $dbSlaveHost }

if ($kafkaBrokers) {
    $brokers = $kafkaBrokers -split ','
    foreach ($broker in $brokers) {
        $host = ($broker.Trim() -split ':')[0]
        $hostsToResolve += $host
    }
}

foreach ($hostName in $hostsToResolve | Select-Object -Unique) {
    Write-Host "Resolving $hostName... " -NoNewline
    try {
        $null = [System.Net.Dns]::GetHostAddresses($hostName)
        Write-Host "✓ OK" -ForegroundColor Green
    } catch {
        Write-Host "✗ FAILED" -ForegroundColor Red
        $failures++
    }
}

# ========== Resumen ==========
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
if ($failures -eq 0) {
    Write-Host "✓ All tests passed!" -ForegroundColor Green
    Write-Host "The system is ready to operate." -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ $failures test(s) failed" -ForegroundColor Red
    Write-Host "Please check network configuration and service availability." -ForegroundColor Red
    exit 1
}
