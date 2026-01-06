import 'package:flutter/material.dart';

class UsedVoucherWidget extends StatefulWidget {
  final List<Map<String, dynamic>> redeemedVouchers;
  final Function(String voucherId)? onVoucherUsed;

  const UsedVoucherWidget({
    super.key,
    required this.redeemedVouchers,
    this.onVoucherUsed,
  });

  @override
  State<UsedVoucherWidget> createState() => _UsedVoucherWidgetState();
}

class _UsedVoucherWidgetState extends State<UsedVoucherWidget> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Active', 'Used', 'Expired'];

  List<Map<String, dynamic>> get _filteredVouchers {
    if (_selectedFilter == 'All') {
      return widget.redeemedVouchers;
    }
    return widget.redeemedVouchers
        .where((voucher) => voucher['status'] == _selectedFilter)
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Used':
        return Colors.blue;
      case 'Expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Active':
        return Icons.check_circle;
      case 'Used':
        return Icons.verified;
      case 'Expired':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  bool _isExpired(String expiryDate) {
    final expiry = DateTime.parse(expiryDate);
    return expiry.isBefore(DateTime.now());
  }

  void _showVoucherDetails(Map<String, dynamic> voucher) {
    final bool isActive = voucher['status'] == 'Active' && !_isExpired(voucher['expiryDate']);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getStatusColor(voucher['status']),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(voucher['status']),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Voucher Details',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Voucher preview
                        Center(
                          child: _buildVoucherTicket(voucher, isPreview: true),
                        ),
                        const SizedBox(height: 24),
                        
                        // Voucher code section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Voucher Code',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[400]!),
                                      ),
                                      child: Text(
                                        voucher['voucherCode'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      // Copy to clipboard functionality
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Voucher code copied to clipboard'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.copy),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.grey[200],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Voucher information
                        _buildInfoCard(
                          'Voucher Information',
                          [
                            'Category: ${voucher['category']}',
                            'Partner Store: ${voucher['partnerStore']}',
                            'Original Points: ${voucher['originalPoints']}',
                            'Status: ${voucher['status']}',
                          ],
                          Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        
                        // Date information
                        _buildInfoCard(
                          'Date Information',
                          [
                            'Redeemed: ${voucher['redeemedDate']}',
                            'Expires: ${voucher['expiryDate']}',
                            if (voucher['usedDate'] != null)
                              'Used: ${voucher['usedDate']}',
                            if (voucher['usedDate'] == null && isActive)
                              'Days remaining: ${DateTime.parse(voucher['expiryDate']).difference(DateTime.now()).inDays}',
                          ],
                          Colors.green,
                        ),
                        
                        // Status warnings
                        if (_isExpired(voucher['expiryDate']) && voucher['status'] != 'Expired') ...[
                          const SizedBox(height: 16),
                          _buildWarningCard(
                            'This voucher has expired',
                            Colors.red,
                            Icons.warning_outlined,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Action buttons
                if (isActive && voucher['usedDate'] == null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _confirmVoucherUsage(voucher);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDE0D0D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Mark as Used',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmVoucherUsage(Map<String, dynamic> voucher) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Mark Voucher as Used?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFDE0D0D),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to mark this voucher as used? This action cannot be undone.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildVoucherTicket(voucher, isSmall: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processVoucherUsage(voucher);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDE0D0D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _processVoucherUsage(Map<String, dynamic> voucher) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Voucher marked as used successfully!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    // Call the callback function if provided - ready for Firebase integration
    if (widget.onVoucherUsed != null) {
      widget.onVoucherUsed!(voucher['id']);
    }
  }

  Widget _buildInfoCard(String title, List<String> details, MaterialColor color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.shade800,
            ),
          ),
          const SizedBox(height: 8),
          ...details.map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              detail,
              style: TextStyle(
                fontSize: 14,
                color: color.shade700,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildWarningCard(String message, MaterialColor color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherTicket(Map<String, dynamic> voucher, {bool isPreview = false, bool isSmall = false}) {
    final double ticketWidth = isSmall ? 200 : (isPreview ? 280 : 120);
    final double ticketHeight = isSmall ? 120 : (isPreview ? 180 : 80);
    final String status = voucher['status'];
    final bool isExpired = _isExpired(voucher['expiryDate']);
    
    Color backgroundColor;
    if (isExpired || status == 'Expired') {
      backgroundColor = Colors.grey[600]!;
    } else if (status == 'Used') {
      backgroundColor = Colors.blue[600]!;
    } else {
      backgroundColor = const Color(0xFFDE0D0D);
    }
    
    return SizedBox(
      width: ticketWidth,
      height: ticketHeight,
      child: CustomPaint(
        painter: TicketPainter(
          backgroundColor: backgroundColor,
          dotColor: Colors.white,
        ),
        child: Container(
          padding: EdgeInsets.all(isSmall ? 12 : (isPreview ? 20 : 8)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                voucher['name'].toString().split(' ')[0], // Extract discount percentage
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 24 : (isPreview ? 32 : 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isSmall) ...[
                const SizedBox(height: 4),
                Text(
                  'OFF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isPreview ? 16 : 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              SizedBox(height: isPreview ? 8 : 2),
              Text(
                voucher['category'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 10 : (isPreview ? 14 : 8),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filterOptions.map((filter) {
              final bool isSelected = _selectedFilter == filter;
              final int count = filter == 'All' 
                  ? widget.redeemedVouchers.length
                  : widget.redeemedVouchers.where((v) => v['status'] == filter).length;
              
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('$filter ($count)'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  selectedColor: const Color(0xFFDE0D0D).withOpacity(0.2),
                  checkmarkColor: const Color(0xFFDE0D0D),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFFDE0D0D) : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Vouchers list
        Expanded(
          child: _filteredVouchers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ${_selectedFilter.toLowerCase()} vouchers found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your redeemed vouchers will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _filteredVouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = _filteredVouchers[index];
                    final bool isExpired = _isExpired(voucher['expiryDate']);
                    
                    return GestureDetector(
                      onTap: () => _showVoucherDetails(voucher),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(voucher['status']).withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Voucher ticket
                            _buildVoucherTicket(voucher),
                            const SizedBox(width: 16),
                            
                            // Voucher details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${voucher['name']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(voucher['status']).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getStatusIcon(voucher['status']),
                                              size: 12,
                                              color: _getStatusColor(voucher['status']),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isExpired && voucher['status'] != 'Expired' 
                                                  ? 'Expired' 
                                                  : voucher['status'],
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(voucher['status']),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${voucher['category']} • ${voucher['partnerStore']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 12,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Redeemed: ${voucher['redeemedDate']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 12,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Expires: ${voucher['expiryDate']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (voucher['usedDate'] != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 12,
                                          color: Colors.blue[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Used: ${voucher['usedDate']}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// Custom painter for ticket shape (reused from redeem_voucher.dart)
class TicketPainter extends CustomPainter {
  final Color backgroundColor;
  final Color dotColor;

  TicketPainter({
    required this.backgroundColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Create ticket shape with rounded corners and side notches
    const radius = 12.0;
    const notchRadius = 8.0;
    const notchPosition = 0.6; // Position of notch from top
    
    // Start from top-left
    path.moveTo(radius, 0);
    
    // Top side
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(
      Offset(size.width, radius),
      radius: const Radius.circular(radius),
    );
    
    // Right side until notch
    path.lineTo(size.width, size.height * notchPosition - notchRadius);
    
    // Right notch
    path.arcToPoint(
      Offset(size.width, size.height * notchPosition + notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    
    // Right side after notch
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: const Radius.circular(radius),
    );
    
    // Bottom side
    path.lineTo(radius, size.height);
    path.arcToPoint(
      Offset(0, size.height - radius),
      radius: const Radius.circular(radius),
    );
    
    // Left side after notch
    path.lineTo(0, size.height * notchPosition + notchRadius);
    
    // Left notch
    path.arcToPoint(
      Offset(0, size.height * notchPosition - notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    
    // Left side until top
    path.lineTo(0, radius);
    path.arcToPoint(
      Offset(radius, 0),
      radius: const Radius.circular(radius),
    );
    
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Draw perforated line
    final dotPaint = Paint()
      ..color = dotColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    const dotRadius = 1.5;
    const dotSpacing = 6.0;
    final lineY = size.height * notchPosition;
    
    for (double x = dotSpacing; x < size.width - dotSpacing; x += dotSpacing) {
      canvas.drawCircle(Offset(x, lineY), dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}