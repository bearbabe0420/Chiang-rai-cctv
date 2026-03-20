import 'package:central_command/utils/app_text_styles.dart';

import '/utils/flutter_flow/theme.dart';
import 'package:flutter/material.dart';

// =============================================================================
// FloatingButton — pill button สำหรับ toolbar ลอย
// =============================================================================

class CommandFloatingButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool isActive;

  const CommandFloatingButton({
    Key? key,
    required this.onTap,
    required this.icon,
    required this.label,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 32,
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.blue.withOpacity(0.55)
                : Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? Colors.blueAccent.withOpacity(0.8)
                  : Colors.white.withOpacity(0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// GridToolbar — top-left: grid size + edit button
// =============================================================================

class GridToolbar extends StatelessWidget {
  final int gridSize;
  final bool isEditMode;
  final VoidCallback onCycleLayout;
  final VoidCallback onToggleEdit;

  const GridToolbar({
    Key? key,
    required this.gridSize,
    required this.isEditMode,
    required this.onCycleLayout,
    required this.onToggleEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: IgnorePointer(
        ignoring: false,
        child: Material(
          elevation: 10,
          color: Colors.transparent,
          child: Row(
            children: [
              CommandFloatingButton(
                onTap: onCycleLayout,
                icon: Icons.grid_view_rounded,
                label: '${gridSize}x$gridSize',
              ),
              const SizedBox(width: 6),
              CommandFloatingButton(
                onTap: onToggleEdit,
                icon: isEditMode ? Icons.check : Icons.edit,
                label: isEditMode ? 'Done' : 'Edit',
                isActive: isEditMode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CategoryFilter — top-right: popup menu กรองหมวดหมู่
// =============================================================================

class CategoryFilter extends StatelessWidget {
  final bool isLoadingCategories;
  final List<dynamic> categories;
  final String? selectedCategoryId;
  final int gridSize;
  final int cameraCount;
  final String Function(String, {bool truncate}) getCategoryName;
  final ValueChanged<String?> onSelected;

  const CategoryFilter({
    Key? key,
    required this.isLoadingCategories,
    required this.categories,
    required this.selectedCategoryId,
    required this.gridSize,
    required this.cameraCount,
    required this.getCategoryName,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: IgnorePointer(
        ignoring: false,
        child: Material(
          elevation: 10,
          color: Colors.transparent,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: isLoadingCategories
                ? _loadingChip()
                : _popupMenu(context),
          ),
        ),
      ),
    );
  }

  Widget _loadingChip() => Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: const Center(
          child: SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: Colors.white),
          ),
        ),
      );

  Widget _popupMenu(BuildContext context) {
    final maxSlots = gridSize * gridSize;
    final showing = cameraCount > maxSlots ? maxSlots : cameraCount;
    final countLabel = cameraCount > maxSlots
        ? '$showing/$cameraCount cams'
        : '$showing cam${showing == 1 ? '' : 's'}';

    return PopupMenuButton<String?>(
      key: ValueKey(selectedCategoryId),
      offset: const Offset(0, 38),
      color: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.white24, width: 1),
      ),
      onSelected: onSelected,
      itemBuilder: (context) => [
        // All cameras
        PopupMenuItem<String?>(
          value: null,
          child: _CategoryMenuItem(
            icon: Icons.grid_view_rounded,
            name: 'No Filter',
            subtitle: 'Show all cameras',
            isSelected: selectedCategoryId == null,
          ),
        ),
        if (categories.isNotEmpty) ...[
          const PopupMenuDivider(height: 1),
          ...categories.map((cat) {
            final id = cat['id']?.toString();
            final name = cat['name']?.toString() ?? 'Unknown';
            final isSel = selectedCategoryId == id;
            return PopupMenuItem<String?>(
              value: id,
              child: _CategoryMenuItem(
                icon: Icons.folder_rounded,
                name: name,
                isSelected: isSel,
              ),
            );
          }),
        ],
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list_rounded,
                color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedCategoryId == null
                      ? 'No Filter'
                      : getCategoryName(selectedCategoryId!),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.1),
                ),
                const SizedBox(height: 1),
                Text(
                  countLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: AppTextStyles.commandSmall,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CategoryMenuItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final String? subtitle;
  final bool isSelected;

  const _CategoryMenuItem({
    required this.icon,
    required this.name,
    this.subtitle,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            color: isSelected ? Colors.blue : Colors.white70, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.white,
                  fontSize: AppTextStyles.commandBody,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.7)
                        : Colors.white54,
                    fontSize: AppTextStyles.commandSmall,
                  ),
                ),
            ],
          ),
        ),
        if (isSelected)
          const Icon(Icons.check_rounded, color: Colors.blue, size: 16),
      ],
    );
  }
}

// =============================================================================
// Empty states
// =============================================================================

/// ไม่มีกล้องในหมวดหมู่ที่เลือก
class CategoryEmptyState extends StatelessWidget {
  final String categoryName;
  const CategoryEmptyState({Key? key, required this.categoryName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, color: Colors.white38, size: 64),
          const SizedBox(height: 16),
          Text(
            'There is no camera in "$categoryName"',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'You can add cameras manually from the Collection page',
            style: TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// ไม่มีกล้องในระบบเลย
class NoCamerasState extends StatelessWidget {
  final VoidCallback onRefresh;
  const NoCamerasState({Key? key, required this.onRefresh}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          const Text('No cameras available',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Check your API connection',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// API error state
class ApiErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ApiErrorState(
      {Key? key, required this.message, required this.onRetry})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}