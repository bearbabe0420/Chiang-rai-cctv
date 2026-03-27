import 'package:central_command/utils/app_text_styles.dart';

import '/utils/flutter_flow/theme.dart';
import 'package:flutter/material.dart';

// =============================================================================
// NameCell — แสดง name + highlight ส่วนที่ตรงกับ search
// =============================================================================

class NameCell extends StatelessWidget {
  final String name;
  final String search;

  const NameCell({super.key, required this.name, required this.search});

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: search.isEmpty
            ? Text(name,
                style: const TextStyle(
                    fontSize: AppTextStyles.tableCell,
                    color: Color(0xFF111827)))
            : HighlightText(text: name, query: search),
      ),
    );
  }
}

// =============================================================================
// HighlightText — bold + primary color ส่วนที่ match
// =============================================================================

class HighlightText extends StatelessWidget {
  final String text;
  final String query;

  const HighlightText({super.key, required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final lower = text.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx < 0) {
      return Text(text,
          style: const TextStyle(
              fontSize: AppTextStyles.tableCell, color: Color(0xFF111827)));
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: AppTextStyles.tableCell, color: Color(0xFF111827)),
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: FlutterFlowTheme.of(context).primary,
              backgroundColor:
                  FlutterFlowTheme.of(context).primary.withOpacity(0.1),
            ),
          ),
          if (idx + query.length < text.length)
            TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}

// =============================================================================
// TextCell — generic text cell ใช้ซ้ำทั่วทั้ง table
// =============================================================================

class TextCell extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;

  const TextCell(this.text,
      {super.key,
      this.fontSize = AppTextStyles.tableCell,
      this.color});

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          text,
          style: TextStyle(
              fontSize: fontSize, color: color ?? const Color(0xFF111827)),
        ),
      ),
    );
  }
}

// =============================================================================
// ActionBtn — icon button กลม สำหรับ View / Edit / Delete
// =============================================================================

class ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const ActionBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: AppTextStyles.tableCell + 12,
          height: AppTextStyles.tableCell + 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: AppTextStyles.tableCell, color: color),
        ),
      ),
    );
  }
}

// =============================================================================
// EmptyState — แสดงเมื่อไม่มีข้อมูล
// =============================================================================

class CameraEmptyState extends StatelessWidget {
  const CameraEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No camera data found',
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