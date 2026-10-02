param([switch]$Build, [switch]$Recreate)

$ErrorActionPreference = 'Stop'
$workspace = Join-Path $PSScriptRoot 'ros2_ws'
$image = 'robotica_inteligente_grado:latest'
$container = 'robotica_inteligente_grado'

New-Item -ItemType Directory -Force -Path $workspace | Out-Null
$xserver = 'C:\Program Files\VcXsrv\vcxsrv.exe'
if ((Test-Path $xserver) -and -not (Get-Process vcxsrv -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $xserver -ArgumentList @(':0', '-multiwindow', '-clipboard', '-ac', '-listen', 'tcp', '-nowgl') -WindowStyle Hidden
    Start-Sleep -Seconds 2
}
docker info --format '{{.ServerVersion}}' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Arranca Docker Desktop antes de ejecutar este script.' }

$imageExists = @(docker image ls --format '{{.Repository}}:{{.Tag}}' | Where-Object { $_ -eq $image }).Count -gt 0
if ($Build -or -not $imageExists) {
    docker build --progress=plain -t $image $PSScriptRoot
    if ($LASTEXITCODE -ne 0) { throw 'La construcción de la imagen ha fallado.' }
}

$containerExists = @(docker container ls -a --format '{{.Names}}' | Where-Object { $_ -eq $container }).Count -gt 0
if ($Recreate -and $containerExists) {
    docker rm -f $container | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'No se ha podido sustituir el contenedor.' }
    $containerExists = $false
}
if (-not $containerExists) {
    docker run -dit --name $container `
        --mount "type=bind,source=$workspace,target=/home/developer/ros2_ws" `
        --hostname robotica-jazzy `
        --shm-size 2g `
        -e DISPLAY=host.docker.internal:0.0 `
        -e LIBGL_ALWAYS_SOFTWARE=1 `
        $image
    if ($LASTEXITCODE -ne 0) { throw 'No se ha podido crear el contenedor.' }
} elseif ((docker inspect -f '{{.State.Running}}' $container) -ne 'true') {
    docker start $container | Out-Null
}

if ($Build -and $containerExists -and -not $Recreate) {
    Write-Warning 'La imagen se ha reconstruido, pero el contenedor existente usa la imagen anterior. Ejecuta con -Recreate para sustituirlo.'
}

Write-Host 'Abriendo shell ROS 2. Para nuevas terminales: docker exec -it robotica_inteligente_grado bash'
docker exec -it $container bash
