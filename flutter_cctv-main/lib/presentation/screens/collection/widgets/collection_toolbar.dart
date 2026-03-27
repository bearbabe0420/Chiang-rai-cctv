import '/utils/flutter_flow_export.dart';
import '/core/i18n/i18n.dart';
import '../../list_camera_page/widgets/toolbar.dart';
import 'package:flutter/material.dart';

/// Toolbar: SearchBar + Refresh + Manage Categories
class CollectionToolbar extends StatelessWidget {
  final TextEditingController? textController;
  final FocusNode? focusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;
  final VoidCallback onManageCategories;

  const CollectionToolbar({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onManageCategories,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Search bar ─────────────────────────────────────────────────────
        Expanded(
          child: CameraSearchBar(
            controller: textController,
            focusNode: focusNode,
            onChanged: onSearchChanged,
            onClear: onClearSearch,
          ),
        ),
        const SizedBox(width: 16),

        // ── Refresh ────────────────────────────────────────────────────────
        FlutterFlowIconButton(
          borderColor: const Color(0xFFDC2626),
          borderRadius: 12.0,
          borderWidth: 2.0,
          buttonSize: 50.0,
          fillColor: Colors.transparent,
          icon: const Icon(Icons.refresh, color: Color(0xFFDC2626), size: 26.0),
          onPressed: onRefresh,
        ),
        const SizedBox(width: 16),

        // ── Manage Categories ──────────────────────────────────────────────
        FFButtonWidget(
          onPressed: onManageCategories,
          text: context.tr('nav.collection'),
          icon: const Icon(Icons.settings, size: 22.0, color: Colors.white),
          options: FFButtonOptions(
            height: 50.0,
            padding:
                const EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
            iconPadding: EdgeInsetsDirectional.zero,
            color: const Color(0xFF10B981),
            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                  fontFamily:
                      FlutterFlowTheme.of(context).titleSmallFamily,
                  color: Colors.white,
                  letterSpacing: 0.0,
                  useGoogleFonts:
                      !FlutterFlowTheme.of(context).titleSmallIsCustom,
                ),
            elevation: 0.0,
            borderSide: const BorderSide(color: Color(0xFF10B981)),
            borderRadius: BorderRadius.circular(10.0),
            hoverColor: const Color(0xFF059669),
            hoverBorderSide: const BorderSide(color: Color(0xFF10B981)),
            hoverTextColor: Colors.white,
          ),
        ),
      ],
    );
  }
}