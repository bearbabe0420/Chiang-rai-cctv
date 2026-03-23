// presentation/widgets/nav_bar_main_widget.dart
// รวม widget + model ไว้ในไฟล์เดียว

import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '/utils/flutter_flow/widgets.dart';
import '/core/i18n/i18n.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// =============================================================================
// Model
// =============================================================================

class NavBarMainModel extends FlutterFlowModel<NavBarMainWidget> {
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}

// =============================================================================
// Widget
// =============================================================================

class NavBarMainWidget extends StatefulWidget {
  const NavBarMainWidget({super.key});

  @override
  State<NavBarMainWidget> createState() => _NavBarMainWidgetState();
}

class _NavBarMainWidgetState extends State<NavBarMainWidget> {
  late NavBarMainModel _model;

  static const _primaryColor = Color(0xFF4B39EF);

  static const _navItems = [
    _NavItemData(
      labelKey: 'nav.list_camera',
      labelFallback: 'รายการกล้อง',
      icon: Icons.videocam_outlined,
      routeName: 'ListCameraPage',
    ),
    _NavItemData(
      labelKey: 'nav.dashboard_ai',
      labelFallback: 'แดชบอร์ด AI',
      icon: Icons.auto_graph_outlined,
      routeName: 'DashboardAI',
    ),
    _NavItemData(
      labelKey: 'nav.collection',
      labelFallback: 'คอลเลกชัน',
      icon: Icons.folder_outlined,
      routeName: 'Collection',
    ),
    _NavItemData(
      labelKey: 'nav.command_view',
      labelFallback: 'มุมมองคำสั่ง',
      icon: Icons.dashboard_outlined,
      routeName: 'CommandView',
    ),
    _NavItemData(
      labelKey: 'nav.map_view',
      labelFallback: 'แผนที่',
      icon: Icons.map_outlined,
      routeName: 'MapView',
    ),
  ];

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NavBarMainModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  String _currentRoute(BuildContext context) =>
      GoRouterState.of(context).name ?? '';

  void _navigate(BuildContext context, String routeName) {
    if (_currentRoute(context) == routeName) return;
    context.goNamed(
      routeName,
      extra: <String, dynamic>{
        '__transition_info__': TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.fade,
          duration: const Duration(milliseconds: 150),
        ),
      },
    );
  }

  void _logout(BuildContext context) {
    AppState().clearAuth();
    context.goNamed('LoginPage');
  }

  void _openSlideMenu(BuildContext context) {
    final currentRoute = _currentRoute(context);
    showGeneralDialog(
      context: context,
      barrierLabel: 'menu',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.28),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerLeft,
          child: SafeArea(
            child: Material(
              color: Colors.white,
              elevation: 12,
              child: SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
                      child: Row(
                        children: [
                          Text(
                            context.tr('nav.menu', fallback: 'เมนูหลัก'),
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF111827),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: const Color(0xFF4B5563),
                            tooltip: '',
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: _navItems.map((item) {
                          final isActive = item.routeName == currentRoute;
                          return ListTile(
                            leading: Icon(
                              item.icon,
                              size: 20,
                              color: isActive
                                  ? _primaryColor
                                  : const Color(0xFF6B7280),
                            ),
                            title: Text(
                              context.tr(item.labelKey,
                                  fallback: item.labelFallback),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight:
                                    isActive ? FontWeight.w700 : FontWeight.w600,
                                color: isActive
                                    ? _primaryColor
                                    : const Color(0xFF111827),
                              ),
                            ),
                            selected: isActive,
                            selectedTileColor: _primaryColor.withOpacity(0.09),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              _navigate(context, item.routeName);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor:
                                      _primaryColor.withOpacity(0.12),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 15,
                                    color: _primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'admin',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                                    Text(
                                      context.tr('nav.administrator'),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _logout(context);
                              },
                              icon: const Icon(
                                Icons.logout_rounded,
                                size: 16,
                                color: Color(0xFFEF4444),
                              ),
                              label: Text(
                                context.tr('nav.logout'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFECACA)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (dialogContext, animation, _, child) {
        final offsetTween = Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        );
        return SlideTransition(
          position: offsetTween.animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = _currentRoute(context);
    final currentItem = _navItems.where((item) => item.routeName == currentRoute).firstOrNull;

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        // ── Left hamburger button ───────────────────────────────────────────
        InkWell(
          onTap: () => _openSlideMenu(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.menu_rounded,
                color: Color(0xFF374151), size: 20),
          ),
        ),
        const SizedBox(width: 10),

        // ── Brand name ───────────────────────────────────────────────────────
        Text(
          context.tr('nav.brand'),
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF111827),
            fontSize: AppTextStyles.navBrand,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),

        // ── Divider ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
              width: 1, height: 20, color: const Color(0xFFE5E7EB)),
        ),

        // ── Current section label ────────────────────────────────────────────
        Expanded(
          child: Text(
            currentItem != null
                ? context.tr(currentItem.labelKey, fallback: currentItem.labelFallback)
                : context.tr('nav.brand'),
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF4B5563),
              fontSize: AppTextStyles.navItem,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _NavItemData — immutable data class
// =============================================================================

class _NavItemData {
  final String labelKey;
  final String labelFallback;
  final IconData icon;
  final String routeName;
  const _NavItemData({
    required this.labelKey,
    required this.labelFallback,
    required this.icon,
    required this.routeName,
  });
}
