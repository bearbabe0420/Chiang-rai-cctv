import 'package:flutter/material.dart';
import '/core/i18n/i18n.dart';

class SnapshotSection extends StatelessWidget {
  final String? imageUrl;
  final Color placeholderColor;

  const SnapshotSection({super.key, this.imageUrl, this.placeholderColor = const Color(0xFF8E8E93)});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(
            'dashboard_ai.cards.latest_snapshot',
            fallback: 'ภาพล่าสุด',
          ),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8A8A8E), letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 160,
            color: const Color(0xFFF2F2F7),
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                              : null,
                          color: placeholderColor,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        color: placeholderColor.withOpacity(0.1),
        child: Center(child: Icon(Icons.image_outlined, color: placeholderColor, size: 32)),
      );
}