import 'package:flutter/material.dart';
import '/core/i18n/i18n.dart';
import '../dashboard_model.dart';
import 'dashboard_card.dart';
import 'card_header.dart';
import 'info_row.dart';
import 'snapshot_section.dart';

class FightingDetectionCard extends StatelessWidget {
  final DetectionEvent event;
  const FightingDetectionCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            icon: Icons.people_outline,
            title: context.tr(
              'dashboard_ai.cards.fighting_detection',
              fallback: 'การตรวจจับการทะเลาะวิวาท',
            ),
          ),
          const SizedBox(height: 24),
          InfoRow(
            label: context.tr('dashboard_ai.fields.camera', fallback: 'กล้อง'),
            value: event.cameraId,
            icon: Icons.camera_alt_outlined,
          ),
          const InfoRowDivider(),
          InfoRow(
            label: context.tr(
              'dashboard_ai.fields.last_detection',
              fallback: 'ตรวจพบล่าสุด',
            ),
            value: event.formattedTime,
            icon: Icons.access_time_outlined,
          ),
          const InfoRowDivider(),
          InfoRow(
            label: context.tr(
              'dashboard_ai.fields.today_count',
              fallback: 'จำนวนวันนี้',
            ),
            value: event.todayCount?.toString() ?? '-',
            icon: Icons.bar_chart_outlined,
          ),
          const SizedBox(height: 20),
          SnapshotSection(
              imageUrl: event.snapshotUrl,
              placeholderColor: const Color(0xFF8E8E93)),
        ],
      ),
    );
  }
}
