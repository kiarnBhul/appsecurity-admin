// Firebase Storage Proxy Server
// This is a simple Node.js server that acts as a proxy for Firebase Storage requests

const http = require('http');
const https = require('https');
const url = require('url');

// Set this to the port you want to run on
const PORT = process.env.PORT || 3000;
// Set this to your frontend origin for better security (or * for any origin)
const ALLOWED_ORIGIN = 'http://localhost:5000';

// Create the server
const server = http.createServer((req, res) => {
  // Set CORS headers - critical for fixing the CORS issues
  res.setHeader('Access-Control-Allow-Origin', ALLOWED_ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Max-Age', '3600');

  // Handle preflight OPTIONS request
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Only allow GET requests
  if (req.method !== 'GET') {
    res.writeHead(405, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Method not allowed' }));
    return;
  }

  // Parse the URL
  const parsedUrl = url.parse(req.url, true);
  const firebaseUrl = parsedUrl.query.url;

  if (!firebaseUrl) {
    res.writeHead(400, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Missing Firebase URL parameter' }));
    return;
  }

  // Validate the URL (basic check that it's a Firebase Storage URL)
  if (!firebaseUrl.includes('firebasestorage.googleapis.com')) {
    res.writeHead(400, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Invalid Firebase Storage URL' }));
    return;
  }

  // Make sure the URL has the alt=media parameter for direct download
  let modifiedUrl = firebaseUrl;
  if (!modifiedUrl.includes('alt=media')) {
    const separator = modifiedUrl.includes('?') ? '&' : '?';
    modifiedUrl += `${separator}alt=media`;
  }

  // Add cache-busting parameter
  const cacheBuster = Date.now();
  const separator = modifiedUrl.includes('?') ? '&' : '?';
  modifiedUrl += `${separator}_cb=${cacheBuster}`;

  console.log(`Proxying request to: ${modifiedUrl}`);

  // Make the request to Firebase Storage
  https.get(modifiedUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Accept': '*/*',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache'
    }
  }, (proxyRes) => {
    // Forward the headers but override CORS headers
    const headers = { ...proxyRes.headers };
    headers['access-control-allow-origin'] = ALLOWED_ORIGIN;
    headers['access-control-allow-methods'] = 'GET, HEAD, OPTIONS';
    headers['access-control-allow-headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization';
    
    // Forward the status code with new headers
    res.writeHead(proxyRes.statusCode, headers);
    
    // Pipe the response data
    proxyRes.pipe(res);
  }).on('error', (err) => {
    console.error('Error fetching from Firebase:', err);
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: `Error fetching from Firebase: ${err.message}` }));
  });
});

// Start the server
server.listen(PORT, () => {
  console.log(`Firebase Storage proxy server running on port ${PORT}`);
  console.log(`Use it by accessing: http://localhost:${PORT}/?url=YOUR_FIREBASE_STORAGE_URL`);
  console.log(`CORS is enabled for origin: ${ALLOWED_ORIGIN}`);
});
