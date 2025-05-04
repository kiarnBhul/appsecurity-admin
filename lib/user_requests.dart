import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'user_request_detail.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animations/animations.dart';

class UserRequestsPage extends StatefulWidget {
  const UserRequestsPage({super.key});

  @override
  _UserRequestsPageState createState() => _UserRequestsPageState();
}

class _UserRequestsPageState extends State<UserRequestsPage> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _menRequests = [];
  List<Map<String, dynamic>> _womenRequests = [];
  bool _isLoading = true;
  late TabController _tabController;
  String _selectedFilter = 'All';
  
  final List<String> _statusFilters = ['All', 'Pending', 'Approved', 'Rejected'];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _fetchRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final menRequests = await _firebaseService.getMenRequests();
      final womenRequests = await _firebaseService.getWomenRequests();
      
      setState(() {
        _menRequests = menRequests;
        _womenRequests = womenRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (kDebugMode) {
        print('Error fetching requests: $e');
      }
    }
  }

  Future<void> _updateRequestStatus(Map<String, dynamic> request, String collection, String status) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Updating status...'),
              ],
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // Update status in Firestore
      await _firestore.collection(collection).doc(request['id']).update({
        'status': status,
        'lastUpdated': DateTime.now(),
      });
      
      // Refresh data
      await _fetchRequests();
      
      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                status == 'Approved' ? Icons.check_circle : 
                status == 'Rejected' ? Icons.cancel : Icons.pending,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Text('Request status updated to $status'),
            ],
          ),
          backgroundColor: _getStatusColor(status),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(8),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating request status: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 16),
              const Text('Failed to update request status'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(8),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _filterRequestsByStatus(List<Map<String, dynamic>> requests) {
    if (_selectedFilter == 'All') {
      return requests;
    }
    return requests.where((request) => 
      (request['status'] ?? 'Pending').toString() == _selectedFilter
    ).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return const Color(0xFFFF9800);
    }
  }

  Widget _buildRequestsList(List<Map<String, dynamic>> requests, String collection) {
    final filteredRequests = _filterRequestsByStatus(requests);
    
    if (filteredRequests.isEmpty) {
      return _buildEmptyState('No requests found for this filter');
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        final request = filteredRequests[index];
        return _buildRequestCard(request, collection, index);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, String collection, int index) {
        final fullName = request['fullName'] ?? request['name'] ?? 'Unknown';
        final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
        final status = request['status'] ?? 'Pending';
        
    return AnimatedSlide(
      offset: Offset(0, 0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutQuint,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: Duration(milliseconds: 300 + (index * 50)),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: status == 'Rejected' 
                          ? Colors.red.withOpacity(0.05)
                          : status == 'Approved'
                              ? Colors.green.withOpacity(0.05)
                              : Colors.white,
                    ),
                    child: Column(
              children: [
                Row(
                  children: [
                            Hero(
                              tag: 'avatar-${request['id']}',
                              child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C3D9C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Color(0xFF5C3D9C),
                                      fontSize: 22,
                            fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                            fullName,
                            style: const TextStyle(
                                            fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                                        ),
                                      ),
                                      _buildStatusBadge(status),
                                    ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request['email'] ?? 'N/A',
                                    style: TextStyle(
                              fontSize: 14,
                                      color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoTile(
                                Icons.phone_outlined, 
                        'Phone',
                        request['phoneNumber'] ?? request['phone'] ?? 'N/A',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoTile(
                                Icons.calendar_today_outlined,
                        'Request Date',
                        _formatTimestamp(request['timestamp']),
                      ),
                    ),
                  ],
                ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => 
                                  UserRequestDetailPage(request: request),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeScaleTransition(
                                    animation: animation,
                                    child: child,
                                  );
                                },
                          ),
                        );
                      },
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5C3D9C),
                        side: const BorderSide(color: Color(0xFF5C3D9C)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                      ),
                    ),
                    Row(
                      children: [
                        if (status != 'Approved')
                              _buildActionButton(
                                Icons.check_rounded,
                                'Approve',
                                Colors.green,
                                () => _updateRequestStatus(request, collection, 'Approved'),
                          ),
                        if (status != 'Approved' && status != 'Rejected')
                          const SizedBox(width: 8),
                        if (status != 'Rejected')
                              _buildActionButton(
                                Icons.close_rounded,
                                'Reject',
                                Colors.red,
                                () => _updateRequestStatus(request, collection, 'Rejected'),
                              ),
                          ],
                        ),
                      ],
                          ),
                    ),
                  ],
                ),
            ),
          ),
            ),
          ),
        );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      DateTime dateTime;
      if (timestamp is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else {
        return 'N/A';
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.check_circle;
        break;
      case 'rejected':
        backgroundColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        icon = Icons.cancel;
        break;
      case 'pending':
      default:
        backgroundColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFFF9800);
        icon = Icons.pending;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
      children: [
        Icon(
          icon,
          size: 18,
            color: const Color(0xFF5C3D9C),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
            Icons.inbox_outlined,
                size: 60,
            color: Colors.grey[400],
          ),
            ),
            const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
                fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
            const SizedBox(height: 16),
            Text(
              'Pull to refresh or tap the button below',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchRequests,
              icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C3D9C),
              foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with title and refresh button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'User Requests',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFF5C3D9C),
                      ),
                      child: ElevatedButton.icon(
                      onPressed: _fetchRequests,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C3D9C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Status filter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter by status:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                        children: _statusFilters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              }
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: const Color(0xFF5C3D9C).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF5C3D9C) : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                                side: isSelected 
                                  ? const BorderSide(color: Color(0xFF5C3D9C), width: 1) 
                                  : BorderSide.none,
                              ),
                              elevation: isSelected ? 0 : 0,
                              pressElevation: 0,
                            ),
                            ),
                          );
                        }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Tabs for Men/Women
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFEEEEEE),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF5C3D9C),
                  unselectedLabelColor: const Color(0xFF888888),
                  indicatorColor: const Color(0xFF5C3D9C),
                  indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: [
                    Tab(
                        icon: Icon(
                          Icons.man_rounded,
                          color: _tabController.index == 0 
                              ? const Color(0xFF5C3D9C) 
                              : Colors.grey[600],
                        ),
                      text: 'Men',
                    ),
                    Tab(
                        icon: Icon(
                          Icons.woman_rounded,
                          color: _tabController.index == 1 
                              ? const Color(0xFF5C3D9C) 
                              : Colors.grey[600],
                        ),
                      text: 'Women',
                    ),
                  ],
                  ),
                ),
              ],
            ),
          ),
          // Content area with tab view
          Expanded(
            child: _isLoading
                ? _buildLoadingShimmer()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRefreshableList(_menRequests, 'Men'),
                      _buildRefreshableList(_womenRequests, 'Women'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildShimmerBox(50, 50, BorderRadius.circular(12)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(150, 18, BorderRadius.circular(4)),
                          const SizedBox(height: 8),
                          _buildShimmerBox(200, 14, BorderRadius.circular(4)),
                        ],
                      ),
                    ),
                    _buildShimmerBox(80, 28, BorderRadius.circular(20)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildShimmerBox(double.infinity, 40, BorderRadius.circular(8)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildShimmerBox(double.infinity, 40, BorderRadius.circular(8)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildShimmerBox(120, 36, BorderRadius.circular(8)),
                    Row(
                      children: [
                        _buildShimmerBox(100, 36, BorderRadius.circular(8)),
                        const SizedBox(width: 8),
                        _buildShimmerBox(100, 36, BorderRadius.circular(8)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildShimmerBox(double width, double height, BorderRadius borderRadius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[300]!,
            Colors.grey[100]!,
            Colors.grey[300]!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: ShimmerEffect(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: borderRadius,
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshableList(List<Map<String, dynamic>> requests, String collection) {
    return RefreshIndicator(
      onRefresh: _fetchRequests,
      color: const Color(0xFF5C3D9C),
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _buildRequestsList(requests, collection),
      ),
    );
  }
}

class ShimmerEffect extends StatefulWidget {
  final Widget child;
  
  const ShimmerEffect({super.key, required this.child});
  
  @override
  _ShimmerEffectState createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.transparent,
                Colors.white,
                Colors.transparent,
              ],
              stops: [
                _animation.value - 1,
                _animation.value,
                _animation.value + 1,
              ],
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
