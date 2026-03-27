import 'package:central_command/utils/app_text_styles.dart';

import '/utils/flutter_flow/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =============================================================================
// PlateCell — ทะเบียน + จังหวัด
// =============================================================================

class PlateCell extends StatelessWidget {
  final String fullPlate;
  final String province;

  const PlateCell({
    super.key,
    required this.fullPlate,
    required this.province,
  });

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fullPlate,
              style: GoogleFonts.sarabun(
                fontSize: AppTextStyles.tablePlate,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            if (province.isNotEmpty)
              Text(
                province,
                style: const TextStyle(
                  fontSize: AppTextStyles.tableProvince,
                  color: Color(0xFF6B7280),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// IconLabelCell — icon + label (ใช้กับ cameraName & timestamp)
// =============================================================================

class IconLabelCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final double fontSize;
  final Color labelColor;
  final Color iconColor;

  const IconLabelCell({
    super.key,
    required this.icon,
    required this.label,
    required this.fontSize,
    this.labelColor = const Color(0xFF374151),
    this.iconColor = const Color(0xFF9CA3AF),
  });

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: fontSize, color: labelColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// HoverableImage — thumbnail + hover zoom overlay
// =============================================================================

class HoverableImage extends StatefulWidget {
  final String imageUrl;
  final String fullPlate;
  final String province;
  final VoidCallback onTap;

  const HoverableImage({
    super.key,
    required this.imageUrl,
    required this.fullPlate,
    required this.province,
    required this.onTap,
  });

  @override
  State<HoverableImage> createState() => _HoverableImageState();
}

class _HoverableImageState extends State<HoverableImage> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 90,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isHovering
                  ? FlutterFlowTheme.of(context).primary
                  : Colors.grey.shade300,
              width: _isHovering ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) => progress == null
                      ? child
                      : Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.broken_image,
                        color: Color(0xFFD1D5DB), size: 24),
                  ),
                ),
                // Hover overlay
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isHovering ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context)
                          .primary
                          .withOpacity(0.3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 32,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
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
}

// =============================================================================
// PlateEmptyState — แสดงเมื่อไม่มีข้อมูล
// =============================================================================

class PlateEmptyState extends StatelessWidget {
  const PlateEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_crash, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No license plate data found',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: AppTextStyles.labelNormal),
            ),
          ],
        ),
      ),
    );
  }
}