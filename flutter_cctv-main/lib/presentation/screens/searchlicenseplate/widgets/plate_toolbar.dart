import 'package:central_command/utils/app_text_styles.dart';

import '/core/i18n/i18n.dart';
import '/utils/flutter_flow/theme.dart';
import 'package:flutter/material.dart';

/// Search bar สำหรับค้นหาทะเบียน
class PlateSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const PlateSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      height: 48,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: context.tr('plate.search_hint'),
          hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF), fontSize: AppTextStyles.labelNormal),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 22),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      size: 20, color: Color(0xFF9CA3AF)),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
          ),
        ),
      ),
    );
  }
}

/// Badge แสดงจำนวนผลลัพธ์ทั้งหมด
class PlateTotalBadge extends StatelessWidget {
  final int total;
  const PlateTotalBadge({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car,
              size: 15, color: FlutterFlowTheme.of(context).primary),
          const SizedBox(width: 6),
          Text(
            context.tr('plate.total_items', params: {'total': '$total'}),
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primary,
              fontWeight: FontWeight.w600,
              fontSize: AppTextStyles.badge,
            ),
          ),
        ],
      ),
    );
  }
}