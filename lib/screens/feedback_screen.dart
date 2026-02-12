import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/complaint.dart';
import '../models/issue_type.dart';
import '../models/meal_type.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../widgets/menu_card.dart';
// replacement picker removed: students will only use the suggested replacement field
import 'my_complaints_screen.dart';

/// Feedback/Dissatisfaction reporting screen.
///
/// Allows students to select a menu item and report an issue type.
/// After submission, records the report (and any suggested replacement) and
/// navigates to the user's My Complaints screen.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  IssueType? _localSelectedIssueType;
  MealType? _selectedMealType;
  final TextEditingController _suggestedReplacementCtrl =
      TextEditingController();

  @override
  void dispose() {
    _suggestedReplacementCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final selectedItem = appState.selectedMenuItem;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Report Dissatisfaction',
            style: AppConstants.headingMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Tell us about any issues with your meal',
            style: AppConstants.bodyMedium,
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Step 1: Select menu item
          _buildSectionHeader('1. Select Menu Item', Icons.restaurant_menu),
          const SizedBox(height: AppConstants.paddingSmall),

          // Meal type selector
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
            ),
            child: DropdownButtonFormField<MealType?>(
              value: _selectedMealType,
              decoration: const InputDecoration(
                labelText: 'Meal Section',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Meals')),
                ...MealType.values.map(
                  (m) => DropdownMenuItem(value: m, child: Text(m.displayName)),
                ),
              ],
              onChanged: (val) => setState(() => _selectedMealType = val),
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          const SizedBox(height: AppConstants.paddingSmall),

          if (selectedItem != null)
            MenuCard(
              menuItem: selectedItem,
              isSelected: true,
              onTap: () => _showMenuItemPicker(context, appState),
            )
          else
            _buildSelectItemCard(context, appState),

          const SizedBox(height: AppConstants.paddingLarge),

          // Step 2: Select issue type
          _buildSectionHeader('2. What\'s the Issue?', Icons.report_problem),
          const SizedBox(height: AppConstants.paddingSmall),

          ...IssueType.values.map(
            (issueType) => _buildIssueTypeCard(issueType),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Suggested replacement (optional)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Replacement (optional)',
                  style: AppConstants.headingSmall,
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                TextField(
                  controller: _suggestedReplacementCtrl,
                  decoration: InputDecoration(
                    hintText: 'E.g. Replace chilli rice with plain rice',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusSmall,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  (selectedItem != null && _localSelectedIssueType != null)
                  ? () => _submitComplaint(context, appState)
                  : null,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send),
                  SizedBox(width: 8),
                  Text('Submit Report', style: AppConstants.buttonText),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          // Info text
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppConstants.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusMedium,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppConstants.secondaryColor),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: Text(
                    'Your report will be recorded. If you provided a suggested replacement it will be sent along with your report.',
                    style: AppConstants.bodySmall.copyWith(
                      color: AppConstants.secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppConstants.headingSmall),
      ],
    );
  }

  Widget _buildSelectItemCard(BuildContext context, AppState appState) {
    return GestureDetector(
      onTap: () => _showMenuItemPicker(context, appState),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingSmall,
        ),
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
          boxShadow: AppConstants.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: AppConstants.primaryColor,
              size: 32,
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Text(
              'Tap to select a menu item',
              style: AppConstants.bodyLarge.copyWith(
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueTypeCard(IssueType issueType) {
    final isSelected = _localSelectedIssueType == issueType;

    return GestureDetector(
      onTap: () {
        setState(() {
          _localSelectedIssueType = issueType;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingSmall,
        ),
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.1)
              : AppConstants.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: AppConstants.cardShadow,
        ),
        child: Row(
          children: [
            // Issue icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getIssueColor(issueType).withOpacity(0.15),
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusSmall,
                ),
              ),
              child: Center(
                child: Text(
                  issueType.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),

            // Issue details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issueType.displayName,
                    style: AppConstants.headingSmall.copyWith(fontSize: 16),
                  ),
                  Text(issueType.description, style: AppConstants.bodySmall),
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
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getIssueColor(IssueType issueType) {
    switch (issueType) {
      case IssueType.taste:
        return Colors.orange;
      case IssueType.hygiene:
        return Colors.red;
      case IssueType.temperature:
        return Colors.blue;
      case IssueType.portionSize:
        return Colors.purple;
      case IssueType.quality:
        return Colors.amber;
      case IssueType.other:
        return Colors.blueGrey;
    }
  }

  void _showMenuItemPicker(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppConstants.backgroundColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppConstants.borderRadiusXLarge),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Menu Item',
                      style: AppConstants.headingMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Menu items list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(
                    bottom: AppConstants.paddingLarge,
                  ),
                  itemCount:
                      (_selectedMealType == null
                              ? appState.todaysMenu
                              : appState.getMenuByMealType(_selectedMealType!))
                          .length,
                  itemBuilder: (context, index) {
                    final menuList = _selectedMealType == null
                        ? appState.todaysMenu
                        : appState.getMenuByMealType(_selectedMealType!);
                    final item = menuList[index];
                    return MenuCard(
                      menuItem: item,
                      isSelected: appState.selectedMenuItem?.id == item.id,
                      onTap: () {
                        appState.selectMenuItem(item);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitComplaint(BuildContext context, AppState appState) async {
    if (_localSelectedIssueType == null) return;

    final menuItem = appState.selectedMenuItem;
    if (menuItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a menu item first.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    try {
      await appState.submitFoodReport(
        menuItemId: menuItem.id,
        menuItemName: menuItem.name,
        mealType: menuItem.mealType,
        mealDate: DateTime.now(),
        reason: _localSelectedIssueType!,
        comments: _suggestedReplacementCtrl.text,
      );
    } catch (e) {
      debugPrint('Food report save failed: $e');
    }

    // existing complaint flow for replacement selection
    appState.selectIssueType(_localSelectedIssueType!);
    final success = appState.submitComplaint();

    if (success) {
      final suggested = _suggestedReplacementCtrl.text.trim();
      setState(() {
        _localSelectedIssueType = null;
        _suggestedReplacementCtrl.clear();
      });

      if (suggested.isNotEmpty) {
        // set custom replacement and comments then confirm
        appState.setCustomReplacementName(suggested);
        appState.setReplacementComments('Requested replacement: $suggested');
        final confirmed = appState.confirmReplacement();
        if (confirmed) {
          if (context.mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report submitted and replacement requested'),
              ),
            );
        } else {
          if (context.mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to request replacement'),
                backgroundColor: AppConstants.errorColor,
              ),
            );
        }
      } else {
        if (context.mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Report submitted')));
      }

      // Reset flow and navigate to My Complaints
      appState.resetFeedbackFlow();
      if (context.mounted)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyComplaintsScreen()),
        );
      return;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit complaint. Please try again.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }
}
