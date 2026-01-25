import '../models/replacement.dart';
import '../utils/dummy_data.dart';

/// Replacement service for managing food replacement pools.
/// 
/// Provides access to replacement items and tracks usage statistics.
class ReplacementService {
  // Private constructor for singleton pattern
  ReplacementService._();
  static final ReplacementService _instance = ReplacementService._();
  static ReplacementService get instance => _instance;

  // Track replacement usage counts
  final Map<String, int> _usageCounts = {};

  /// Get all replacement items.
  List<ReplacementItem> getAllReplacements() {
    return DummyData.replacementItems;
  }

  /// Get replacement items by pool type.
  List<ReplacementItem> getReplacementsByPoolType(PoolType poolType) {
    return DummyData.getReplacementsByPoolType(poolType);
  }

  /// Get a specific replacement item by ID.
  ReplacementItem? getReplacementById(String id) {
    return DummyData.findReplacementById(id);
  }

  /// Record usage of a replacement item.
  void recordUsage(String replacementId) {
    _usageCounts[replacementId] = (_usageCounts[replacementId] ?? 0) + 1;
  }

  /// Get usage count for a specific replacement item.
  int getUsageCount(String replacementId) {
    return _usageCounts[replacementId] ?? 0;
  }

  /// Get total usage counts by pool type.
  Map<PoolType, int> getUsageByPoolType() {
    final Map<PoolType, int> poolUsage = {
      PoolType.snack: 0,
      PoolType.fruit: 0,
      PoolType.protein: 0,
    };

    _usageCounts.forEach((id, count) {
      final item = getReplacementById(id);
      if (item != null) {
        poolUsage[item.poolType] = (poolUsage[item.poolType] ?? 0) + count;
      }
    });

    return poolUsage;
  }

  /// Get most popular replacement item.
  ReplacementItem? getMostUsedReplacement() {
    if (_usageCounts.isEmpty) return null;

    String? maxId;
    int maxCount = 0;
    _usageCounts.forEach((id, count) {
      if (count > maxCount) {
        maxCount = count;
        maxId = id;
      }
    });

    return maxId != null ? getReplacementById(maxId!) : null;
  }

  /// Get total replacements issued.
  int get totalReplacementsIssued {
    return _usageCounts.values.fold(0, (sum, count) => sum + count);
  }

  /// Clear usage data (for testing purposes).
  void clearUsageData() {
    _usageCounts.clear();
  }
}
