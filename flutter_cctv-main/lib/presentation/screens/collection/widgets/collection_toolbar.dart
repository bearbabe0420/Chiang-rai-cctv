import '/utils/flutter_flow_theme.dart';
import '/utils/flutter_flow_icon_button.dart';
import '/utils/flutter_flow_widgets.dart';
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
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: textController,
              focusNode: focusNode,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search cameras...',
                hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF9CA3AF), size: 20),
                suffixIcon: (textController?.text.isNotEmpty ?? false)
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: Color(0xFF9CA3AF)),
                        onPressed: onClearSearch,
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: FlutterFlowTheme.of(context).primary),
                ),
              ),
            ),
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
          text: 'Manage Categories',
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