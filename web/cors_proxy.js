// Server-side CORS Proxy for Firebase Storage
function setupCorsProxy() {
  // Only set up once
  if (window.corsProxySetup) return;
  window.corsProxySetup = true;

  console.log('Setting up server-side CORS proxy for Firebase Storage');

  // Define the proxy server URL - change this to your actual proxy server
  // If you're using the PHP proxy, it would be something like '/firebase_proxy.php'
  // If you're using the Node.js proxy, it would be something like 'http://localhost:3000'
  const PROXY_SERVER_URL = '/firebase_proxy.php';

  // Create a proxied URL using the server-side proxy
  function createProxiedUrl(url) {
    if (!url || typeof url !== 'string') return url;

    // Only process Firebase Storage URLs
    if (!url.includes('firebasestorage.googleapis.com')) return url;

    // Use the server-side proxy
    const encodedUrl = encodeURIComponent(url);
    const proxiedUrl = `${PROXY_SERVER_URL}?url=${encodedUrl}`;

    // Log the proxied URL
    console.log('Created server-side proxied URL:', proxiedUrl);
    return proxiedUrl;
  }

  // Intercept fetch requests to Firebase Storage
  const originalFetch = window.fetch;
  window.fetch = function(url, options = {}) {
    if (typeof url === 'string' && url.includes('firebasestorage.googleapis.com')) {
      console.log('Proxying Firebase Storage fetch request:', url);

      // Use the server-side proxy instead
      const proxiedUrl = createProxiedUrl(url);

      // Return the fetch with the proxied URL
      return originalFetch(proxiedUrl, options)
        .catch(error => {
          console.error('Firebase Storage fetch error:', error);

          // Try a different approach if the first one fails - direct with no-cors
          console.log('Trying direct fetch with no-cors as fallback');
          return originalFetch(url, {
            ...options,
            mode: 'no-cors',
            cache: 'no-store'
          }).catch(fallbackError => {
            console.error('Firebase Storage fallback fetch also failed:', fallbackError);
            throw fallbackError;
          });
        });
    }

    // For non-Firebase Storage URLs, use the original fetch
    return originalFetch(url, options);
  };

  // Also intercept XMLHttpRequest
  const originalXhrOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method, url, async = true, user, password) {
    let modifiedUrl = url;

    if (typeof url === 'string' && url.includes('firebasestorage.googleapis.com')) {
      console.log('Proxying Firebase Storage XHR request:', url);

      // Use the server-side proxy
      modifiedUrl = createProxiedUrl(url);
      console.log('Using proxied URL for XHR:', modifiedUrl);

      // Add event listener to handle errors
      this.addEventListener('error', function(e) {
        console.error('XHR error for Firebase Storage:', e);
      });
    }

    // Call the original open method with the modified URL
    return originalXhrOpen.call(this, method, modifiedUrl, async, user, password);
  };

  // Create a global function to get URLs through the proxy
  window.getProxiedUrl = function(url) {
    return createProxiedUrl(url);
  };

  // Add a helper function to check if an image is loaded correctly
  window.checkImageLoaded = function(url, callback) {
    if (!url || typeof url !== 'string') {
      callback(false);
      return;
    }

    // For Firebase Storage URLs, use the proxy directly
    if (url.includes('firebasestorage.googleapis.com')) {
      const proxiedUrl = createProxiedUrl(url);
      const img = new Image();

      img.onload = function() {
        console.log('Image loaded successfully via proxy:', proxiedUrl);
        callback(true);
      };

      img.onerror = function(error) {
        console.error('Image failed to load via proxy:', proxiedUrl, error);
        callback(false);
      };

      img.src = proxiedUrl;
      return;
    }

    // For non-Firebase URLs, try loading directly
    const img = new Image();

    img.onload = function() {
      console.log('Image loaded successfully:', url);
      callback(true);
    };

    img.onerror = function(error) {
      console.error('Image failed to load:', url, error);
      callback(false);
    };

    img.src = url;
  };

  // Add a direct image loader function that uses a data URL fallback
  window.loadImageWithFallback = function(url, imageElement, fallbackUrl) {
    if (!url || typeof url !== 'string') {
      imageElement.src = fallbackUrl;
      return;
    }

    // For Firebase Storage URLs, use the proxy directly
    if (url.includes('firebasestorage.googleapis.com')) {
      const proxiedUrl = createProxiedUrl(url);
      console.log('Loading image via proxy:', proxiedUrl);

      imageElement.onload = function() {
        console.log('Image loaded successfully via proxy:', proxiedUrl);
      };

      imageElement.onerror = function() {
        console.error('Image failed to load via proxy, using fallback:', proxiedUrl);
        imageElement.src = fallbackUrl;
      };

      imageElement.src = proxiedUrl;
      return;
    }

    // For non-Firebase URLs, try loading directly
    imageElement.onload = function() {
      console.log('Image loaded successfully:', url);
    };

    imageElement.onerror = function() {
      console.error('Image failed to load, using fallback:', url);
      imageElement.src = fallbackUrl;
    };

    imageElement.src = url;
  };

  // Add a function to convert Firebase Storage URLs to base64 (for extreme cases)
  window.getBase64FromFirebaseUrl = function(url, callback) {
    if (!url || typeof url !== 'string') {
      callback(null);
      return;
    }

    // Use the server-side proxy
    const proxiedUrl = createProxiedUrl(url);

    fetch(proxiedUrl)
      .then(response => response.blob())
      .then(blob => {
        const reader = new FileReader();
        reader.onloadend = function() {
          callback(reader.result);
        };
        reader.readAsDataURL(blob);
      })
      .catch(error => {
        console.error('Error converting to base64:', error);
        callback(null);
      });
  };
}

// Set up the proxy when the script loads
setupCorsProxy();
