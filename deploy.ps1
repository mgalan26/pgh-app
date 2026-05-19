$env:PATH = $env:PATH + ";C:\Users\Usuario\AppData\Roaming\npm"

Write-Host "Building Flutter web..." -ForegroundColor Cyan
flutter build web --release

Write-Host "Deploying to Vercel..." -ForegroundColor Cyan
Push-Location build\web
vercel --token vcp_4zyxnr1jczVM6v4kCAG06JxfKprMnBneLrOPLmcAZHQxCSJWs50riopf --yes --prod --scope mgalan26s-projects
Pop-Location

Write-Host "Deploy complete! https://agenda.appgh.net" -ForegroundColor Green
