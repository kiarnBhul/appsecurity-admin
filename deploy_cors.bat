@echo off
echo Deploying CORS configuration to Firebase Storage...

REM Make sure the Firebase CLI is installed
where firebase >nul 2>nul
if %ERRORLEVEL% neq 0 (
  echo Firebase CLI not found. Please install it with: npm install -g firebase-tools
  exit /b 1
)

REM Check if the user is logged in
firebase projects:list >nul 2>nul
if %ERRORLEVEL% neq 0 (
  echo Please log in to Firebase first with: firebase login
  exit /b 1
)

REM Deploy the CORS configuration
echo Deploying CORS configuration from cors.json...
gsutil cors set cors.json gs://YOUR_FIREBASE_STORAGE_BUCKET

echo CORS configuration deployed successfully!
echo.
echo Please replace 'YOUR_FIREBASE_STORAGE_BUCKET' in this script with your actual Firebase Storage bucket name.
echo You can find your bucket name in the Firebase Console under Storage.
echo.
echo After updating the script, run it again to deploy the CORS configuration.

pause
