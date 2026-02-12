import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class MyComplaintsScreen extends StatelessWidget {
  const MyComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final complaints = appState.allComplaints
        .where((c) => c.studentId == user?.uid)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        backgroundColor: AppConstants.primaryColor,
      ),
      body: complaints.isEmpty
          ? Center(
              child: Text(
                'You have not submitted any complaints yet.',
                style: AppConstants.bodyMedium,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              itemCount: complaints.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppConstants.paddingSmall),
              itemBuilder: (context, index) {
                final c = complaints[index];
                return Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppConstants.cardColor,
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusMedium,
                    ),
                    boxShadow: AppConstants.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppConstants.errorColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            c.menuItem.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.menuItem.name,
                              style: AppConstants.headingSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${c.issueType.displayName} • ${DateFormat('MMM d, HH:mm').format(c.timestamp)}',
                              style: AppConstants.bodySmall,
                            ),
                            if (c.replacementId != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Replacement requested',
                                style: AppConstants.bodySmall.copyWith(
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
