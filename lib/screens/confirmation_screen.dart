import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/complaint.dart';
import '../models/replacement.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

/// Confirmation screen shown after successful complaint and replacement selection.
/// 
/// Displays a success animation with summary of the complaint and chosen replacement.
class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final complaint = appState.currentComplaint;
    final replacement = appState.selectedReplacement;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.appGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              children: [
                const Spacer(),

                // Success animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppConstants.elevatedShadow,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle,
                        color: AppConstants.successColor,
                        size: 80,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingLarge),

                // Success text
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'Request Confirmed!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your replacement has been processed',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.paddingXLarge),

                // Summary card
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusXLarge),
                      boxShadow: AppConstants.elevatedShadow,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Summary',
                          style: AppConstants.headingMedium,
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        const Divider(),
                        const SizedBox(height: AppConstants.paddingMedium),

                        // Complaint info
                        if (complaint != null) ...[
                          _buildSummaryRow(
                            icon: '🍽️',
                            label: 'Reported Item',
                            value: complaint.menuItem.name,
                          ),
                          const SizedBox(height: AppConstants.paddingSmall),
                          _buildSummaryRow(
                            icon: complaint.issueType.icon,
                            label: 'Issue Type',
                            value: complaint.issueType.displayName,
                          ),
                        ],

                        const SizedBox(height: AppConstants.paddingMedium),
                        
                        // Arrow
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppConstants.successColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_downward,
                            color: AppConstants.successColor,
                          ),
                        ),

                        const SizedBox(height: AppConstants.paddingMedium),

                        // Replacement info
                        if (replacement != null) ...[
                          _buildSummaryRow(
                            icon: replacement.emoji,
                            label: 'Replacement',
                            value: replacement.name,
                            highlight: true,
                          ),
                          const SizedBox(height: AppConstants.paddingSmall),
                          _buildSummaryRow(
                            icon: replacement.poolType.icon,
                            label: 'From Pool',
                            value: replacement.poolType.displayName,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Return button
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _returnToHome(context, appState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.primaryColor,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home),
                          SizedBox(width: 8),
                          Text(
                            'Return to Home',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Secondary action
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: TextButton(
                    onPressed: () {
                      // Could add option to report another item
                      _returnToHome(context, appState);
                    },
                    child: Text(
                      'Report Another Issue',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: highlight
                ? AppConstants.successColor.withOpacity(0.15)
                : AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              icon,
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
                label,
                style: AppConstants.bodySmall,
              ),
              Text(
                value,
                style: highlight
                    ? AppConstants.headingSmall.copyWith(
                        color: AppConstants.successColor,
                      )
                    : AppConstants.bodyLarge,
              ),
            ],
          ),
        ),
        if (highlight)
          const Icon(
            Icons.check_circle,
            color: AppConstants.successColor,
            size: 20,
          ),
      ],
    );
  }

  void _returnToHome(BuildContext context, AppState appState) {
    appState.resetFeedbackFlow();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}
