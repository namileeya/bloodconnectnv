import 'package:flutter/material.dart';

class PointsHistoryWidget extends StatefulWidget {
  final List<Map<String, dynamic>> pointsHistory;
  final String Function(String)? formatDescription;

  const PointsHistoryWidget({
    super.key,
    required this.pointsHistory,
    this.formatDescription,
  });

  @override
  State<PointsHistoryWidget> createState() => _PointsHistoryWidgetState();
}

class _PointsHistoryWidgetState extends State<PointsHistoryWidget> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Earned', 'Redeemed', 'Bonus', 'Voucher Used'];

  List<Map<String, dynamic>> get _filteredHistory {
    if (_selectedFilter == 'All') {
      return widget.pointsHistory;
    }
    
    String filterType;
    switch (_selectedFilter) {
      case 'Earned':
        filterType = 'earned';
        break;
      case 'Redeemed':
        filterType = 'redeemed';
        break;
      case 'Bonus':
        filterType = 'bonus';
        break;
      case 'Voucher Used':
        filterType = 'voucher_used';
        break;
      default:
        return widget.pointsHistory;
    }
    
    return widget.pointsHistory
        .where((history) => history['type'] == filterType)
        .toList();
  }

  Color _getPointsColor(String points) {
    if (points.startsWith('+')) {
      return Colors.green[600]!;
    } else if (points.startsWith('-')) {
      return Colors.red[600]!;
    } else {
      return Colors.grey[600]!;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'earned':
        return Icons.add_circle_outline;
      case 'redeemed':
        return Icons.remove_circle_outline;
      case 'bonus':
        return Icons.star_outline;
      case 'voucher_used':
        return Icons.local_offer_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'earned':
        return Colors.green;
      case 'redeemed':
        return Colors.red;
      case 'bonus':
        return Colors.orange;
      case 'voucher_used':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'earned':
        return 'Earned';
      case 'redeemed':
        return 'Redeemed';
      case 'bonus':
        return 'Bonus';
      case 'voucher_used':
        return 'Used';
      default:
        return 'Unknown';
    }
  }

  void _showHistoryDetails(Map<String, dynamic> history) {
    showDialog(
      context: context,
      barrierDismissible: true,
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
                    color: _getTypeColor(history['type']),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getTypeIcon(history['type']),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Transaction Details',
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
                        // Points display rectangle
                        Center(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(history['type']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getTypeColor(history['type']).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  history['points'] == '0' ? 'No Change' : '${history['points']} Points',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: history['points'] == '0' 
                                        ? Colors.grey[600] 
                                        : _getPointsColor(history['points']),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(history['type']).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getTypeColor(history['type']).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _getTypeDisplayName(history['type']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getTypeColor(history['type']),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Transaction Information
                        _buildInfoCard(
                          'Transaction Information',
                          [
                            'Date: ${history['date'] ?? 'N/A'}',
                            'Category: ${history['category'] ?? 'N/A'}',
                            'Transaction ID: ${history['id'] ?? 'N/A'}',
                            if (history['relatedId'] != null && history['relatedId'].toString().isNotEmpty)
                              'Related ID: ${history['relatedId'].toString()}',
                          ],
                          Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        _buildInfoCard(
                          'Description',
                          [
                            history['description'] ?? 'No description available',
                          ],
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Close button
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<String> details, Color color) {
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
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...details.map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              detail,
              style: TextStyle(
                fontSize: 14,
                color: color,
                height: 1.4,
              ),
            ),
          )),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Yesterday';
      } else if (difference < 7) {
        return '$difference days ago';
      } else {
        return dateString;
      }
    } catch (e) {
      return dateString;
    }
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
              int count;
              
              if (filter == 'All') {
                count = widget.pointsHistory.length;
              } else {
                String filterType;
                switch (filter) {
                  case 'Earned':
                    filterType = 'earned';
                    break;
                  case 'Redeemed':
                    filterType = 'redeemed';
                    break;
                  case 'Bonus':
                    filterType = 'bonus';
                    break;
                  case 'Voucher Used':
                    filterType = 'voucher_used';
                    break;
                  default:
                    filterType = '';
                }
                count = widget.pointsHistory.where((h) => h['type'] == filterType).length;
              }
              
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
        
        // History list
        Expanded(
          child: _filteredHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ${_selectedFilter.toLowerCase()} history found',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your points transactions will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _filteredHistory.length,
                  itemBuilder: (context, index) {
                    final history = _filteredHistory[index];
                    
                    return GestureDetector(
                      onTap: () => _showHistoryDetails(history),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getTypeColor(history['type']).withOpacity(0.3),
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
                            // Type icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getTypeColor(history['type']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getTypeIcon(history['type']),
                                color: _getTypeColor(history['type']),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Transaction details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.formatDescription != null
                                              ? widget.formatDescription!(history['description'] ?? 'No description')
                                              : (history['description'] ?? 'No description'),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        history['points'] == '0' ? 'No Change' : '${history['points']} pts',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _getPointsColor(history['points'] ?? '0'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getTypeColor(history['type']).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getTypeDisplayName(history['type']),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _getTypeColor(history['type']),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatDate(history['date'] ?? ''),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    history['category'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
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