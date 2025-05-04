<?php
// Firebase Storage Proxy
// This script acts as a proxy for Firebase Storage requests to bypass CORS restrictions

// Allow from any origin
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit();
}

// Get the Firebase URL from the query parameter
$firebaseUrl = isset($_GET['url']) ? $_GET['url'] : null;

if (!$firebaseUrl) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing Firebase URL parameter']);
    exit();
}

// Validate the URL (basic check that it's a Firebase Storage URL)
if (strpos($firebaseUrl, 'firebasestorage.googleapis.com') === false) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid Firebase Storage URL']);
    exit();
}

// Make sure the URL has the alt=media parameter for direct download
if (strpos($firebaseUrl, 'alt=media') === false) {
    $separator = strpos($firebaseUrl, '?') !== false ? '&' : '?';
    $firebaseUrl .= $separator . 'alt=media';
}

// Add cache-busting parameter
$cacheBuster = time();
$separator = strpos($firebaseUrl, '?') !== false ? '&' : '?';
$firebaseUrl .= $separator . '_cb=' . $cacheBuster;

// Initialize cURL session
$ch = curl_init();

// Set cURL options
curl_setopt($ch, CURLOPT_URL, $firebaseUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false); // For development only, enable in production
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Origin: https://firebasestorage.googleapis.com',
    'Referer: https://firebasestorage.googleapis.com/',
    'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
]);

// Execute cURL session
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$contentType = curl_getinfo($ch, CURLINFO_CONTENT_TYPE);

// Check for cURL errors
if (curl_errno($ch)) {
    http_response_code(500);
    echo json_encode(['error' => 'cURL error: ' . curl_error($ch)]);
    curl_close($ch);
    exit();
}

// Close cURL session
curl_close($ch);

// Forward the HTTP status code
http_response_code($httpCode);

// Set the content type header
if ($contentType) {
    header("Content-Type: $contentType");
} else {
    // Default to binary data if content type is not detected
    header("Content-Type: application/octet-stream");
}

// Output the response
echo $response;
?>
