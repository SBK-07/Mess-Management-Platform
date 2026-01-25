import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../utils/constants.dart';

/// A card widget displaying a menu item.
/// 
/// Shows the item name, emoji, description, and meal type badge.
/// Supports tap callback for selection.
class MenuCard extends StatelessWidget {
  final MenuItem menuItem;
  final VoidCallback? onTap;
  final bool isSelected;

  const MenuCard({
    super.key,
    required this.menuItem,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppConstants.primaryColor.withOpacity(0.1)
              : AppConstants.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isSelected 
                ? AppConstants.primaryColor 
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: AppConstants.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              // Emoji container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                child: Center(
                  child: Text(
                    menuItem.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menuItem.name,
                      style: AppConstants.headingSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      menuItem.description,
                      style: AppConstants.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Selection indicator
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppConstants.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              
              if (!isSelected && onTap != null)
                const Icon(
                  Icons.chevron_right,
                  color: AppConstants.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
