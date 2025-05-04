# Deploy CORS configuration to Firebase Storage using gsutil
Write-Host "Deploying CORS configuration to Firebase Storage using gsutil..."

# Check if gsutil is installed
$gsutilExists = Get-Command gsutil -ErrorAction SilentlyContinue
if (-not $gsutilExists) {
    Write-Host "gsutil is not installed. Please install Google Cloud SDK."
    exit 1
}

# Deploy the CORS configuration
gsutil cors set cors.json gs://fluutersecurity-app.appspot.com

Write-Host "CORS configuration deployed successfully!"
