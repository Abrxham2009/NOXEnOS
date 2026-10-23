# ==============================================================================
# NOXEnOS Windows Build Orchestrator
# Triggers the ISO compilation via WSL2 or Docker directly from Windows PowerShell.
# ==============================================================================

param(
    [ValidateSet("auto", "wsl", "docker")]
    [string]$Engine = "auto"
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "    NOXEnOS Linux - Orquestador de Compilación Windows    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$projectDir = (Get-Item "$PSScriptRoot\..").FullName
$hasDocker = (Get-Command docker -ErrorAction SilentlyContinue) -ne $null
$hasWsl = (Get-Command wsl -ErrorAction SilentlyContinue) -ne $null

if ($Engine -eq "auto") {
    if ($hasDocker) {
        $Engine = "docker"
    } elseif ($hasWsl) {
        $Engine = "wsl"
    } else {
        $Engine = "none"
    }
}

Write-Host "[*] Motor de compilación seleccionado: $Engine" -ForegroundColor Green

switch ($Engine) {
    "docker" {
        Write-Host "[*] Ejecutando compilación mediante contenedor Docker..." -ForegroundColor Cyan
        & "$PSScriptRoot\build-in-docker.sh"
    }
    "wsl" {
        Write-Host "[*] Comprobando distribución WSL..." -ForegroundColor Cyan
        $wslDistros = wsl --list --quiet 2>$null
        if (-not $wslDistros) {
            Write-Host "[!] No hay distribuciones WSL instaladas." -ForegroundColor Yellow
            Write-Host "    Para instalar Ubuntu en WSL, ejecuta en PowerShell como Administrador:"
            Write-Host "    wsl --install -d Ubuntu-24.04" -ForegroundColor White
            exit 1
        }
        Write-Host "[*] Lanzando build-iso.sh dentro de WSL..." -ForegroundColor Cyan
        $wslPath = $projectDir.Replace("\", "/").Replace("C:", "/mnt/c")
        wsl -u root -- cd "$wslPath" "&&" bash scripts/build-iso.sh
    }
    default {
        Write-Host "[!] No se detectó Docker ni WSL activo en el sistema Windows." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Opciones recomendadas para compilar la ISO:" -ForegroundColor White
        Write-Host "1. Instalar WSL 2 (Recomendado):" -ForegroundColor Cyan
        Write-Host "   wsl --install -d Ubuntu-24.04" -ForegroundColor Gray
        Write-Host "   Una vez instalado, abre Ubuntu y ejecuta:" -ForegroundColor Gray
        Write-Host "   cd /mnt/c/Users/Abraham/Downloads/NOXEnOS && sudo bash scripts/build-iso.sh" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2. Usar una máquina virtual Linux en VirtualBox:" -ForegroundColor Cyan
        Write-Host "   Crea una VM con Ubuntu 24.04, comparte esta carpeta y corre build-iso.sh." -ForegroundColor Gray
        Write-Host ""
        Write-Host "3. Usar GitHub Actions CI/CD:" -ForegroundColor Cyan
        Write-Host "   Sube el repositorio y deja que los runners de Ubuntu compilen la ISO automáticamente." -ForegroundColor Gray
    }
}
