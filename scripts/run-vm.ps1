# ==============================================================================
# NOXEnOS VirtualBox VM Runner
# Creates and boots a VirtualBox virtual machine to test NOXEnOS Linux ISO.
# ==============================================================================

param(
    [string]$IsoPath = "$PSScriptRoot\..\output\NOXEnOS.iso",
    [string]$VmName = "NOXEnOS-Test",
    [int]$RamMB = 4096,
    [int]$CpuCount = 2,
    [int]$DiskSizeMB = 25600,
    [switch]$DryRun,
    [switch]$Headless
)

$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   NOXEnOS Linux - Lanzador de Prueba VirtualBox  " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Verify VBoxManage exists
if (-not (Test-Path $VBoxManage)) {
    Write-Error "No se encontró VirtualBox en '$VBoxManage'. Asegúrate de tener Oracle VirtualBox instalado."
    exit 1
}

# 2. Verify ISO exists
if (-not (Test-Path $IsoPath)) {
    Write-Warning "El archivo ISO '$IsoPath' aún no ha sido generado."
    Write-Host "Para compilar la ISO, ejecuta 'scripts/build-iso.sh' en un entorno Linux (WSL, Docker o VM)." -ForegroundColor Yellow
    if (-not $DryRun) {
        exit 1
    }
}

Write-Host "[*] ISO seleccionada: $IsoPath" -ForegroundColor Green
Write-Host "[*] Nombre de la máquina virtual: $VmName" -ForegroundColor Green
Write-Host "[*] Memoria RAM: $RamMB MB | CPUs: $CpuCount" -ForegroundColor Green

if ($DryRun) {
    Write-Host "[+] Modo Dry-Run verificado con éxito. Los parámetros son válidos." -ForegroundColor Green
    exit 0
}

# 3. Check if VM already exists
$existingVMs = & $VBoxManage list vms
$vmExists = $existingVMs -match """$VmName"""

if ($vmExists) {
    Write-Host "[*] La máquina virtual '$VmName' ya existe. Deteniendo si está en ejecución..." -ForegroundColor Yellow
    & $VBoxManage controlvm $VmName poweroff 2>$null
    Start-Sleep -Seconds 1
} else {
    Write-Host "[*] Creando nueva máquina virtual '$VmName'..." -ForegroundColor Cyan
    & $VBoxManage createvm --name $VmName --ostype "Ubuntu_64" --register
    
    # Configure base hardware
    & $VBoxManage modifyvm $VmName `
        --memory $RamMB `
        --cpus $CpuCount `
        --vram 128 `
        --graphicscontroller vmsvga `
        --accelerate3d on `
        --boot1 dvd `
        --boot2 disk `
        --boot3 none `
        --boot4 none `
        --audio-controller hda `
        --nic1 nat `
        --clipboard-mode bidirectional `
        --draganddrop bidirectional

    # Setup storage controller
    & $VBoxManage storagectl $VmName --name "SATA" --add sata --controller IntelAHCI --portcount 2

    # Create virtual hard drive for test installation
    $diskPath = Join-Path (Split-Path $IsoPath) "NOXEnOS-TestDisk.vdi"
    if (-not (Test-Path $diskPath)) {
        Write-Host "[*] Creando disco virtual de prueba (${DiskSizeMB} MB)..." -ForegroundColor Cyan
        & $VBoxManage createmedium disk --filename $diskPath --size $DiskSizeMB --format VDI
    }
    & $VBoxManage storageattach $VmName --storagectl "SATA" --port 0 --device 0 --type hdd --medium $diskPath
}

# Attach the ISO
Write-Host "[*] Conectando imagen ISO al lector DVD..." -ForegroundColor Cyan
& $VBoxManage storageattach $VmName --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium $IsoPath

# Start the VM
$startType = if ($Headless) { "headless" } else { "gui" }
Write-Host "[*] Iniciando máquina virtual '$VmName' ($startType)..." -ForegroundColor Green
& $VBoxManage startvm $VmName --type $startType

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " ¡Máquina virtual de prueba iniciada con éxito!   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
