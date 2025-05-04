# Deploy CORS configuration to Firebase Storage
Write-Host "Deploying CORS configuration to Firebase Storage..."

# First, make sure we're logged in
firebase login --no-localhost

# Deploy the CORS configuration
firebase storage:cors set cors.json --project fluutersecurity-app

Write-Host "CORS configuration deployed successfully!"
