import 'dart:async';
import 'package:flutter/material.dart';
import 'package:central_command/presentation/widgets/nav/nav_bar_main_widget.dart';
import '/core/i18n/i18n.dart';
import '/utils/app_text_styles.dart';
import '/index.dart';
import 'package:go_router/go_router.dart';
import 'dashboard_model.dart';
import 'widgets/stat_card.dart';
import 'widgets/license_plate_card.dart';
import 'widgets/accident_detection_card.dart';
import 'widgets/fighting_detection_card.dart';
//import 'widgets/incident_trend_chart_card.dart';

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
  final LicensePlateRepository _licensePlateRepository =
      LicensePlateRepository();
  final AccidentRepository _accidentRepository = AccidentRepository();

  LicensePlateData _licensePlateData = const LicensePlateData(totalDetected: 0);
  DetectionEvent _accidentEvent = DetectionEvent(
    cameraId: '-',
    lastDetection: DateTime.now(),
    todayCount: null,
  );
  String? _topAccidentCameraName;
  int? _topAccidentCameraMonthCount;
  final _fightingEvent = DetectionEvent(
    cameraId: 'Camera-B07',
    lastDetection: DateTime(2024, 1, 1, 14, 28, 33),
    todayCount: 5,
    snapshotUrl:
        'https://images.unsplash.com/photo-1515187029135-18ee286d815b?w=400&h=200&fit=crop',
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
    _refreshDashboardData();
    _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshDashboardData();
      setState(() => _isLive = false);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isLive = true);
      });
    });
  }

  Future<void> _refreshDashboardData() async {
    await Future.wait([
      _loadLatestLicensePlate(),
      _loadAccidentDashboard(),
    ]);
  }

  Future<void> _loadLatestLicensePlate() async {
    try {
      final latest = await _licensePlateRepository.getLatestLicensePlate();
      if (!mounted || latest == null) return;

      setState(() {
        _licensePlateData = LicensePlateData(
          totalDetected: _licensePlateData.totalDetected,
          latestPlateNumber: latest.licensePlate?.fullPlate,
          cameraId: latest.cameraName ?? latest.cameraId,
          lastDetection: DateTime.tryParse(latest.timestamp ?? ''),
          todayCount: latest.totalLicenseToday ?? _licensePlateData.todayCount,
          snapshotUrl: latest.imageUrl,
        );
      });
    } catch (_) {
      // Keep existing dashboard values if fetch fails.
    }
  }

  Future<void> _loadAccidentDashboard() async {
    try {
      final accidentDashboard =
          await _accidentRepository.getAccidentDashboard();
      if (!mounted || accidentDashboard == null) return;

      final latest = accidentDashboard.latestAccident;
      final topCamera = accidentDashboard.topCameras.isNotEmpty
          ? accidentDashboard.topCameras.first
          : null;

      setState(() {
        if (latest != null) {
          _accidentEvent = DetectionEvent(
            cameraId: latest.cameraName ?? latest.cameraId ?? '-',
            lastDetection: DateTime.tryParse(latest.timestamp ?? '') ??
                _accidentEvent.lastDetection,
            todayCount: null,
            snapshotUrl: latest.imageUrl,
          );
        }
        _topAccidentCameraName = topCamera?.cameraName ?? topCamera?.cameraId;
        _topAccidentCameraMonthCount = topCamera?.accidentCount;
      });
    } catch (_) {
      // Keep existing dashboard values if fetch fails.
    }
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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            context.tr('dashboard_ai.title',
                                fallback: 'แดชบอร์ดเฝ้าระวัง AI'),
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.5)),
                        SizedBox(height: 4),
                        Text(
                            context.tr('dashboard_ai.subtitle',
                                fallback:
                                    'สถานะการตรวจจับแบบเรียลไทม์จากระบบกล้องอัจฉริยะ'),
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF8A8A8E))),
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
                  LicensePlateCard(
                      data: _licensePlateData, onSearch: _showSearchDialog),
                  AccidentDetectionCard(
                    event: _accidentEvent,
                    topCameraName: _topAccidentCameraName,
                    topCameraMonthCount: _topAccidentCameraMonthCount,
                  ),
                  FightingDetectionCard(event: _fightingEvent),
                ];
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: cards
                            .expand((c) =>
                                [Expanded(child: c), const SizedBox(width: 16)])
                            .toList()
                          ..removeLast(),
                      )
                    : Column(
                        children: cards
                            .expand((c) => [c, const SizedBox(height: 16)])
                            .toList()
                          ..removeLast(),
                      );
              }),
              const SizedBox(height: 20),
              // const IncidentTrendChartCard(),
            ],
          ),
        ),
      ),
    );
  }
}
