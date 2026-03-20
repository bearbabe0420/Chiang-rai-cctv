import 'package:central_command/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/utils/flutter_flow/theme.dart';

/// Dialog แสดงรูปขยาย พร้อม plate info ด้านล่าง
class ImageViewerDialog extends StatelessWidget {
  final String imageUrl;
  final String? plateText;
  final String? province;

  const ImageViewerDialog({
    super.key,
    required this.imageUrl,
    this.plateText,
    this.province,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Dismiss on tap outside
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.92,
                    maxHeight: MediaQuery.of(context).size.height * 0.78,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 5.0,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            width: 300,
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          width: 300,
                          height: 200,
                          color: Colors.grey.shade800,
                          child: const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.white54, size: 48),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Plate info badge
                if (plateText != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          plateText!,
                          style: GoogleFonts.sarabun(
                            fontSize: AppTextStyles.tablePlate,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        if (province != null && province!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              province!,
                              style: GoogleFonts.sarabun(
                                fontSize: AppTextStyles.tableProvince,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  label: const Text('close',
                      style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}