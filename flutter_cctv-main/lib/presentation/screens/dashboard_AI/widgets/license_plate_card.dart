import 'package:flutter/material.dart';
import '/core/i18n/i18n.dart';
import '../dashboard_model.dart';
import 'dashboard_card.dart';
import 'card_header.dart';
import 'info_row.dart';
import 'snapshot_section.dart';

class LicensePlateCard extends StatelessWidget {
  final LicensePlateData data;
  final VoidCallback onSearch;

  const LicensePlateCard({super.key, required this.data, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────
          CardHeader(
            icon: Icons.directions_car_outlined,
            title: context.tr(
              'dashboard_ai.cards.license_plate_detection',
              fallback: 'การตรวจจับป้ายทะเบียน',
            ),
          ),
          const SizedBox(height: 24),

          // ── ปุ่ม Search ──────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search, size: 16),
              label: Text(
                context.tr(
                  'dashboard_ai.cards.search_license_plate',
                  fallback: 'ค้นหาป้ายทะเบียน',
                ),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Info Rows ────────────────────────────
          InfoRow(
            label: context.tr('dashboard_ai.cards.latest_plate', fallback: 'ป้ายล่าสุด'),
            value: data.latestPlateNumber ?? '-',
            icon: Icons.directions_car_outlined,
          ),
          const InfoRowDivider(),
          InfoRow(
            label: context.tr('dashboard_ai.cards.camera', fallback: 'กล้อง'),
            value: data.cameraId ?? '-',
            icon: Icons.camera_alt_outlined,
          ),
          const InfoRowDivider(),
          InfoRow(
            label: context.tr('dashboard_ai.cards.last_detection', fallback: 'เวลาที่ตรวจพบ'),
            value: data.formattedTime ?? '-',
            icon: Icons.access_time_outlined,
          ),
          const InfoRowDivider(),
          InfoRow(
            label: context.tr('dashboard_ai.cards.today_count', fallback: 'จำนวนวันนี้'),
            value: data.todayCount?.toString() ?? '-',
            icon: Icons.bar_chart_outlined,
          ),
          const SizedBox(height: 20),

          // ── Latest Snapshot ──────────────────────
          SnapshotSection(
            imageUrl: data.snapshotUrl,
            placeholderColor: const Color(0xFF3A3A3C),
          ),
        ],
        ),
    );
  }
}