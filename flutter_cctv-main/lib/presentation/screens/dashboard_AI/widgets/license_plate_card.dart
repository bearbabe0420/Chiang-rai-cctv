import 'package:flutter/material.dart';
import '/core/i18n/i18n.dart';
import '../dashboard_model.dart';
import 'dashboard_card.dart';
import 'card_header.dart';

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
          CardHeader(
            icon: Icons.directions_car_outlined,
            title: context.tr(
              'dashboard_ai.cards.license_plate_detection',
              fallback: 'การตรวจจับป้ายทะเบียน',
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Text(
                  context.tr(
                    'dashboard_ai.cards.total_plates_detected',
                    fallback: 'ป้ายทะเบียนที่ตรวจพบทั้งหมด',
                  ),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF8A8A8E)),
                ),
                const SizedBox(height: 8),
                Text(data.formattedTotal,
                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), letterSpacing: -2)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search, size: 18),
              label: Text(
                context.tr(
                  'dashboard_ai.cards.search_license_plate',
                  fallback: 'ค้นหาป้ายทะเบียน',
                ),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}