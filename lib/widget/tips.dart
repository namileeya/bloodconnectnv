import 'package:flutter/material.dart';

class TipsWidget extends StatelessWidget {
  const TipsWidget({super.key});

  // Donation Tips Data for BloodConnect KL, Malaysia
  static final List<Map<String, dynamic>> _donationTips = [
    {
      'category': 'Before Donation',
      'tips': [
        'Get enough sleep of 7-8 hours the previous night',
        'Eat a healthy, iron-rich meal before coming',
        'Stay hydrated and drink plenty of water (16-20 oz)',
        'Avoid alcohol for 24 hours before donation',
        'Bring valid photo identification (MyKad/Passport)',
        'Wear comfortable clothing with sleeves that can be raised',
        'List any medications you\'re taking or recently took',
        'Avoid fatty foods like fries or ice cream',
        'Avoid vigorous exercise or heavy lifting before donating',
        'Wait 14 days after recovering from COVID-19 symptoms',
        'Wait one week after COVID-19 vaccination if no side effects',
      ],
      'icon': Icons.schedule,
      'color': Colors.blue,
    },
    {
      'category': 'During Donation',
      'tips': [
        'Wear comfortable clothing with accessible sleeves',
        'Let the medical staff know your preferred arm',
        'Stay relaxed and breathe normally throughout',
        'Take time to chill and put your feet up',
        'Squeeze your hand regularly to maintain blood flow',
        'Maintain social distancing as per health protocols',
        'Alert staff immediately if you feel unwell',
        'Stay hydrated if offered water or refreshments',
      ],
      'icon': Icons.favorite,
      'color': Colors.red,
    },
    {
      'category': 'After Donation',
      'tips': [
        'Rest for 10-15 minutes before leaving',
        'Keep the bandage on for several hours',
        'Relax and enjoy some cookies or snacks provided',
        'Drink extra 600ml of liquid over the next 24 hours',
        'Keep eating iron-rich foods to replenish',
        'Contact BloodConnect if diagnosed with illness within 48 hours',
        'If feeling dizzy or lightheaded, sit or lie down immediately',
        'If needle site bleeds, apply pressure and raise arm for 5-10 minutes',
        'Apply cold pack if bruising occurs during first 24 hours',
        'Avoid activities where fainting may cause injury for 24 hours',
        'Avoid alcohol and caffeinated drinks for 24 hours',
        'Avoid heavy lifting or vigorous exercise for 24 hours',
        'Share your donation experience with others to encourage donation',
      ],
      'icon': Icons.self_improvement,
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Donation Tips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _donationTips.length,
            itemBuilder: (context, index) {
              final tipCategory = _donationTips[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tipCategory['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              tipCategory['icon'],
                              color: tipCategory['color'],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            tipCategory['category'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: tipCategory['color'],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...((tipCategory['tips'] as List<String>).map((tip) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: tipCategory['color'],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList()),
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