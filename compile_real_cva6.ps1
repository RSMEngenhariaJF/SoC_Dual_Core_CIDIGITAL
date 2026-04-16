# PowerShell Script para Compilar e Testar CVA6 Real
# Uso: .\compile_real_cva6.ps1 [test_name]

param(
    [string]$TestName = "base_test",
    [switch]$Verbose = $false,
    [switch]$CleanBuild = $false,
    [switch]$SynthesisOnly = $false
)

# Cores para output
$colors = @{
    Success = 'Green'
    Error = 'Red'
    Warning = 'Yellow'
    Info = 'Cyan'
}

function Write-Status {
    param([string]$Message, [string]$Type = 'Info')
    $color = $colors[$Type]
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] " -ForegroundColor Gray -NoNewline
    Write-Host $Message -ForegroundColor $color
}

# ============================================================================
# SETUP
# ============================================================================

$ProjectRoot = Get-Location
$UvmRoot = Join-Path $ProjectRoot "uvm_tb"
$RtlRoot = Join-Path $ProjectRoot "rtl"
$CoresRoot = Join-Path $RtlRoot "cores"
$Cva6Root = Join-Path $CoresRoot "cva6-master"
$FilesF = Join-Path $CoresRoot "cva6" "files.f"

Write-Status "╔════════════════════════════════════════════════════════════════╗" Info
Write-Status "║      CVA6 Real Core - Compilation and Testing Script          ║" Info
Write-Status "╚════════════════════════════════════════════════════════════════╝" Info

Write-Status "Project Root: $ProjectRoot" Info
Write-Status "Test: $TestName" Info

# ============================================================================
# VALIDATIONS
# ============================================================================

Write-Status "Validating setup..." Info

if (-not (Test-Path $Cva6Root)) {
    Write-Status "ERROR: CVA6 repository not found at $Cva6Root" Error
    exit 1
}

if (-not (Test-Path $FilesF)) {
    Write-Status "ERROR: files.f not found at $FilesF" Error
    Write-Status "Run: python scripts\generate_flist.py" Warning
    exit 1
}

if (-not (Test-Path $UvmRoot)) {
    Write-Status "ERROR: UVM testbench not found at $UvmRoot" Error
    exit 1
}

Write-Status "✓ All paths validated" Success

# ============================================================================
# FILE VALIDATION
# ============================================================================

Write-Status "Validating files.f ..." Info

$LineCount = (Get-Content $FilesF | Measure-Object -Line).Lines
$SvCount = (Get-Content $FilesF | Where-Object { $_ -match '\.sv$|\.v$' } | Measure-Object -Line).Lines

Write-Status "  Files.f contains: $LineCount lines, $SvCount RTL files" Info

if ($SvCount -lt 50) {
    Write-Status "WARNING: Expected >50 RTL files, found $SvCount" Warning
}

# ============================================================================
# CLEAN BUILD (Optional)
# ============================================================================

if ($CleanBuild) {
    Write-Status "Cleaning previous build artifacts..." Warning
    
    Pop-Location
    Push-Location $UvmRoot
    
    if (Test-Path "_work") { Remove-Item -Recurse -Force "_work" }
    if (Test-Path "*.log") { Remove-Item -Force "*.log" }
    if (Test-Path "*.wdb") { Remove-Item -Force "*.wdb" }
    if (Test-Path "dump.vcd") { Remove-Item -Force "dump.vcd" }
    
    Pop-Location
    Write-Status "✓ Cleaned" Success
}

# ============================================================================
# COMPILE
# ============================================================================

Write-Status "Starting compilation..." Info

Push-Location $UvmRoot

$CompileStart = Get-Date

try {
    # Compile command
    if ($Verbose) {
        make compile TEST=$TestName VERBOSE=1
    } else {
        make compile TEST=$TestName
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Status "Compilation FAILED with exit code $LASTEXITCODE" Error
        exit 1
    }
    
} catch {
    Write-Status "Compilation error: $_" Error
    exit 1
}

$CompileDuration = (Get-Date) - $CompileStart
Write-Status "✓ Compilation completed in $($CompileDuration.TotalSeconds) seconds" Success

# ============================================================================
# SIMULATION (Optional)
# ============================================================================

if ($SynthesisOnly) {
    Write-Status "Synthesis-only mode. Skipping simulation." Info
    Pop-Location
    exit 0
}

Write-Status "Starting simulation of test: $TestName" Info

$SimStart = Get-Date

try {
    if ($Verbose) {
        make simulate TEST=$TestName VERBOSE=1
    } else {
        make simulate TEST=$TestName
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Status "Simulation FAILED with exit code $LASTEXITCODE" Error
        Pop-Location
        exit 1
    }
    
} catch {
    Write-Status "Simulation error: $_" Error
    exit 1
}

$SimDuration = (Get-Date) - $SimStart
Write-Status "✓ Simulation completed in $($SimDuration.TotalSeconds) seconds" Success

# ============================================================================
# RESULTS
# ============================================================================

Pop-Location

Write-Status "╔════════════════════════════════════════════════════════════════╗" Info
Write-Status "║                     TEST RESULTS                             ║" Info
Write-Status "╚════════════════════════════════════════════════════════════════╝" Info

Write-Status "Test Name: $TestName" Success
Write-Status "Compilation Time: $($CompileDuration.TotalSeconds)s" Info
Write-Status "Simulation Time: $($SimDuration.TotalSeconds)s" Info

# Check for wave files
$WaveFiles = @(
    (Join-Path $UvmRoot "dump.vcd"),
    (Join-Path $UvmRoot "sim.wdb"),
    (Join-Path $UvmRoot "*_waves.wdb")
)

$WaveFound = $false
foreach ($wave in $WaveFiles) {
    if (Test-Path $wave) {
        Write-Status "Wave file: $wave" Success
        $WaveFound = $true
    }
}

if ($WaveFound) {
    Write-Status "Open waveform with: gtkwave $wave" Info
}

# Check logs
$LogFile = Join-Path $UvmRoot "sim.log"
if (Test-Path $LogFile) {
    Write-Status "Log file: $LogFile" Info
    
    # Search for errors
    $Errors = Select-String "Error|ERROR|ERROR!|FAIL" $LogFile | Measure-Object
    if ($Errors.Count -gt 0) {
        Write-Status "Found $($Errors.Count) potential errors in log" Warning
    } else {
        Write-Status "✓ No errors in log" Success
    }
    
    # Search for coherency-specific messages
    if ($TestName -eq "coherency_test") {
        $Snoops = Select-String "snoop" $LogFile | Measure-Object
        $CoherentOps = Select-String "coherent" $LogFile | Measure-Object
        Write-Status "Snoop operations logged: $($Snoops.Count)" Info
        Write-Status "Coherent operations logged: $($CoherentOps.Count)" Info
    }
}

# ============================================================================
# RECOMMENDATIONS
# ============================================================================

Write-Status "═══════════════════════════════════════════════════════════════" Info
Write-Status "NEXT STEPS:" Info
Write-Status "═══════════════════════════════════════════════════════════════" Info

if ($TestName -eq "base_test") {
    Write-Status "✓ Base test passed - Connection OK" Success
    Write-Status "Next: Run coherency_test" Info
    Write-Status "  .\compile_real_cva6.ps1 -TestName coherency_test" Warning
}
elseif ($TestName -eq "coherency_test") {
    Write-Status "✓ Coherency test completed" Success
    Write-Status "Next: Run stress_test" Info
    Write-Status "  .\compile_real_cva6.ps1 -TestName stress_test" Warning
}
elseif ($TestName -eq "stress_test") {
    Write-Status "✓ Stress test passed - System stable" Success
    Write-Status "Next: Run full test suite" Info
    Write-Status "  cd uvm_tb && make test_all" Warning
}

Write-Status "═══════════════════════════════════════════════════════════════" Info
Write-Status "Build completed successfully!" Success

