import 'package:flutter/material.dart';

class RedeemVoucherWidget extends StatefulWidget {
  final int userPoints;
  final List<Map<String, dynamic>> availableVouchers;
  final Function(String, int, String, String) onRedeem;

  const RedeemVoucherWidget({
    super.key,
    required this.userPoints,
    required this.availableVouchers,
    required this.onRedeem,
  });

  @override
  State<RedeemVoucherWidget> createState() => _RedeemVoucherWidgetState();
}

class _RedeemVoucherWidgetState extends State<RedeemVoucherWidget> {
  String _selectedCategory = 'All';

  List<Map<String, dynamic>> get _filteredVouchers {
    if (_selectedCategory == 'All') {
      return widget.availableVouchers;
    }
    return widget.availableVouchers
        .where((voucher) => voucher['category'] == _selectedCategory)
        .toList();
  }

  List<String> get _categories {
    final categories = widget.availableVouchers
        .map((v) => v['category']?.toString() ?? 'General')
        .toSet()
        .toList();
    categories.insert(0, 'All');
    return categories;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & beverages':
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_cart;
      case 'entertainment':
        return Icons.movie;
      case 'healthcare':
        return Icons.medical_services;
      default:
        return Icons.confirmation_number;
    }
  }

  void _showVoucherDetails(Map<String, dynamic> voucher) {
    final bool canRedeem = widget.userPoints >= voucher['points'];
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(_getCategoryIcon(voucher['category']), color: const Color(0xFFDE0D0D)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  voucher['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDE0D0D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${voucher['points']} Points',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDE0D0D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Required to redeem',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Voucher details
              _buildDetailRow('Category', voucher['category']),
              _buildDetailRow('Discount', '${voucher['discountValue']}%'),
              _buildDetailRow('Expiry', _formatDate(voucher['expiryDate'])),
              
              if (voucher['description'] != null && voucher['description'].toString().isNotEmpty)
                _buildDetailRow('Description', voucher['description'].toString()),
              
              const SizedBox(height: 16),
              
              // Points comparison
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Points:'),
                        Text(
                          '${widget.userPoints}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Required Points:'),
                        Text(
                          '${voucher['points']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Remaining Points:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.userPoints - voucher['points']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: canRedeem ? const Color(0xFFDE0D0D) : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              if (!canRedeem) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You need ${voucher['points'] - widget.userPoints} more points to redeem this voucher',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: canRedeem ? () {
                Navigator.of(context).pop();
                _confirmRedeemVoucher(voucher);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canRedeem ? const Color(0xFFDE0D0D) : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Redeem Now'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _confirmRedeemVoucher(Map<String, dynamic> voucher) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Redemption'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Redeem "${voucher['name']}" for ${voucher['points']} points?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Points:'),
                        Text('${widget.userPoints}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Points to Use:'),
                        Text(
                          '-${voucher['points']}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining Points:'),
                        Text(
                          '${widget.userPoints - voucher['points']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDE0D0D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Generate a unique voucher code
                final voucherCode = 'BC${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}';
                widget.onRedeem(
                  voucher['name'],
                  voucher['points'],
                  voucher['id'],
                  voucherCode,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDE0D0D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Points summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.orange[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Points',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${widget.userPoints} points',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDE0D0D),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDE0D0D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.availableVouchers.length} vouchers',
                  style: const TextStyle(
                    color: Color(0xFFDE0D0D),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Category filter
        if (_categories.length > 1)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                return Padding(
                  padding: EdgeInsets.only(
                    right: 8,
                    left: index == 0 ? 0 : 8,
                  ),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: const Color(0xFFDE0D0D),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                );
              },
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Vouchers list
        Expanded(
          child: widget.availableVouchers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.confirmation_number,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No vouchers available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Earn more points by donating blood!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _filteredVouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = _filteredVouchers[index];
                    final canRedeem = widget.userPoints >= voucher['points'];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: () => _showVoucherDetails(voucher),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDE0D0D).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getCategoryIcon(voucher['category']),
                            color: const Color(0xFFDE0D0D),
                            size: 24,
                          ),
                        ),
                        title: Text(
                          voucher['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${voucher['category']} • ${voucher['discountValue']}% OFF',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Expires: ${_formatDate(voucher['expiryDate'])}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: canRedeem
                                    ? const Color(0xFFDE0D0D).withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${voucher['points']} pts',
                                style: TextStyle(
                                  color: canRedeem
                                      ? const Color(0xFFDE0D0D)
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (!canRedeem)
                              const SizedBox(height: 4),
                            if (!canRedeem)
                              Text(
                                'Need ${voucher['points'] - widget.userPoints} more',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
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