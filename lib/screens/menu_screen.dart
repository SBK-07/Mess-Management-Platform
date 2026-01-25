import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../widgets/menu_card.dart';

/// Menu display screen with tabs for different meal types.
/// 
/// Shows breakfast, lunch, and dinner items in a tabbed view.
/// Students can tap on items to report dissatisfaction.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Column(
      children: [
        // Tab bar
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
              _buildTab(MealType.breakfast),
              _buildTab(MealType.lunch),
              _buildTab(MealType.dinner),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MealTypeList(mealType: MealType.breakfast),
              _MealTypeList(mealType: MealType.lunch),
              _MealTypeList(mealType: MealType.dinner),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(MealType mealType) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(mealType.icon),
          const SizedBox(width: 4),
          Text(mealType.displayName),
        ],
      ),
    );
  }
}

/// List of menu items for a specific meal type.
class _MealTypeList extends StatelessWidget {
  final MealType mealType;

  const _MealTypeList({required this.mealType});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final menuItems = appState.getMenuByMealType(mealType);

    if (menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🍽️',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'No ${mealType.displayName.toLowerCase()} items today',
              style: AppConstants.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        bottom: AppConstants.paddingLarge,
      ),
      itemCount: menuItems.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader();
        }
        
        final item = menuItems[index - 1];
        return MenuCard(
          menuItem: item,
          onTap: () => _showReportOption(context, item),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's ${mealType.displayName}",
            style: AppConstants.headingMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap on any item to report an issue',
            style: AppConstants.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showReportOption(BuildContext context, MenuItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.borderRadiusXLarge),
          ),
        ),
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Item info
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  ),
                  child: Center(
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppConstants.headingMedium,
                      ),
                      Text(
                        item.description,
                        style: AppConstants.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final appState = Provider.of<AppState>(context, listen: false);
                      appState.selectMenuItem(item);
                      Navigator.pop(context);
                      
                      // Navigate to feedback tab
                      DefaultTabController.of(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected "${item.name}" - Go to Report tab to submit feedback'),
                          action: SnackBarAction(
                            label: 'OK',
                            onPressed: () {},
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.report_problem_outlined),
                    label: const Text('Report Issue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.errorColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
          ],
        ),
      ),
    );
  }
}
