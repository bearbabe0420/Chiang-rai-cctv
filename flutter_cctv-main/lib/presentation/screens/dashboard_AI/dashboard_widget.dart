import 'dart:async';
import 'package:flutter/material.dart';
import 'package:central_command/presentation/widgets/nav/nav_bar_main_widget.dart';
import '/utils/app_text_styles.dart';
import '/index.dart';
import 'package:go_router/go_router.dart';
import 'dashboard_model.dart';
//import 'widgets/live_indicator.dart';
import 'widgets/stat_card.dart';
import 'widgets/license_plate_card.dart';
import 'widgets/accident_detection_card.dart';
import 'widgets/fighting_detection_card.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  static String routeName = 'DashboardAI';
  static String routePath = '/dashboard-ai';

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  bool _isLive = true;
  late Timer _liveTimer;

  final _licensePlateData = const LicensePlateData(totalDetected: 1247);
  final _accidentEvent = DetectionEvent(
    cameraId: 'Camera-A03',
    lastDetection: DateTime(2024, 1, 1, 9, 15, 42),
    todayCount: 3,
    snapshotUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=400&h=200&fit=crop',
  );
  final _fightingEvent = DetectionEvent(
    cameraId: 'Camera-B07',
    lastDetection: DateTime(2024, 1, 1, 14, 28, 33),
    todayCount: 5,
    snapshotUrl: 'https://images.unsplash.com/photo-1515187029135-18ee286d815b?w=400&h=200&fit=crop',
  );
  final _systemStats = const SystemStats(
    camerasOnline: 24,
    alertsToday: 8,
    systemUptimePercent: 99.8,
    storageUsedPercent: 68,
  );

  @override
  void initState() {
    super.initState();
    _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() => _isLive = false);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isLive = true);
      });
    });
  }

  @override
  void dispose() {
    _liveTimer.cancel();
    super.dispose();
  }

  void _showSearchDialog() {
    context.pushNamed(ListPlatePageWidget.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        toolbarHeight: AppTextStyles.navBarHeight,
        backgroundColor: const Color(0xFFF3F4F6),
        automaticallyImplyLeading: false,
        title: const NavBarMainWidget(),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              // ignore: prefer_const_constructors
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Monitoring Dashboard',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), letterSpacing: -0.5)),
                        SizedBox(height: 4),
                        Text('Real-time detection status from AI surveillance systems',
                            style: TextStyle(fontSize: 14, color: Color(0xFF8A8A8E))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Detection Cards
              LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final cards = [
                  LicensePlateCard(data: _licensePlateData, onSearch: _showSearchDialog),
                  AccidentDetectionCard(event: _accidentEvent),
                  FightingDetectionCard(event: _fightingEvent),
                ];
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: cards.expand((c) => [Expanded(child: c), const SizedBox(width: 16)]).toList()..removeLast(),
                      )
                    : Column(
                        children: cards.expand((c) => [c, const SizedBox(height: 16)]).toList()..removeLast(),
                      );
              }),
              const SizedBox(height: 24),

              // Stats Row
              LayoutBuilder(builder: (context, constraints) {
                final statCards = [
                  StatCard(label: 'Cameras Online', value: _systemStats.camerasOnline.toString(), icon: Icons.videocam, color: const Color(0xFF007AFF)),
                  StatCard(label: 'Alerts Today', value: _systemStats.alertsToday.toString(), icon: Icons.notifications_outlined, color: const Color(0xFFFF9500)),
                  StatCard(label: 'System Uptime', value: _systemStats.formattedUptime, icon: Icons.check_circle_outline, color: const Color(0xFF34C759)),
                  StatCard(label: 'Storage Used', value: _systemStats.formattedStorage, icon: Icons.storage_outlined, color: const Color(0xFFFF3B30)),
                ];
                return constraints.maxWidth > 600
                    ? Row(children: statCards.expand((c) => [Expanded(child: c), const SizedBox(width: 16)]).toList()..removeLast())
                    : GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: statCards,
                      );
              }),
            ],
          ),
        ),
      ),
    );
  }
}