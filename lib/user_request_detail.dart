import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'utils/storage_utils.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserRequestDetailPage extends StatefulWidget {
  final Map<String, dynamic> request;

  const UserRequestDetailPage({super.key, required this.request});

  @override
  _UserRequestDetailPageState createState() => _UserRequestDetailPageState();
}

// Removed dart:html import and using a simpler approach
class SafeImageWidget extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SafeImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  State<SafeImageWidget> createState() => _SafeImageWidgetState();
}

class _SafeImageWidgetState extends State<SafeImageWidget> {
  int _retryCount = 0;
  static const int _maxRetries = 5;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    // If it's a Firebase Storage URL, preload the image to check for CORS issues
    if (widget.imageUrl.contains('firebasestorage.googleapis.com')) {
      _preloadImage();
    } else {
      _isLoading = false;
    }
  }

  void _preloadImage() {
    if (widget.imageUrl.startsWith('LOCAL_PLACEHOLDER:')) {
      _isLoading = false;
      return;
    }

    final proxiedUrl = StorageUtils.getProxiedUrl(widget.imageUrl);
    developer.log('Preloading image: $proxiedUrl', name: 'SafeImageWidget');

    // Use a network image provider to preload
    final imageProvider = NetworkImage(proxiedUrl);

    // Listen for errors
    final imageStream = imageProvider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        developer.log('Image loaded successfully: $proxiedUrl', name: 'SafeImageWidget');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = false;
          });
        }
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        developer.log('Error loading image: $exception', name: 'SafeImageWidget');
        if (_retryCount < _maxRetries) {
          _retryCount++;
          developer.log('Retrying image load ($_retryCount/$_maxRetries): $proxiedUrl', name: 'SafeImageWidget');

          // Try again with a delay
          Future.delayed(Duration(milliseconds: 500 * _retryCount), () {
            if (mounted) {
              _preloadImage();
            }
          });
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          }
        }
      },
    );

    imageStream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    // Handle our special local placeholder URLs
    if (widget.imageUrl.startsWith('LOCAL_PLACEHOLDER:')) {
      String type = widget.imageUrl.substring('LOCAL_PLACEHOLDER:'.length);
      return _buildPlaceholder(type);
    }

    // If still loading, show loading widget
    if (_isLoading) {
      return _buildLoadingWidget(isRetry: _retryCount > 0);
    }

    // If there was an error, show placeholder
    if (_hasError) {
      String type = "Document";
      if (widget.imageUrl.contains('front_document')) {
        type = "Front Document";
      } else if (widget.imageUrl.contains('back_document')) {
        type = "Back Document";
      } else if (widget.imageUrl.contains('payment_screenshot')) {
        type = "Payment Screenshot";
      }
      return _buildPlaceholder(type);
    }

    // Use CachedNetworkImage with Firebase Storage URLs
    if (widget.imageUrl.contains('firebasestorage.googleapis.com')) {
      // Apply CORS proxy to Firebase Storage URLs
      final proxiedUrl = StorageUtils.getProxiedUrl(widget.imageUrl);

      developer.log('Rendering image with CachedNetworkImage: $proxiedUrl', name: 'SafeImageWidget');

      return CachedNetworkImage(
        imageUrl: proxiedUrl,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        fadeInDuration: const Duration(milliseconds: 300),
        httpHeaders: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
          'Access-Control-Allow-Origin': '*',
        },
        cacheKey: '${proxiedUrl}_${DateTime.now().millisecondsSinceEpoch}',
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) {
          developer.log('CachedNetworkImage error: $error for URL: $url', name: 'SafeImageWidget');
          return _buildErrorWidget(error.toString());
        },
      );
    }
    // Direct URL - just display it
    else {
      return Image.network(
        widget.imageUrl,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder("Document");
        },
      );
    }
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            ),
            const SizedBox(height: 8),
            const Text(
              'Failed to load image',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  error,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget({bool isRetry = false}) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (isRetry) ...[
              const SizedBox(height: 8),
              Text(
                'Retrying... ($_retryCount/$_maxRetries)',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String type) {
    Color color = Colors.grey.shade300;
    if (type.contains("Front")) color = const Color(0xFF5C9CDE);
    if (type.contains("Back")) color = const Color(0xFF6EBD6E);
    if (type.contains("Payment")) color = const Color(0xFFF5A95A);

    return Container(
      width: widget.width,
      height: widget.height,
      color: color,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type.contains("Front")
                  ? Icons.contact_page_outlined
                  : type.contains("Back")
                      ? Icons.featured_play_list_outlined
                      : Icons.receipt_long_outlined,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserRequestDetailPageState extends State<UserRequestDetailPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isLoading = true;
  Map<String, String> _documentUrls = {};
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();

    // Set initial placeholders
    _documentUrls = {
      'front_document.jpg': _generatePlaceholderUrl('Front Document'),
      'back_document.jpg': _generatePlaceholderUrl('Back Document'),
      'payment_screenshot.jpg': _generatePlaceholderUrl('Payment Screenshot'),
    };

    // Delay the Firebase operation to ensure UI is responsive first
    Future.delayed(Duration.zero, () async {
      if (!mounted) return;

      // Show loading message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading documents...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Fetch the actual documents
      _generateDefaultDocuments(notifyStateChange: true);

      // Show success message if mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents loaded'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime dateTime;
      if (timestamp is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'N/A';
      }
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildInfoSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5C3D9C),
              ),
            ),
            const Divider(height: 32),
            _buildInfoRow('Full Name', widget.request['fullName'] ?? widget.request['name'] ?? 'N/A'),
            _buildInfoRow('Email', widget.request['email'] ?? 'N/A'),
            _buildInfoRow('Phone', widget.request['phoneNumber'] ?? widget.request['phone'] ?? 'N/A'),
            _buildInfoRow('Gender', widget.request['gender'] ?? 'N/A'),
            _buildInfoRow('Nationality', widget.request['nationality'] ?? 'N/A'),
            _buildInfoRow('Address', widget.request['address'] ?? 'N/A'),
            _buildInfoRow('State', widget.request['state'] ?? 'N/A'),
            _buildInfoRow('City', widget.request['city'] ?? 'N/A'),
            if (widget.request['experience'] != null) _buildInfoRow('Experience', widget.request['experience']),
            if (widget.request['languages'] != null) _buildInfoRow('Languages', widget.request['languages']),
            if (widget.request['skills'] != null)
              _buildInfoRow(
                  'Skills',
                  widget.request['skills'] is List
                ? (widget.request['skills'] as List).join(', ')
                : widget.request['skills'].toString()),
            _buildInfoRow('Document Type', widget.request['documentType'] ?? 'N/A'),
            _buildInfoRow('Payment Method', widget.request['paymentMethod'] ?? 'N/A'),
            _buildInfoRow('Request Date', _formatTimestamp(widget.request['timestamp'])),
            _buildInfoRow('Status', widget.request['status'] ?? 'Pending'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: Color(0xFF5C3D9C),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading documents...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C3D9C).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF5C3D9C),
                      ),
                    ),
                    const SizedBox(width: 16),
                Text(
                  'Documents',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5C3D9C),
                  ),
                ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Preview Mode',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Document samples shown below',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const Divider(height: 32),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: _documentUrls.length,
              itemBuilder: (context, index) {
                final entry = _documentUrls.entries.elementAt(index);
                return _buildDocumentCard(entry.key, entry.value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(String name, String url) {
    String documentType = 'Document';
    Color cardColor = const Color(0xFF5C3D9C).withValues(alpha: 0.1);
    IconData documentIcon = Icons.insert_drive_file_outlined;

    if (name.toLowerCase().contains('front')) {
      documentType = 'Front Document';
      cardColor = const Color(0xFF5C9CDE).withValues(alpha: 0.1);
      documentIcon = Icons.contact_page_outlined;
    } else if (name.toLowerCase().contains('back')) {
      documentType = 'Back Document';
      cardColor = const Color(0xFF6EBD6E).withValues(alpha: 0.1);
      documentIcon = Icons.featured_play_list_outlined;
    } else if (name.toLowerCase().contains('payment')) {
      documentType = 'Payment Screenshot';
      cardColor = const Color(0xFFF5A95A).withValues(alpha: 0.1);
      documentIcon = Icons.receipt_long_outlined;
    }

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBar(
                        title: Text(
                          documentType,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: const Color(0xFF5C3D9C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.download),
                            tooltip: 'Download',
                            onPressed: () {
                              // In a real implementation, you would add download functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Download not available in demo'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                    ),
                    Flexible(
                        child: Stack(
                          children: [
                            InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4,
                        child: SafeImageWidget(
                          imageUrl: url,
                          fit: BoxFit.contain,
                        ),
                            ),
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.zoom_in, color: Colors.white),
                                      onPressed: () {
                                        // In a real app, you would implement zoom in
                                      },
                                      tooltip: 'Zoom In',
                                      iconSize: 20,
                                      constraints: const BoxConstraints(
                                        minWidth: 30,
                                        minHeight: 30,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.zoom_out, color: Colors.white),
                                      onPressed: () {
                                        // In a real app, you would implement zoom out
                                      },
                                      tooltip: 'Zoom Out',
                                      iconSize: 20,
                                      constraints: const BoxConstraints(
                                        minWidth: 30,
                                        minHeight: 30,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.rotate_right, color: Colors.white),
                                      onPressed: () {
                                        // In a real app, you would implement rotation
                                      },
                                      tooltip: 'Rotate',
                                      iconSize: 20,
                                      constraints: const BoxConstraints(
                                        minWidth: 30,
                                        minHeight: 30,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'document-$name',
                    child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                    ),
                    child: SafeImageWidget(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                        'View',
                        style: TextStyle(
                          color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                        ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    documentIcon,
                    size: 18,
                    color: const Color(0xFF5C3D9C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
              child: Text(
                documentType,
                style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF333333),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generate a placeholder image for corrupted images
  String _generatePlaceholderUrl(String type) {
    // Use a special prefix that our SafeImageWidget knows to handle
    // This will be intercepted and rendered as a local widget instead of a network request
    return "LOCAL_PLACEHOLDER:$type";
  }

  // Generate default document placeholders if none are found
  void _generateDefaultDocuments({bool notifyStateChange = true}) async {
    if (!_isMounted) return;

    // Create a map of document URLs with placeholders initially
    final Map<String, String> documentUrls = {
      'front_document.jpg': _generatePlaceholderUrl('Front Document'),
      'back_document.jpg': _generatePlaceholderUrl('Back Document'),
      'payment_screenshot.jpg': _generatePlaceholderUrl('Payment Screenshot'),
    };

    // Get the user's email from the request
    final String email = widget.request['email'] ?? '';
    final String collection = widget.request['collection'] ?? '';

    if (email.isNotEmpty) {
      developer.log('Fetching documents for email: $email, collection: $collection', name: 'UserRequestDetailPage');

      try {
        // Try to fetch the actual images from Firebase Storage
        // Construct the path to the user's documents in Firebase Storage
        String basePath = 'documents';

        // If we have a collection, use it in the path
        if (collection.isNotEmpty) {
          basePath = '$collection/$basePath';
        }

        // Create a sanitized version of the email for use in the path
        final String sanitizedEmail = email.replaceAll('.', '_').replaceAll('@', '_at_');

        // Construct the full paths to the documents
        final String frontDocPath = '$basePath/$sanitizedEmail/front_document.jpg';
        final String backDocPath = '$basePath/$sanitizedEmail/back_document.jpg';
        final String paymentScreenshotPath = '$basePath/$sanitizedEmail/payment_screenshot.jpg';

        developer.log('Attempting to fetch from paths: $frontDocPath, $backDocPath, $paymentScreenshotPath',
            name: 'UserRequestDetailPage');

        // Try to get download URLs for each document
        try {
          final frontDocUrl = await _storage.ref(frontDocPath).getDownloadURL();
          documentUrls['front_document.jpg'] = StorageUtils.getProxiedUrl(frontDocUrl);
          developer.log('Found front document: $frontDocUrl', name: 'UserRequestDetailPage');
        } catch (e) {
          developer.log('Front document not found: $e', name: 'UserRequestDetailPage');

          // Try alternative path
          try {
            final altPath = 'brandhelp/$sanitizedEmail/front_document.jpg';
            final frontDocUrl = await _storage.ref(altPath).getDownloadURL();
            documentUrls['front_document.jpg'] = StorageUtils.getProxiedUrl(frontDocUrl);
            developer.log('Found front document at alt path: $frontDocUrl', name: 'UserRequestDetailPage');
          } catch (e) {
            developer.log('Front document not found at alt path either', name: 'UserRequestDetailPage');
          }
        }

        try {
          final backDocUrl = await _storage.ref(backDocPath).getDownloadURL();
          documentUrls['back_document.jpg'] = StorageUtils.getProxiedUrl(backDocUrl);
          developer.log('Found back document: $backDocUrl', name: 'UserRequestDetailPage');
        } catch (e) {
          developer.log('Back document not found: $e', name: 'UserRequestDetailPage');

          // Try alternative path
          try {
            final altPath = 'brandhelp/$sanitizedEmail/back_document.jpg';
            final backDocUrl = await _storage.ref(altPath).getDownloadURL();
            documentUrls['back_document.jpg'] = StorageUtils.getProxiedUrl(backDocUrl);
            developer.log('Found back document at alt path: $backDocUrl', name: 'UserRequestDetailPage');
          } catch (e) {
            developer.log('Back document not found at alt path either', name: 'UserRequestDetailPage');
          }
        }

        try {
          final paymentUrl = await _storage.ref(paymentScreenshotPath).getDownloadURL();
          documentUrls['payment_screenshot.jpg'] = StorageUtils.getProxiedUrl(paymentUrl);
          developer.log('Found payment screenshot: $paymentUrl', name: 'UserRequestDetailPage');
        } catch (e) {
          developer.log('Payment screenshot not found: $e', name: 'UserRequestDetailPage');

          // Try alternative path
          try {
            final altPath = 'brandhelp/$sanitizedEmail/payment_screenshot.jpg';
            final paymentUrl = await _storage.ref(altPath).getDownloadURL();
            documentUrls['payment_screenshot.jpg'] = StorageUtils.getProxiedUrl(paymentUrl);
            developer.log('Found payment screenshot at alt path: $paymentUrl', name: 'UserRequestDetailPage');
          } catch (e) {
            developer.log('Payment screenshot not found at alt path either', name: 'UserRequestDetailPage');
          }
        }
      } catch (e) {
        developer.log('Error fetching documents from Firebase Storage: $e', name: 'UserRequestDetailPage');
      }
    }

    // Also try to use document URLs if available in the request
    if (widget.request.containsKey('documents')) {
      try {
        final documents = widget.request['documents'];
        if (documents is Map<String, dynamic>) {
          // Process document URLs from the request
          if (documents.containsKey('frontDocument') && documents['frontDocument'] is String) {
            final url = documents['frontDocument'] as String;
            if (url.isNotEmpty) {
              documentUrls['front_document.jpg'] = StorageUtils.getProxiedUrl(url);
            }
          }

          if (documents.containsKey('backDocument') && documents['backDocument'] is String) {
            final url = documents['backDocument'] as String;
            if (url.isNotEmpty) {
              documentUrls['back_document.jpg'] = StorageUtils.getProxiedUrl(url);
            }
          }

          if (documents.containsKey('paymentScreenshot') && documents['paymentScreenshot'] is String) {
            final url = documents['paymentScreenshot'] as String;
            if (url.isNotEmpty) {
              documentUrls['payment_screenshot.jpg'] = StorageUtils.getProxiedUrl(url);
            }
          }
        }
      } catch (e) {
        developer.log('Error processing document URLs from request: $e', name: 'UserRequestDetailPage');
      }
    }

    // Update the state with the document URLs
    if (notifyStateChange) {
      if (!_isMounted) return;
      setState(() {
        _documentUrls = documentUrls;
        _isLoading = false;
      });
    } else {
      _documentUrls = documentUrls;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: const Color(0xFF5C3D9C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoSection(),
            _buildDocumentsSection(),
          ],
        ),
      ),
    );
  }
}
