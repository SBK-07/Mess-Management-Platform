import 'package:flutter/material.dart';
import '../models/replacement.dart';
import '../utils/constants.dart';

/// A card widget displaying a replacement pool item.
/// 
/// Shows the item with pool-specific styling and selection state.
class ReplacementCard extends StatelessWidget {
  final ReplacementItem item;
  final VoidCallback? onTap;
  final bool isSelected;

  const ReplacementCard({
    super.key,
    required this.item,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected 
              ? _getPoolColor().withOpacity(0.2)
              : AppConstants.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isSelected 
                ? _getPoolColor() 
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected 
              ? AppConstants.elevatedShadow 
              : AppConstants.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji with background
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _getPoolColor().withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    item.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              
              // Item name
              Text(
                item.name,
                style: AppConstants.headingSmall.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Description
              Text(
                item.description,
                style: AppConstants.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Selection indicator
              if (isSelected) ...[
                const SizedBox(height: AppConstants.paddingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPoolColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Selected',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPoolColor() {
    switch (item.poolType) {
      case PoolType.snack:
        return AppConstants.snackPoolColor;
      case PoolType.fruit:
        return AppConstants.fruitPoolColor;
      case PoolType.protein:
        return AppConstants.proteinPoolColor;
    }
  }
}
