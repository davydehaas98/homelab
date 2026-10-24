# Restarts the Podman machine when `podman` cannot connect ("actively refused"): the WSL machine can run with nothing
# listening on its SSH port, and every start picks a new port. Run it in PowerShell; it does nothing when Podman answers.
#
# Usage: pwsh .devcontainer/podman-fix.ps1

podman ps *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Podman answers"
    exit 0
}

Write-Host "Podman does not answer, restarting the machine.."
podman machine stop
Start-Sleep -Seconds 5
podman machine start

podman ps *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Podman still does not answer"
    exit 1
}
Write-Host "Podman answers; restart VS Code or reopen the dev container so it reads the new port"
