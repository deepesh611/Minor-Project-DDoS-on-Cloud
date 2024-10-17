# Check if Python is installed
if (-not (Get-Command python3 -ErrorAction SilentlyContinue)) {
    Write-Host "Python3 is not installed." -ForegroundColor Red
    exit 1
}
else {
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        python3 --version
    } else {
        python --version
    }
    Write-Host ""
}

Set-Location -Path "./src"
Start-Process -FilePath "python" -ArgumentList "./catchup.py" -NoNewWindow -Wait
Set-Location -Path ".."