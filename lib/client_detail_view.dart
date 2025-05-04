import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientDetailView extends StatefulWidget {
  final Map<String, dynamic> client;

  const ClientDetailView({
    super.key,
    required this.client,
  });

  @override
  _ClientDetailViewState createState() => _ClientDetailViewState();
}

class _ClientDetailViewState extends State<ClientDetailView> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _clientJobs = [];
  bool _isLoading = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _fetchClientJobs();
  }

  Future<void> _fetchClientJobs() async {
    try {
      final jobs = await _firebaseService.getJobsByClientId(widget.client['id']);
      setState(() {
        _clientJobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleVerification() async {
    final isCurrentlyVerified = widget.client['verificationStatus'] == 'Verified';
    
    setState(() {
      _isVerifying = true;
    });

    try {
      await _firebaseService.updateClientVerification(
        widget.client['id'],
        !isCurrentlyVerified,
      );

      // Update the local client data
      setState(() {
        widget.client['isVerified'] = !isCurrentlyVerified;
        widget.client['verificationStatus'] = !isCurrentlyVerified ? 'Verified' : 'Pending';
        widget.client['verifiedAt'] = !isCurrentlyVerified ? DateTime.now().toIso8601String() : null;
        widget.client['verificationSubmittedAt'] = !isCurrentlyVerified ? DateTime.now().toIso8601String() : null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !isCurrentlyVerified
                  ? 'Client profile verified successfully'
                  : 'Client profile verification removed',
            ),
            backgroundColor: !isCurrentlyVerified ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update verification status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Widget _buildVerificationBadge() {
    final isVerified = widget.client['verificationStatus'] == 'Verified';
    final verificationStatus = widget.client['verificationStatus'] ?? 'Pending';
    final verifiedAt = widget.client['verifiedAt'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: verificationStatus == 'Verified' 
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: verificationStatus == 'Verified'
              ? const Color(0xFF81C784)
              : const Color(0xFFFFB74D),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verificationStatus == 'Verified'
                    ? Icons.verified_user
                    : Icons.pending,
                color: verificationStatus == 'Verified'
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFF57C00),
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    verificationStatus == 'Verified'
                        ? 'Verified Profile'
                        : 'Verification $verificationStatus',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: verificationStatus == 'Verified'
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFF57C00),
                    ),
                  ),
                  if (widget.client['verificationInfo'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Name: ${widget.client['verificationInfo']['name'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              _isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5C3D9C)),
                      ),
                    )
                  : TextButton(
                      onPressed: _toggleVerification,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF5C3D9C),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(verificationStatus == 'Verified' ? 'Unverify' : 'Verify Now'),
                    ),
            ],
          ),
          if (verificationStatus == 'Verified' && verifiedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Verified on ${DateFormat('MMM d, yyyy').format(
                verifiedAt is String 
                    ? DateTime.parse(verifiedAt)
                    : (verifiedAt as Timestamp).toDate(),
              )}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ],
          if (widget.client['verificationSubmittedAt'] != null && verificationStatus != 'Verified') ...[
            const SizedBox(height: 8),
            Text(
              'Submitted on ${DateFormat('MMM d, yyyy').format(
                (widget.client['verificationSubmittedAt'] as Timestamp).toDate(),
              )}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsSection() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5C3D9C),
        ),
      );
    }

    if (_clientJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No jobs found for this client',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _clientJobs.length,
      itemBuilder: (context, index) {
        final job = _clientJobs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              job['title'] ?? 'Untitled Job',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  job['description'] ?? 'No description',
                  style: const TextStyle(color: Color(0xFF666666)),
                ),
                const SizedBox(height: 8),
                _buildStatusBadge(job['status'] ?? 'N/A'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                // TODO: Navigate to job details
              },
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Client Details',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // TODO: Implement edit functionality
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF5C3D9C),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF5C3D9C).withOpacity(0.1),
                  child: Text(
                    (widget.client['name'] ?? 'N/A')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF5C3D9C),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.client['name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.client['email'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildVerificationBadge(),
            const SizedBox(height: 32),
            _buildInfoCard(
              'Personal Information',
              [
                _buildInfoRow('Phone', widget.client['phone'] ?? 'N/A'),
                _buildInfoRow('Location', widget.client['location'] ?? 'N/A'),
                _buildInfoRow('Joined Date', widget.client['joinedDate'] ?? 'N/A'),
                _buildInfoRow('Status', widget.client['status'] ?? 'Active'),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              'Jobs History',
              [_buildJobsSection()],
            ),
          ],
        ),
      ),
    );
  }
} 