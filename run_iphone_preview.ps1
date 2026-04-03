# ShowTickets — Flutter web + iPhone frame preview
# Opens instructions, then starts the dev server. Use the URL printed below.
param(
  [int]$Port = 8080
)

Set-Location $PSScriptRoot

Write-Host ""
Write-Host "After the server starts, open:" -ForegroundColor Cyan
Write-Host "  http://localhost:$Port/iphone_preview.html" -ForegroundColor Yellow
Write-Host ""
Write-Host "If binding fails (port in use), free $Port or run:" -ForegroundColor DarkGray
Write-Host "  .\run_iphone_preview.ps1 -Port 8081" -ForegroundColor DarkGray
Write-Host ""

flutter run -d web-server --web-hostname=localhost --web-port=$Port
