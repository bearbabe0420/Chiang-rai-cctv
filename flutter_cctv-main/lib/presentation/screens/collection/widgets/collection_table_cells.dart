import 'category_chip.dart';
import '/utils/flutter_flow_theme.dart';
import '/utils/flutter_flow_util.dart';
import 'package:flutter/material.dart';

// =============================================================================
// StatusBadge
// =============================================================================

/// Online / Offline badge with dot indicator
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isOnline = status.toLowerCase() == 'online';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: isOnline
                  ? const Color(0xFF15803D)
                  : const Color(0xFFDC2626),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CollectionCategoryChips
// =============================================================================

/// Chip list สำหรับ categories ของกล้องในตาราง
class CollectionCategoryChips extends StatelessWidget {
  final dynamic item;
  const CollectionCategoryChips({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cats = getJsonField(item, r'$.categories');
    if (cats == null || (cats is List && cats.isEmpty)) {
      return const SizedBox.shrink();
    }
    final list = cats is List ? cats : [cats];
    final names = list
        .map((c) => c is Map ? c['name']?.toString() ?? '' : c.toString())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: names
          .map((n) => CategoryChip(
                name: n,
                fontSize: AppTextStyles.tableStatus,
              ))
          .toList(),
    );
  }
}

// =============================================================================
// CollectionEmptyState
// =============================================================================

/// Empty state เมื่อไม่มีกล้องในตาราง
class CollectionEmptyState extends StatelessWidget {
  final String searchText;
  const CollectionEmptyState({super.key, required this.searchText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 80.0,
              color: FlutterFlowTheme.of(context).secondaryText),
          const SizedBox(height: 16.0),
          Text(
            searchText.isNotEmpty
                ? 'No cameras found matching "$searchText"'
                : 'No cameras available',
            style: FlutterFlowTheme.of(context).titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}