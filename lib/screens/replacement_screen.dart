import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/replacement.dart';
import '../models/pool_type.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../widgets/replacement_card.dart';
import 'confirmation_screen.dart';

/// Replacement pool selection screen.
/// 
/// Shows three pools (Snack, Fruit, Protein) for students to choose
/// a replacement after reporting dissatisfaction.
class ReplacementScreen extends StatefulWidget {
  const ReplacementScreen({super.key});

  @override
  State<ReplacementScreen> createState() => _ReplacementScreenState();
}

class _ReplacementScreenState extends State<ReplacementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReplacementItem? _localSelectedReplacement;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final complaint = appState.currentComplaint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Replacement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Show confirmation dialog before going back
            _showCancelDialog(context, appState);
          },
        ),
      ),
      body: Column(
        children: [
          // Complaint summary card
          if (complaint != null) _buildComplaintSummary(complaint),

          // Pool selection tabs
          Container(
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppConstants.cardColor,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              boxShadow: AppConstants.cardShadow,
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: AppConstants.textSecondary,
              indicator: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                _buildPoolTab(PoolType.snack),
                _buildPoolTab(PoolType.fruit),
                _buildPoolTab(PoolType.protein),
              ],
            ),
          ),

          // Pool items grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPoolGrid(PoolType.snack, appState),
                _buildPoolGrid(PoolType.fruit, appState),
                _buildPoolGrid(PoolType.protein, appState),
              ],
            ),
          ),

          // Custom Input & Comments Section
          _buildCustomInputSection(appState),

          // Confirm button
          _buildConfirmButton(context, appState),
        ],
      ),
    );
  }

  Widget _buildCustomInputSection(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Need something else?', style: AppConstants.headingSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Enter custom replacement...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) {
                    appState.setCustomReplacementName(val.isEmpty ? null : val);
                    if (val.isNotEmpty) {
                      setState(() {
                        _localSelectedReplacement = null;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Complements / Comments', style: AppConstants.headingSmall),
          const SizedBox(height: 8),
          TextField(
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g. Extra butter, No salt...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            onChanged: (val) => appState.setReplacementComments(val),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintSummary(complaint) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: AppConstants.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppConstants.errorColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            child: Center(
              child: Text(
                complaint.menuItem.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reported Issue:',
                  style: AppConstants.bodySmall,
                ),
                Text(
                  '${complaint.menuItem.name} - ${complaint.issueType.displayName}',
                  style: AppConstants.headingSmall.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.errorColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              complaint.issueType.icon,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolTab(PoolType poolType) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(poolType.icon),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              poolType.displayName.replaceAll(' Pool', ''),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolGrid(PoolType poolType, AppState appState) {
    final items = appState.getReplacementsByPoolType(poolType);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pool header
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingSmall,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getPoolColor(poolType).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    poolType.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poolType.displayName,
                      style: AppConstants.headingSmall,
                    ),
                    Text(
                      poolType.description,
                      style: AppConstants.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(
                top: AppConstants.paddingSmall,
                bottom: AppConstants.paddingLarge,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppConstants.paddingSmall,
                mainAxisSpacing: AppConstants.paddingSmall,
                childAspectRatio: 0.85,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ReplacementCard(
                  item: item,
                  isSelected: _localSelectedReplacement?.id == item.id,
                  onTap: () {
                    setState(() {
                      _localSelectedReplacement = item;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (_localSelectedReplacement != null || (appState.customReplacementName?.isNotEmpty ?? false))
                ? () => _confirmReplacement(context, appState)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.successColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle),
                const SizedBox(width: 8),
                Text(
                  _localSelectedReplacement != null
                      ? 'Confirm: ${_localSelectedReplacement!.name}'
                      : (appState.customReplacementName != null
                          ? 'Confirm: ${appState.customReplacementName}'
                          : 'Select a replacement'),
                  style: AppConstants.buttonText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPoolColor(PoolType poolType) {
    switch (poolType) {
      case PoolType.snack:
        return AppConstants.snackPoolColor;
      case PoolType.fruit:
        return AppConstants.fruitPoolColor;
      case PoolType.protein:
        return AppConstants.proteinPoolColor;
    }
  }

  void _confirmReplacement(BuildContext context, AppState appState) {
    if (_localSelectedReplacement == null) return;

    appState.selectReplacement(_localSelectedReplacement!);
    final success = appState.confirmReplacement();

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ConfirmationScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to confirm replacement. Please try again.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  void _showCancelDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Replacement?'),
        content: const Text(
          'Your complaint has been recorded. Are you sure you want to skip choosing a replacement?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Selecting'),
          ),
          ElevatedButton(
            onPressed: () {
              appState.resetFeedbackFlow();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: const Text('Skip Replacement'),
          ),
        ],
      ),
    );
  }
}
