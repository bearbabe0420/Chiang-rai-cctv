import 'package:central_command/utils/app_text_styles.dart';

import '/core/i18n/i18n.dart';
import '/utils/flutter_flow/theme.dart';
import 'package:flutter/material.dart';
import '../list_camera_page_model.dart';
import 'toolbar.dart';
import 'table_cells.dart';
import 'pagination.dart';

/// Card หลักที่รวม Toolbar + Table + Pagination
class CameraTableCard extends StatelessWidget {
  final ListCameraPageModel model;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onAddCamera;
  final ValueChanged<int> onPageChanged;
  final Widget Function() buildTable;

  const CameraTableCard({
    super.key,
    required this.model,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onAddCamera,
    required this.onPageChanged,
    required this.buildTable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Toolbar ──────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: CameraSearchBar(
                    controller: model.searchBarTextController,
                    focusNode: model.searchBarFocusNode,
                    onChanged: onSearchChanged,
                    onClear: onClearSearch,
                  ),
                ),
                const SizedBox(width: 12),
                AddCameraButton(onPressed: onAddCamera),
              ],
            ),
            const SizedBox(height: 16),

            // ── Table / Loading / Empty ───────────────────────────────────
            if (model.isLoading)
              SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary),
                  ),
                ),
              )
            else if (model.listOFcamera.isEmpty)
              const CameraEmptyState()
            else
              LayoutBuilder(builder: (context, constraints) {
                const double minWidth = 1100;
                final w = constraints.maxWidth;
                if (w >= minWidth) return buildTable();
                if (w >= 800) {
                  return Transform.scale(
                    scale: w / minWidth,
                    alignment: Alignment.topLeft,
                    child: SizedBox(width: minWidth, child: buildTable()),
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: minWidth, child: buildTable()),
                );
              }),

            const SizedBox(height: 20),

            // ── Pagination ────────────────────────────────────────────────
            if (!model.isLoading) ...[
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr(
                      'camera_list.page_summary',
                      params: {
                        'page': '${model.currentPage}',
                        'totalPages': '${model.totalPages}',
                        'totalItems': '${model.totalCameras}',
                      },
                    ),
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: AppTextStyles.labelSmall,
                    ),
                  ),
                  CameraPagination(
                    currentPage: model.currentPage,
                    totalPages: model.totalPages,
                    onPageChanged: onPageChanged,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}