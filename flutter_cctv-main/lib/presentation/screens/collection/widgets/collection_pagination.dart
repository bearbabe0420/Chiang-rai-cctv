import '/utils/flutter_flow_theme.dart';
import 'package:flutter/material.dart';

/// Pagination bar พร้อม first/prev/numbers/next/last
class CollectionPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const CollectionPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  List<int?> get _pageNums {
    if (totalPages <= 7) return [for (int p = 1; p <= totalPages; p++) p];
    final nums = <int?>[1];
    if (currentPage > 3) nums.add(null);
    final start = (currentPage - 1).clamp(2, totalPages - 1);
    final end = (currentPage + 1).clamp(2, totalPages - 1);
    for (int p = start; p <= end; p++) nums.add(p);
    if (currentPage < totalPages - 2) nums.add(null);
    nums.add(totalPages);
    return nums;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavBtn(
            icon: Icons.first_page,
            enabled: currentPage > 1,
            onTap: () => onPageChanged(1)),
        const SizedBox(width: 2),
        _NavBtn(
            icon: Icons.chevron_left,
            enabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1)),
        const SizedBox(width: 4),
        ..._pageNums.map((p) {
          if (p == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('...',
                  style: TextStyle(
                      color: Color(0xFF6B7280), fontSize: 14)),
            );
          }
          final isActive = p == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: isActive ? null : () => onPageChanged(p),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? FlutterFlowTheme.of(context).primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive
                        ? FlutterFlowTheme.of(context).primary
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$p',
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        _NavBtn(
            icon: Icons.chevron_right,
            enabled: currentPage < totalPages,
            onTap: () => onPageChanged(currentPage + 1)),
        const SizedBox(width: 2),
        _NavBtn(
            icon: Icons.last_page,
            enabled: currentPage < totalPages,
            onTap: () => onPageChanged(totalPages)),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled
                ? const Color(0xFFD1D5DB)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Icon(icon,
            size: 20,
            color:
                enabled ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
      ),
    );
  }
}