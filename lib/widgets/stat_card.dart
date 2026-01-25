import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// A reusable statistics display card.
/// 
/// Shows an icon, value, and label in a clean format.
/// Used primarily in the admin dashboard.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final Color? backgroundColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppConstants.primaryColor;
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with colored background
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            child: Icon(
              icon,
              color: cardColor,
              size: 24,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          
          // Value
          Text(
            value,
            style: AppConstants.headingLarge.copyWith(
              color: cardColor,
            ),
          ),
          const SizedBox(height: 4),
          
          // Label
          Text(
            label,
            style: AppConstants.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// A horizontal stat card variant for smaller displays.
class StatCardHorizontal extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const StatCardHorizontal({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppConstants.primaryColor;
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Row(
        children: [
          // Icon with colored background
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            child: Icon(
              icon,
              color: cardColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          
          // Value and label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppConstants.headingMedium.copyWith(
                    color: cardColor,
                  ),
                ),
                Text(
                  label,
                  style: AppConstants.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
