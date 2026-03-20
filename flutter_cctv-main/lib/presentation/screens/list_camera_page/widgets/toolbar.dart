import 'package:central_command/utils/app_text_styles.dart';

import '/utils/flutter_flow/theme.dart';
import 'package:flutter/material.dart';

/// Search bar สำหรับกรองกล้อง
class CameraSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const CameraSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search cameras by name...',
          hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF), fontSize: AppTextStyles.labelNormal),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
          suffixIcon: (controller?.text.isNotEmpty ?? false)
              ? IconButton(
                  icon: const Icon(Icons.close,
                      size: 18, color: Color(0xFF9CA3AF)),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

/// ปุ่ม Add Camera
class AddCameraButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AddCameraButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Camera'),
      style: ElevatedButton.styleFrom(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppTextStyles.labelNormal),
      ),
    );
  }
}