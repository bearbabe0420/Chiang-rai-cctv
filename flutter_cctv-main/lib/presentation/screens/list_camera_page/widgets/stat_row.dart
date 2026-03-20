import 'package:central_command/utils/app_text_styles.dart';

import '/utils/flutter_flow/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../list_camera_page_model.dart';

/// แถว Stat Cards (Total / Online / Offline)
class CameraStatRow extends StatelessWidget {
  final ListCameraPageModel model;
  const CameraStatRow({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StatCard(
          icon: Icons.camera_outdoor,
          iconColor: FlutterFlowTheme.of(context).primary,
          label: 'Total cameras',
          count: model.totalCameras,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.wifi,
          iconColor: const Color(0xFF16A34A),
          label: 'Online',
          count: model.onlineCameras,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.wifi_off,
          iconColor: const Color(0xFFDC2626),
          label: 'Offline',
          count: model.offlineCameras,
        ),
      ],
    );
  }
}

/// Card แสดงตัวเลข stat แต่ละตัว
class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF606A85),
                    fontSize: AppTextStyles.badge,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF15161E),
                    fontSize: AppTextStyles.statCardHero,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}