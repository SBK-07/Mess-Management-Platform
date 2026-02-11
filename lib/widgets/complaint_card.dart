import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../models/issue_type.dart';
import '../utils/constants.dart';

/// A card widget displaying a complaint summary.
/// 
/// Shows the menu item, issue type, and timestamp.
class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback? onTap;

  const ComplaintCard({
    super.key,
    required this.complaint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          boxShadow: AppConstants.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              // Issue type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getIssueColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                child: Center(
                  child: Text(
                    complaint.issueType.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              
              // Complaint details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          complaint.menuItem.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            complaint.menuItem.name,
                            style: AppConstants.headingSmall.copyWith(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getIssueColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        complaint.issueType.displayName,
                        style: AppConstants.bodySmall.copyWith(
                          color: _getIssueColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(complaint.timestamp),
                      style: AppConstants.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getIssueColor() {
    switch (complaint.issueType) {
      case IssueType.taste:
        return Colors.orange;
      case IssueType.hygiene:
        return Colors.red;
      case IssueType.quantity:
        return Colors.blue;
      case IssueType.other:
        return Colors.blueGrey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
