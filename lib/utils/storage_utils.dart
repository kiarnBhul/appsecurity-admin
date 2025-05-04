import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer' as developer;

/// Utility class for handling Firebase Storage URLs with CORS support
class StorageUtils {
  /// The URL of the server-side proxy
  static const String _proxyServerUrl = '/firebase_proxy.php';

  /// Transforms a Firebase Storage URL to handle CORS issues
  /// This is particularly important for web platforms
  static String getProxiedUrl(String url) {
    if (!kIsWeb || url.isEmpty) {
      return url;
    }

    // For web platform, handle Firebase Storage URLs
    if (url.contains('firebasestorage.googleapis.com')) {
      // Log for debugging
      developer.log('Proxying Firebase Storage URL: $url', name: 'StorageUtils');

      // Make sure the URL has the alt=media parameter for direct download
      if (!url.contains('alt=media')) {
        final separator = url.contains('?') ? '&' : '?';
        url = '$url${separator}alt=media';
      }

      // Use the server-side proxy for Firebase Storage URLs
      final encodedUrl = Uri.encodeComponent(url);
      final proxiedUrl = '$_proxyServerUrl?url=$encodedUrl';

      developer.log('Using server-side proxy: $proxiedUrl', name: 'StorageUtils');
      return proxiedUrl;
    }

    return url;
  }

  /// Creates a data URL from a Firebase Storage URL (for extreme cases)
  /// This is a fallback method when all other approaches fail
  static Future<String?> createDataUrl(String url) async {
    if (!kIsWeb || url.isEmpty) {
      return null;
    }

    try {
      // Use the proxied URL
      final proxiedUrl = getProxiedUrl(url);

      // Use the JS interop to convert to base64
      // This is handled by the cors_proxy.js script
      // The implementation is in the window.getBase64FromFirebaseUrl function

      developer.log('Attempting to create data URL from: $proxiedUrl', name: 'StorageUtils');

      // For now, just return the proxied URL
      // In a real implementation, you would use JS interop to call window.getBase64FromFirebaseUrl
      return proxiedUrl;
    } catch (e) {
      developer.log('Error creating data URL: $e', name: 'StorageUtils');
      return null;
    }
  }
}
