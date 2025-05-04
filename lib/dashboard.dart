import 'package:flutter/material.dart';
import 'users.dart';
import 'user_requests.dart';
import 'firebase_service.dart';
import 'package:flutter/foundation.dart';
import 'clients_page.dart';
import 'client_detail_view.dart';
import 'settings_page.dart';
import 'admin_access.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // Track selected tab
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _clientDetails = [];
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final clientDetails = await _firebaseService.getClientDetails();
      final jobs = await _firebaseService.getJobs();
      
      setState(() {
        _clientDetails = clientDetails;
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      if (kDebugMode) {
        print('Error fetching dashboard data: $e');
      }
    }
  }

  // Define pages to switch between
  List<Widget> _getPages() {
    return [
      // Dashboard page with ClientDetail and Jobs data
      _buildDashboardContent(),
      const UserRequestsPage(),
      const ClientsPage(),
      UserListScreen(),
      const AdminAccessPage(),
      const SettingsPage(),
    ];
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5C3D9C),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              _buildRefreshButton(),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Clients', 
                  _clientDetails.length.toString(),
                  Icons.people_alt_rounded,
                  const Color(0xFF4A86E8),
                  'clients',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildStatCard(
                  'Total Jobs', 
                  _jobs.length.toString(),
                  Icons.work_rounded,
                  const Color(0xFF43A047),
                  'active jobs',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildStatCard(
                  'Requests', 
                  '${_clientDetails.length + _jobs.length}',
                  Icons.assignment_rounded,
                  const Color(0xFFE67C73),
                  'pending',
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          _buildSectionHeading('Client Details', Icons.people_rounded),
          const SizedBox(height: 16),
          _buildClientDetailsCard(),
          const SizedBox(height: 36),
          _buildSectionHeading('Recent Jobs', Icons.work_rounded),
          const SizedBox(height: 16),
          _buildJobsCard(),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return ElevatedButton.icon(
      onPressed: _fetchDashboardData,
      icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
      label: const Text('Refresh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5C3D9C),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildSectionHeading(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF5C3D9C),
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.85),
            color,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Icon(
                icon,
                color: Colors.white.withOpacity(0.8),
                size: 28,
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _clientDetails.isEmpty
            ? _buildEmptyStateMessage('No client details found')
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTableHeader('ID', flex: 2),
                        _buildTableHeader('Name', flex: 2),
                        _buildTableHeader('Email', flex: 2),
                        _buildTableHeader('Phone', flex: 2),
                        _buildTableHeader('Actions', flex: 1, isLast: true),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _clientDetails.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                    itemBuilder: (context, index) {
                      final client = _clientDetails[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                client['id'] ?? 'N/A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF555555),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                client['name'] ?? 'N/A',
                                style: const TextStyle(
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                client['email'] ?? 'N/A',
                                style: const TextStyle(
                                  color: Color(0xFF555555),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                client['phone'] ?? 'N/A',
                                style: const TextStyle(
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5C3D9C).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                      icon: const Icon(Icons.visibility_rounded, size: 18, color: Color(0xFF5C3D9C)),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ClientDetailView(
                                            client: client,
                                          ),
                                        ),
                                      );
                                    },
                                    tooltip: 'View Details',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
      ),
    );
  }

  Widget _buildJobsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _jobs.isEmpty
            ? _buildEmptyStateMessage('No jobs found')
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTableHeader('ID', flex: 2),
                        _buildTableHeader('Title', flex: 2),
                        _buildTableHeader('Description', flex: 3),
                        _buildTableHeader('Status', flex: 1),
                        _buildTableHeader('Actions', flex: 1, isLast: true),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _jobs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                    itemBuilder: (context, index) {
                      final job = _jobs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                _truncateText(job['id'] ?? 'N/A', 25),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF555555),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                job['title'] ?? 'N/A',
                                style: const TextStyle(
                                  color: Color(0xFF333333),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                job['description'] ?? 'N/A',
                                style: const TextStyle(
                                  color: Color(0xFF555555),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: _buildStatusBadge(job['status'] ?? 'N/A'),
                            ),
                            Expanded(
                              flex: 1,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5C3D9C).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                      icon: const Icon(Icons.visibility_rounded, size: 18, color: Color(0xFF5C3D9C)),
                                    onPressed: () {
                                      // View job details
                                    },
                                    tooltip: 'View Details',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status.toLowerCase()) {
      case 'open':
        backgroundColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        break;
      case 'in progress':
        backgroundColor = const Color(0xFFFFF9C4);
        textColor = const Color(0xFFAF8F00);
        break;
      case 'completed':
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'cancelled':
        backgroundColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      default:
        backgroundColor = const Color(0xFFEEEEEE);
        textColor = const Color(0xFF616161);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableHeader(String title, {required int flex, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF666666),
          fontSize: 14,
        ),
        textAlign: isLast ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  Widget _buildEmptyStateMessage(String message) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();
    
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 240,
            color: const Color(0xFF5C3D9C),
            child: Column(
              children: [
                // App Logo
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 40, 
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.shield,
                            color: Color(0xFF5C3D9C),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Security App',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.person, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                                fontWeight: FontWeight.w600,
                        ),
                      ),
                            SizedBox(height: 2),
                      Text(
                        'admin@gmail.com',
                        style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // MENU Section
                      const Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                        child: Text(
                          'MENU',
                          style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                            fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                          ),
                        ),
                      ),
                ),
                
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 20, 
                  endIndent: 20,
                  color: Colors.white12,
                ),
                
                const SizedBox(height: 12),
                
                // Navigation Menu - Main Items
                _buildNavItem(
                        icon: Icons.dashboard,
                        title: 'Dashboard',
                  index: 0,
                      ),
                _buildNavItem(
                        icon: Icons.notifications,
                        title: 'User Requests',
                  index: 1,
                      ),
                _buildNavItem(
                        icon: Icons.people_alt,
                        title: 'Clients',
                  index: 2,
                      ),
                _buildNavItem(
                        icon: Icons.group,
                        title: 'Users',
                  index: 3,
                ),
                
                const SizedBox(height: 16),
                
                // ADMIN Section
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 20, 
                  endIndent: 20,
                  color: Colors.white12,
                ),
                
                const SizedBox(height: 12),
                
                // Navigation Menu - Admin Items
                _buildNavItem(
                  icon: Icons.admin_panel_settings,
                  title: 'Manage Admins',
                  index: 4,
                      ),
                _buildNavItem(
                        icon: Icons.settings,
                        title: 'Settings',
                  index: 5,
                ),
                
                const Spacer(),
                
                // Yellow Warning Strip
                Container(
                  height: 25,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFC107), Color(0xFFFFAB00)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: WarningStripePainter(),
                  ),
                ),
                
                // Logout Button
                Container(
                  width: double.infinity,
                  color: const Color(0xFF4CAF50),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showLogoutConfirmation(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                letterSpacing: 0.3,
                              ),
                      ),
                    ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right-Side Content (Dynamically Changes)
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FC),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              child: pages[_selectedIndex], // Display selected page
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C3D9C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
              _animationController.reset();
              _animationController.forward();
            });
          },
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WarningStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;
    
    const stripeWidth = 12.0;
    const stripeSpacing = 12.0;
    
    for (double i = -2 * size.width; i < 2 * size.width; i += stripeWidth + stripeSpacing) {
      final path = Path()
        ..moveTo(i, 0)
        ..lineTo(i + stripeWidth, 0)
        ..lineTo(i + stripeWidth + size.height, size.height)
        ..lineTo(i + size.height, size.height)
        ..close();
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
