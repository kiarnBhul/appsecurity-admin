@echo off
echo Starting Firebase Storage Proxy Server...

REM Install required dependencies if not already installed
echo Checking for required Node.js modules...
npm list http https url || npm install http https url

REM Start the proxy server
echo Starting proxy server on port 3000...
node firebase_proxy_server.js

echo Server running at http://localhost:3000 